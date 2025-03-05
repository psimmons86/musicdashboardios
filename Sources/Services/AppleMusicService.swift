import Foundation
import MusicKit

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

public class AppleMusicService {
    public static let shared = AppleMusicService()
    private let defaults = UserDefaults.standard
    
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
        
        // Get recently played tracks
        var recentRequest = MusicRecentlyPlayedRequest<Song>()
        recentRequest.limit = 25
        let recentResponse = try await recentRequest.response()
        
        // Get recommendations for variety
        var recommendRequest = MusicPersonalRecommendationsRequest()
        recommendRequest.limit = 30
        let recommendResponse = try await recommendRequest.response()
        
        // Process tracks
        // Get multiple pages of recent tracks
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
        
        // Add recommended tracks
        let recommendedTracks = recommendResponse.recommendations
            .flatMap { recommendation -> [Song] in
                if let songs = recommendation.items as? MusicItemCollection<Song> {
                    return Array(songs)
                }
                return []
            }
            .map(convertToTrack)
        
        allTracks.append(contentsOf: recommendedTracks)
        
        // Calculate artist stats
        var artistStats: [String: (playCount: Int, tracks: Set<Track>)] = [:]
        for track in allTracks {
            let stats = artistStats[track.artist] ?? (0, [])
            artistStats[track.artist] = (stats.0 + 1, stats.1.union([track]))
        }
        
        let topArtists = artistStats.map { name, stats in
            ArtistStats(
                id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
                name: name,
                playCount: stats.playCount,
                totalListeningTime: stats.playCount * 3, // Estimate 3 minutes per track
                topTracks: Array(stats.tracks).prefix(5).map { $0 }
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
        
        // Create track stats
        let trackCounts = NSCountedSet(array: allTracks.map { $0.id })
        let topTracks = allTracks
            .reduce(into: [String: Track]()) { dict, track in
                dict[track.id] = track
            }
            .map { id, track in
                TrackStats(
                    id: id,
                    track: track,
                    playCount: trackCounts.count(for: id),
                    totalListeningTime: trackCounts.count(for: id) * 3,
                    lastPlayed: Date()
                )
            }
            .sorted { $0.playCount > $1.playCount }
        
        // Create listening history
        let listeningHistory = allTracks
            .prefix(50)
            .enumerated()
            .map { index, track in
                let startTime = Calendar.current.date(byAdding: .hour, value: -index, to: Date()) ?? Date()
                return ListeningSession(
                    id: UUID().uuidString,
                    startTime: startTime,
                    duration: 3, // Estimate 3 minutes per track
                    tracks: [track]
                )
            }
            .sorted { $0.startTime > $1.startTime }

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
        
        var request = MusicCatalogSearchRequest(term: "genre:", types: [Song.self])
        request.limit = 25
        let response = try await request.response()
        return response.songs
            .compactMap { $0.genreNames.first }
            .removingDuplicates()
            .sorted()
    }
    
    public func generatePlaylist(from tracks: [Track], genre: String? = nil) async throws -> [Track] {
        guard isAuthorized else { throw ServiceError.unauthorized }
        
        // Create a search request for similar songs
        var searchTerms = tracks.prefix(3).map { "\($0.artist) \($0.title)" }.joined(separator: " ")
        if let genre = genre {
            searchTerms += " \(genre)"
        }
        
        var request = MusicCatalogSearchRequest(term: searchTerms, types: [Song.self])
        request.limit = 20
        
        let response = try await request.response()
        return response.songs.map(convertToTrack)
    }
}
