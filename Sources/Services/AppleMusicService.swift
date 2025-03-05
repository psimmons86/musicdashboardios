import Foundation
import MusicKit
import CloudKit

enum ServiceError: Error {
    case unauthorized
    case rateLimited
    case networkError
    case invalidResponse
    case notFound
}

private func processInBatches<T>(_ items: [T], batchSize: Int, _ process: ([T]) async throws -> Void) async throws {
    var index = 0
    while index < items.count {
        let end = min(index + batchSize, items.count)
        let batch = Array(items[index..<end])
        try await process(batch)
        index += batchSize
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        Array(Set(self))
    }
}

extension MusicDataRequest.Error {
    var isRateLimit: Bool {
        status == 429
    }
}

// MARK: - CloudKit Service

private class CloudKitManager {
    static let shared = CloudKitManager()
    private let container = CKContainer(identifier: "iCloud.com.musicdashboard.stats")
    private let database: CKDatabase
    
    private init() {
        self.database = container.privateCloudDatabase
        print("[CloudKit] Service initialized")
    }
    
    func incrementPlayCount(for track: Track) async throws {
        let recordID = CKRecord.ID(recordName: "track-\(track.id)")
        
        do {
            print("[CloudKit] Incrementing play count for track: \(track.title)")
            
            // Try to fetch existing record
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
                let currentCount = record["playCount"] as? Int ?? 0
                record["playCount"] = currentCount + 1
                record["lastPlayed"] = Date()
                
                print("[CloudKit] Updating play count to \(currentCount + 1)")
            } catch {
                // Create new record if it doesn't exist
                record = CKRecord(recordType: "Track", recordID: recordID)
                record["id"] = track.id
                record["title"] = track.title
                record["artist"] = track.artist
                record["albumTitle"] = track.albumTitle
                record["artworkURL"] = track.artworkURL
                record["playCount"] = 1
                record["lastPlayed"] = Date()
                
                print("[CloudKit] Creating new track record with play count 1")
            }
            
            try await database.save(record)
            print("[CloudKit] Successfully saved record")
        } catch {
            print("[CloudKit] Error tracking play count: \(error)")
            throw error
        }
    }
    
    func getPlayCount(for track: Track) async throws -> Int {
        let recordID = CKRecord.ID(recordName: "track-\(track.id)")
        
        do {
            print("[CloudKit] Fetching play count for track: \(track.title)")
            let record = try await database.record(for: recordID)
            let playCount = record["playCount"] as? Int ?? 0
            print("[CloudKit] Found play count: \(playCount)")
            return playCount
        } catch {
            print("[CloudKit] No existing record found, returning 0")
            return 0
        }
    }
    
    func getAllPlayCounts() async throws -> [String: Int] {
        print("[CloudKit] Fetching all play counts")
        
        let query = CKQuery(recordType: "Track", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        
        var playCounts: [String: Int] = [:]
        for record in result.matchResults {
            do {
                let record = try record.1.get()
                if let id = record["id"] as? String,
                   let count = record["playCount"] as? Int {
                    playCounts[id] = count
                }
            } catch {
                print("[CloudKit] Error processing record: \(error)")
                continue
            }
        }
        
        print("[CloudKit] Found \(playCounts.count) play count records")
        return playCounts
    }
    
    func saveListeningSession(_ session: ListeningSession) async throws {
        let recordID = CKRecord.ID(recordName: session.id)
        let record = CKRecord(recordType: "ListeningSession", recordID: recordID)
        
        print("[CloudKit] Saving listening session: \(session.id)")
        
        record["startTime"] = session.startTime
        record["duration"] = session.duration
        record["trackIds"] = session.tracks.map { $0.id }
        
        try await database.save(record)
        print("[CloudKit] Successfully saved listening session")
    }
    
    func getListeningSessions(since date: Date) async throws -> [ListeningSession] {
        print("[CloudKit] Fetching listening sessions since: \(date)")
        
        let predicate = NSPredicate(format: "startTime >= %@", date as NSDate)
        let query = CKQuery(recordType: "ListeningSession", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        let result = try await database.records(matching: query)
        var sessions: [ListeningSession] = []
        
        for record in result.matchResults {
            do {
                let record = try record.1.get()
                if let startTime = record["startTime"] as? Date,
                   let duration = record["duration"] as? Int,
                   let trackIds = record["trackIds"] as? [String] {
                    // Fetch tracks for each session
                    let tracks = try await fetchTracks(ids: trackIds)
                    let session = ListeningSession(
                        id: record.recordID.recordName,
                        startTime: startTime,
                        duration: duration,
                        tracks: tracks
                    )
                    sessions.append(session)
                }
            } catch {
                print("[CloudKit] Error processing record: \(error)")
                continue
            }
        }
        
        print("[CloudKit] Found \(sessions.count) listening sessions")
        return sessions
    }
    
    private func fetchTracks(ids: [String]) async throws -> [Track] {
        let recordIDs = ids.map { CKRecord.ID(recordName: "track-\($0)") }
        let result = try await database.records(for: recordIDs)
        
        return result.compactMap { recordID, recordResult in
            do {
                let record = try recordResult.get()
                return Track(
                    id: record["id"] as? String ?? "",
                    title: record["title"] as? String ?? "",
                    artist: record["artist"] as? String ?? "",
                    albumTitle: record["albumTitle"] as? String ?? "",
                    artworkURL: record["artworkURL"] as? String ?? ""
                )
            } catch {
                print("[CloudKit] Error processing track record: \(error)")
                return nil
            }
        }
    }
}

// MARK: - Apple Music Service

public class AppleMusicService {
    public static let shared = AppleMusicService()
    private let defaults = UserDefaults.standard
    private let cloudKit = CloudKitManager.shared
    
    private init() {
        // Request music authorization on init
        Task {
            await requestMusicAuthorization()
        }
    }
    
    private func requestMusicAuthorization() async {
        // Request authorization
        let status = await MusicAuthorization.request()
        switch status {
        case MusicAuthorization.Status.authorized:
            print("Music access authorized")
        default:
            print("Music access not authorized: \(status)")
        }
    }
    
    public var isAuthorized: Bool {
        MusicAuthorization.currentStatus == MusicAuthorization.Status.authorized
    }
    
    private func convertToTrack(_ song: Song) -> Track {
        Track(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            albumTitle: song.albumTitle ?? "",
            artworkURL: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
        )
    }
    
    public func getRecentlyPlayed() async throws -> [Track] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = 20
        
        let response = try await request.response()
        return response.items.map(convertToTrack)
    }
    
    public func getTopTracks() async throws -> [Track] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        var request = MusicPersonalRecommendationsRequest()
        request.limit = 20
        
        let response = try await request.response()
        let recommendations = response.recommendations
            .flatMap { recommendation -> [Song] in
                if let songs = recommendation.items as? MusicItemCollection<Song> {
                    return Array(songs)
                }
                return []
            }
            .prefix(20)
        
        return recommendations.map(convertToTrack)
    }
    
    public func searchTracks(query: String) async throws -> [Track] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 20
        
        let response = try await request.response()
        return response.songs.map(convertToTrack)
    }
    
    public func getWeeklyPlaylist() async throws -> Playlist {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        var request = MusicPersonalRecommendationsRequest()
        request.limit = 10
        let response = try await request.response()
        
        let tracks = response.recommendations
            .flatMap { recommendation -> [Song] in
                if let songs = recommendation.items as? MusicItemCollection<Song> {
                    return Array(songs)
                }
                return []
            }
            .prefix(10)
            .map(convertToTrack)
        
        return Playlist(
            id: UUID().uuidString,
            name: "Your Weekly Mix",
            description: "Personalized playlist based on your Apple Music listening history",
            createdAt: Date(),
            tracks: Array(tracks),
            type: .weekly,
            mood: .energetic,
            genre: "Mixed",
            tempo: nil,
            isCollaborative: false,
            schedule: PlaylistSchedule(
                frequency: .weekly,
                dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                time: Date(),
                lastUpdated: Date(),
                nextUpdate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            )
        )
    }
    
    public func getStreamingStats() async throws -> StreamingStats {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        print("[Stats] Starting to load streaming stats: \(Date())")
        
        // Get recently played tracks
        print("[Stats] Fetching recently played tracks...")
        var recentRequest = MusicRecentlyPlayedRequest<Song>()
        recentRequest.limit = 25
        let recentResponse = try await recentRequest.response()
        
        print("[Stats] Fetching recommendations...")
        var recommendRequest = MusicPersonalRecommendationsRequest()
        recommendRequest.limit = 30
        let recommendResponse = try await recommendRequest.response()
        
        print("[Stats] Processing tracks in batches...")
        var allTracks: [Track] = []
        var offset = 0
        let pageSize = 25
        let totalNeeded = 100
        
        while allTracks.count < totalNeeded {
            var request = MusicRecentlyPlayedRequest<Song>()
            request.limit = pageSize
            request.offset = offset
            
            let response = try await request.response()
            let tracks = response.items.map(convertToTrack)
            allTracks.append(contentsOf: tracks)
            
            if tracks.count < pageSize { break } // No more tracks available
            offset += pageSize
        }
        
        print("[Stats] Adding recommended tracks...")
        let recommendedTracks = recommendResponse.recommendations
            .flatMap { recommendation -> [Song] in
                if let songs = recommendation.items as? MusicItemCollection<Song> {
                    return Array(songs)
                }
                return []
            }
            .map(convertToTrack)
        
        allTracks.append(contentsOf: recommendedTracks)
        
        print("[Stats] Calculating play counts...")
        let trackSet = NSCountedSet(array: allTracks)
        let artistSet = NSCountedSet(array: allTracks.map { $0.artist })
        
        // Build artist stats with accurate play counts
        var artistStats: [String: Set<Track>] = [:]
        for track in allTracks {
            var tracks = artistStats[track.artist] ?? []
            tracks.insert(track)
            artistStats[track.artist] = tracks
        }
        
        let topArtists = artistStats.map { name, tracks in
            ArtistStats(
                id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
                name: name,
                playCount: artistSet.count(for: name),
                totalListeningTime: artistSet.count(for: name) * 3, // Estimate 3 minutes per track
                topTracks: Array(tracks).prefix(5).map { $0 }
            )
        }.sorted { $0.playCount > $1.playCount }
        
        // Create weekly stats
        let weeklyStats = WeeklyStats(
            weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            totalTracks: allTracks.count,
            totalArtists: artistStats.count,
            totalListeningTime: allTracks.count * 3,
            topGenres: try await getTopGenresFromTracks(allTracks),
            mostActiveDay: Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1],
            averageTracksPerDay: allTracks.count / 7
        )
        
        // Get accurate play counts from CloudKit
        print("[Stats] Fetching play counts from CloudKit...")
        let playCounts = try await cloudKit.getAllPlayCounts()
        
        // Create track stats with accurate play counts
        let uniqueTracks = Array(Set(allTracks))
        let topTracks = uniqueTracks.map { track in
            let playCount = playCounts[track.id] ?? trackSet.count(for: track)
            return TrackStats(
                id: track.id,
                track: track,
                playCount: playCount,
                totalListeningTime: playCount * 3,
                lastPlayed: Date()
            )
        }.sorted { $0.playCount > $1.playCount }
        
        // Get listening history from CloudKit
        print("[Stats] Fetching listening history...")
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let listeningHistory = try await cloudKit.getListeningSessions(since: weekAgo)

        print("[Stats] Finished loading stats: \(Date())")
        return StreamingStats(
            totalListeningTime: allTracks.count * 3,
            topArtists: Array(topArtists.prefix(10)),
            topTracks: Array(topTracks.prefix(10)),
            weeklyStats: weeklyStats,
            listeningHistory: listeningHistory
        )
    }
    
    private func retryWithBackoff<T>(_ operation: () async throws -> T, maxRetries: Int = 3) async throws -> T {
        var retryCount = 0
        var delay: UInt64 = 1_000_000_000 // 1 second
        
        while true {
            do {
                return try await operation()
            } catch let error as MusicDataRequest.Error where error.isRateLimit {
                retryCount += 1
                if retryCount >= maxRetries { throw error }
                
                try await Task.sleep(nanoseconds: delay)
                delay *= 2 // Exponential backoff
            } catch {
                throw error // Re-throw non-rate-limit errors
            }
        }
    }
    
    private func getTopGenresFromTracks(_ tracks: [Track]) async throws -> [String] {
        var genres: [String] = []
        let batchSize = 5 // Process in smaller batches
        
        try await processInBatches(Array(tracks.prefix(20)), batchSize: batchSize) { batch in
            try await withThrowingTaskGroup(of: String?.self) { group in
                for track in batch {
                    group.addTask {
                        try await self.retryWithBackoff {
                            let request = MusicCatalogSearchRequest(term: "\(track.artist) \(track.title)", types: [Song.self])
                            let response = try await request.response()
                            return response.songs.first?.genreNames.first
                        }
                    }
                }
                
                for try await genre in group {
                    if let genre = genre {
                        genres.append(genre)
                    }
                }
            }
            
            // Add delay between batches
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        }
        
        return Array(Set(genres)).prefix(5).sorted()
    }
    
    public func getAvailableGenres() async throws -> [String] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        // Return curated list of valid Apple Music genres
        return [
            "Alternative",
            "Electronic",
            "Hip-Hop/Rap",
            "Indie Rock",
            "Indie Electronic",
            "Pop",
            "R&B/Soul",
            "Rock"
        ]
    }
    
    public func generatePlaylist(from tracks: [Track], genre: String? = nil) async throws -> [Track] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        var allRecommendations: [Track] = []
        
        // Get recommendations based on each seed track
        for track in tracks where !track.id.isEmpty {
            var request = MusicCatalogSearchRequest(
                term: "\(track.artist) \(track.title) \(genre ?? "")",
                types: [Song.self]
            )
            request.limit = 10
            
            let response = try await request.response()
            let recommendations = response.songs
                .map(convertToTrack)
                .filter { (rec: Track) in
                    // Filter out seed tracks and duplicates
                    !tracks.contains(rec) && 
                    !allRecommendations.contains(rec)
                }
            allRecommendations.append(contentsOf: recommendations)
            
            // Add delay between requests to avoid rate limiting
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        }
        
        // If we don't have enough tracks, get more based on genre
        if allRecommendations.count < 20, let genre = genre {
            var request = MusicCatalogSearchRequest(term: genre, types: [Song.self])
            request.limit = 20 - allRecommendations.count
            
            let response = try await request.response()
            let genreRecommendations = response.songs
                .map(convertToTrack)
                .filter { rec in
                    !tracks.contains(rec) && 
                    !allRecommendations.contains(rec)
                }
            allRecommendations.append(contentsOf: genreRecommendations)
        }
        
        // Shuffle and return exactly 20 tracks
        return Array(allRecommendations.shuffled().prefix(20))
    }
}
