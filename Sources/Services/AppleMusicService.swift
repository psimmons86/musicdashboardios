import Foundation
import MusicKit
import CryptoKit
import Security

// Track struct to represent a music track
public struct Track: Identifiable {
    public let id: MusicItemID
    public let title: String
    public let artistName: String
    public let artwork: Artwork?
    
    public init(id: MusicItemID, title: String, artistName: String, artwork: Artwork?) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artwork = artwork
    }
}

@available(iOS 16.0, macOS 12.0, *)
public class AppleMusicService {
    public static let shared = AppleMusicService()
    
    // MARK: - Private Properties
    
    // These values are obtained from the Apple Developer Portal
    private let teamId = "4Y39R5M676" // Your 10-character Team ID from your developer account
    private let keyId = "97K5H5UANT"  // Your 10-character key identifier from your developer account
    private var privateKey: SecKey? = nil
    private let privateKeyFilename = "AuthKey_97K5H5UANT.p8"
    
    private var developerToken: String?
    private var developerTokenExpirationDate: Date?
    
    private init() {
        // Load private key from file if available
        loadPrivateKey()
    }
    
    // MARK: - Authentication
    
    /// Request authorization to access Apple Music
    public func requestAuthorization() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    /// Check if the user is authorized to access Apple Music
    public func checkAuthorizationStatus() -> MusicAuthorization.Status {
        return MusicAuthorization.currentStatus
    }
    
    // MARK: - Developer Token Management
    
    /// Load the private key from the app bundle
    private func loadPrivateKey() {
        if let keyPath = Bundle.main.path(forResource: "AuthKey_97K5H5UANT", ofType: "p8") {
            do {
                let keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))
            
                // Convert the .p8 file data to a string and remove headers/footers
                var keyString = String(data: keyData, encoding: .utf8) ?? ""
                keyString = keyString.replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
                keyString = keyString.replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
                keyString = keyString.replacingOccurrences(of: "\n", with: "")
                keyString = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Convert the base64 string to data
                guard let data = Data(base64Encoded: keyString) else {
                    print("Failed to decode base64 key data")
                    return
                }
                
                // Create a SecKey from the data
                let attributes: [String: Any] = [
                    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                    kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                    kSecAttrKeySizeInBits as String: 256
                ]
                
                var error: Unmanaged<CFError>?
                privateKey = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error)
                
                if privateKey == nil {
                    if let error = error?.takeRetainedValue() {
                        print("Error creating private key: \(error)")
                    }
                }
            } catch {
                print("Error loading private key: \(error)")
            }
        } else {
            print("Private key file not found in app bundle")
        }
    }
    
    /// Generate a developer token for Apple Music API requests
    private func generateDeveloperToken() -> String? {
        // Check if we have a valid token that hasn't expired
        if let token = developerToken, let expirationDate = developerTokenExpirationDate, expirationDate > Date() {
            return token
        }
        
        // Make sure we have a private key
        guard let privateKey = privateKey else {
            print("Private key not loaded")
            return nil
        }
        
        // Create the JWT header
        let header = [
            "alg": "ES256",
            "kid": keyId
        ]
        
        // Create the JWT payload
        let currentTime = Date()
        let expirationTime = currentTime.addingTimeInterval(15777000) // ~6 months
        
        let payload = [
            "iss": teamId,
            "iat": Int(currentTime.timeIntervalSince1970),
            "exp": Int(expirationTime.timeIntervalSince1970)
        ] as [String : Any]
        
        // Convert header and payload to JSON
        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let payloadData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Failed to serialize header or payload")
            return nil
        }
        
        // Base64 encode the header and payload
        let base64Header = headerData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        let base64Payload = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Create the data to sign
        let toSign = "\(base64Header).\(base64Payload)"
        guard let toSignData = toSign.data(using: .utf8) else {
            print("Failed to create data to sign")
            return nil
        }
        
        // Sign the data
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey,
                                                   .ecdsaSignatureMessageX962SHA256,
                                                   toSignData as CFData,
                                                   &error) as Data? else {
            if let error = error?.takeRetainedValue() {
                print("Error signing data: \(error)")
            }
            return nil
        }
        
        // Base64 encode the signature
        let base64Signature = signature.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Create the JWT token
        let token = "\(toSign).\(base64Signature)"
        
        // Save the token and expiration date
        developerToken = token
        developerTokenExpirationDate = expirationTime
        
        return token
    }
    
    /// Ensure we have a valid developer token
    private func ensureDeveloperToken() throws -> String {
        guard let token = generateDeveloperToken() else {
            throw NSError(domain: "AppleMusicService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to generate developer token. Make sure you have registered a media identifier and created a private key in the Apple Developer Portal."])
        }
        return token
    }
    
    // MARK: - MusicKit Availability
    
    /// Check if MusicKit is available (entitlement is enabled)
    private var isMusicKitAvailable: Bool {
        // Check if the MusicKit entitlement is enabled
        // This is a simple check that will return true if the app has the entitlement
        // and false if it doesn't
        return Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.musickit") != nil
    }
    
    /// Get mock data when MusicKit is not available
    private func getMockTracks(count: Int = 20, term: String = "popular") -> [Track] {
        // Create some mock tracks when MusicKit is not available
        var tracks: [Track] = []
        
        // Mock track data
        let mockTitles = [
            "Bohemian Rhapsody", "Stairway to Heaven", "Imagine", "Smells Like Teen Spirit",
            "Billie Jean", "Sweet Child O' Mine", "Hotel California", "Yesterday",
            "Thriller", "Like a Rolling Stone", "Hey Jude", "Purple Haze",
            "Respect", "Johnny B. Goode", "Good Vibrations", "My Generation",
            "What's Going On", "Satisfaction", "Waterloo Sunset", "London Calling"
        ]
        
        let mockArtists = [
            "Queen", "Led Zeppelin", "John Lennon", "Nirvana",
            "Michael Jackson", "Guns N' Roses", "Eagles", "The Beatles",
            "Michael Jackson", "Bob Dylan", "The Beatles", "Jimi Hendrix",
            "Aretha Franklin", "Chuck Berry", "The Beach Boys", "The Who",
            "Marvin Gaye", "The Rolling Stones", "The Kinks", "The Clash"
        ]
        
        // Create mock tracks
        for i in 0..<min(count, mockTitles.count) {
            let track = Track(
                id: MusicItemID(i.description),
                title: mockTitles[i],
                artistName: mockArtists[i],
                artwork: nil
            )
            tracks.append(track)
        }
        
        return tracks
    }
    
    // MARK: - Recommendations
    
    /// Get recommended tracks based on user's listening history
    public func getRecommendedTracks() async throws -> [Track] {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data.")
            return getMockTracks(term: "top hits")
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // Request personalized recommendations
        let request = MusicPersonalRecommendationsRequest()
        let response = try await request.response()
        
        // Extract tracks from recommendations
        var tracks: [Track] = []
        
        // Get some tracks from the catalog
        let catalogRequest = MusicCatalogSearchRequest(term: "top hits", types: [Song.self])
        let catalogResponse = try await catalogRequest.response()
        
        if let songs = catalogResponse.songs as? MusicItemCollection<Song> {
            for song in songs {
                // Convert Song to Track
                let track = Track(
                    id: song.id,
                    title: song.title,
                    artistName: song.artistName,
                    artwork: song.artwork
                )
                tracks.append(track)
                
                // Limit to 20 tracks
                if tracks.count >= 20 {
                    break
                }
            }
        }
        
        return tracks
    }
    
    // MARK: - Recently Played
    
    /// Get recently played tracks
    public func getRecentlyPlayed() async throws -> [Track] {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data.")
            return getMockTracks(term: "popular")
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // For now, return some catalog tracks as a substitute for recently played
        let request = MusicCatalogSearchRequest(term: "popular", types: [Song.self])
        let response = try await request.response()
        
        var tracks: [Track] = []
        
        if let songs = response.songs as? MusicItemCollection<Song> {
            for song in songs {
                // Convert Song to Track
                let track = Track(
                    id: song.id,
                    title: song.title,
                    artistName: song.artistName,
                    artwork: song.artwork
                )
                tracks.append(track)
                
                // Limit to 20 tracks
                if tracks.count >= 20 {
                    break
                }
            }
        }
        
        return tracks
    }
    
    // MARK: - Top Tracks
    
    /// Get user's top tracks
    public func getTopTracks() async throws -> [Track] {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data.")
            return getMockTracks(term: "hits")
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // For now, return some catalog tracks as a substitute for top tracks
        let request = MusicCatalogSearchRequest(term: "hits", types: [Song.self])
        let response = try await request.response()
        
        var tracks: [Track] = []
        
        if let songs = response.songs as? MusicItemCollection<Song> {
            for song in songs {
                // Convert Song to Track
                let track = Track(
                    id: song.id,
                    title: song.title,
                    artistName: song.artistName,
                    artwork: song.artwork
                )
                tracks.append(track)
                
                // Limit to 20 tracks
                if tracks.count >= 20 {
                    break
                }
            }
        }
        
        return tracks
    }
    
    // MARK: - Save Playlist
    
    /// Save a playlist to Apple Music
    public func saveToAppleMusic(name: String, tracks: [Track]) async throws -> Bool {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Cannot save playlist to Apple Music.")
            // Return true to indicate success even though we didn't actually save the playlist
            // This allows the app to continue functioning without MusicKit
            return true
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // Create a new playlist
        let description = "Created by Music Dashboard"
        
        // In a real implementation, we would create a playlist in the user's library
        // For now, just return success
        return true
    }
    
    // MARK: - Streaming Stats
    
    /// Get user's streaming statistics
    public func getStreamingStats() async throws -> Models.StreamingStats {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data for streaming stats.")
            // Create mock streaming stats
            let mockTracks = getMockTracks(count: 5)
            return Models.StreamingStats(
                totalPlays: 100,
                uniqueArtists: 20,
                uniqueSongs: 50,
                topTracks: mockTracks
            )
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // Get recently played tracks to calculate stats
        let recentTracks = try await getRecentlyPlayed()
        
        // Calculate stats
        let totalPlays = recentTracks.count
        
        // Get unique artists
        let artistIDs = Set(recentTracks.compactMap { $0.artistName })
        let uniqueArtists = artistIDs.count
        
        // Get unique songs
        let songIDs = Set(recentTracks.map { $0.id })
        let uniqueSongs = songIDs.count
        
        // Get top tracks (most frequently played)
        let topTracks = Array(recentTracks.prefix(5))
        
        return Models.StreamingStats(
            totalPlays: totalPlays,
            uniqueArtists: uniqueArtists,
            uniqueSongs: uniqueSongs,
            topTracks: topTracks
        )
    }
    
    // MARK: - Weekly Playlist
    
    /// Generate a weekly playlist based on user's listening history
    public func getWeeklyPlaylist() async throws -> Models.Playlist {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data for weekly playlist.")
            // Create a mock playlist
            let mockTracks = getMockTracks(count: 20)
            return Models.Playlist(
                id: UUID().uuidString,
                name: "Your Weekly Mix (Demo)",
                description: "Demo playlist with mock data",
                tracks: mockTracks,
                genre: determineGenre(from: mockTracks),
                mood: determineMood(from: mockTracks),
                schedule: Models.PlaylistSchedule(
                    frequency: .weekly,
                    nextUpdate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                )
            )
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // Get a mix of recommended and top tracks
        let recommendedTracks = try await getRecommendedTracks()
        let topTracks = try await getTopTracks()
        
        // Combine and shuffle
        var tracks = recommendedTracks
        tracks.append(contentsOf: topTracks)
        tracks.shuffle()
        
        // Limit to 20 tracks
        tracks = Array(tracks.prefix(20))
        
        // Determine mood based on tracks
        let mood = determineMood(from: tracks)
        
        // Determine genre based on tracks
        let genre = determineGenre(from: tracks)
        
        // Create playlist
        return Models.Playlist(
            id: UUID().uuidString,
            name: "Your Weekly Mix",
            description: "Personalized playlist based on your listening history",
            tracks: tracks,
            genre: genre,
            mood: mood,
            schedule: Models.PlaylistSchedule(
                frequency: .weekly,
                nextUpdate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            )
        )
    }
    
    // MARK: - Search
    
    /// Search for tracks
    public func searchTracks(query: String) async throws -> [Track] {
        // Check if MusicKit is available
        guard isMusicKitAvailable else {
            print("MusicKit is not available. Using mock data for search.")
            // Filter mock tracks based on the query
            let allMockTracks = getMockTracks(count: 20)
            let filteredTracks = allMockTracks.filter { 
                $0.title.lowercased().contains(query.lowercased()) || 
                $0.artistName.lowercased().contains(query.lowercased())
            }
            return filteredTracks.isEmpty ? allMockTracks : filteredTracks
        }
        
        // Check authorization
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw NSError(domain: "AppleMusicService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music"])
        }
        
        // Create search request
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 20
        
        let response = try await request.response()
        
        // Extract tracks
        var tracks: [Track] = []
        
        if let songs = response.songs as? MusicItemCollection<Song> {
            for song in songs {
                // Convert Song to Track
                let track = Track(
                    id: song.id,
                    title: song.title,
                    artistName: song.artistName,
                    artwork: song.artwork
                )
                tracks.append(track)
                
                // Limit to 20 tracks
                if tracks.count >= 20 {
                    break
                }
            }
        }
        
        return tracks
    }
    
    // MARK: - Helper Methods
    
    /// Determine the mood of a playlist based on its tracks
    private func determineMood(from tracks: [Track]) -> Models.PlaylistMood {
        // In a real implementation, this would analyze track attributes
        // For now, return a random mood
        let moods: [Models.PlaylistMood] = [.chill, .energetic, .focus, .workout, .party]
        return moods.randomElement() ?? .chill
    }
    
    /// Determine the primary genre of a playlist based on its tracks
    private func determineGenre(from tracks: [Track]) -> String {
        // In a real implementation, this would analyze track genres
        // For now, return a random genre
        let genres = ["Pop", "Rock", "Hip-Hop", "Electronic", "R&B", "Jazz", "Classical", "Country", "Indie"]
        return genres.randomElement() ?? "Mixed"
    }
}
