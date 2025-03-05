import Foundation

// MARK: - Track
public struct Track: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let artist: String
    public let albumTitle: String
    public let artworkURL: String
    
    public init(id: String, title: String, artist: String, albumTitle: String, artworkURL: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.artworkURL = artworkURL
    }
    
    public func artworkURLForSize(width: Int, height: Int) -> URL? {
        return URL(string: artworkURL.replacingOccurrences(of: "{w}", with: "\(width)")
            .replacingOccurrences(of: "{h}", with: "\(height)"))
    }
}

// MARK: - Playlist
public struct Playlist: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let createdAt: Date
    public var tracks: [Track]
    public let type: PlaylistType
    public let mood: PlaylistMood?
    public let genre: String?
    public let tempo: Int? // BPM
    public let isCollaborative: Bool
    public let schedule: PlaylistSchedule?
    
    public init(id: String, name: String, description: String? = nil, createdAt: Date, tracks: [Track], type: PlaylistType, mood: PlaylistMood? = nil, genre: String? = nil, tempo: Int? = nil, isCollaborative: Bool = false, schedule: PlaylistSchedule? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.tracks = tracks
        self.type = type
        self.mood = mood
        self.genre = genre
        self.tempo = tempo
        self.isCollaborative = isCollaborative
        self.schedule = schedule
    }
}

public enum PlaylistType: String, Codable {
    case weekly = "weekly"
    case generated = "generated"
    case custom = "custom"
    case collaborative = "collaborative"
}

public enum PlaylistMood: String, Codable {
    case energetic = "energetic"
    case relaxed = "relaxed"
    case happy = "happy"
    case melancholic = "melancholic"
    case focused = "focused"
    case party = "party"
}

public struct PlaylistSchedule: Codable {
    public let frequency: ScheduleFrequency
    public let dayOfWeek: Int? // 1 = Sunday, 7 = Saturday
    public let time: Date // Time of day for notification
    public let lastUpdated: Date
    public let nextUpdate: Date
    
    public init(frequency: ScheduleFrequency, dayOfWeek: Int? = nil, time: Date, lastUpdated: Date, nextUpdate: Date) {
        self.frequency = frequency
        self.dayOfWeek = dayOfWeek
        self.time = time
        self.lastUpdated = lastUpdated
        self.nextUpdate = nextUpdate
    }
}

public enum ScheduleFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

public struct PlaylistPreferences: Codable {
    public var preferredGenres: [String]
    public var preferredMoods: [PlaylistMood]
    public var tempoRange: ClosedRange<Int>
    public var excludedArtists: [String]
    public var minimumEnergySongs: Bool
    public var maximumPlaylistLength: Int
    
    public init(preferredGenres: [String], preferredMoods: [PlaylistMood], tempoRange: ClosedRange<Int>, excludedArtists: [String], minimumEnergySongs: Bool, maximumPlaylistLength: Int) {
        self.preferredGenres = preferredGenres
        self.preferredMoods = preferredMoods
        self.tempoRange = tempoRange
        self.excludedArtists = excludedArtists
        self.minimumEnergySongs = minimumEnergySongs
        self.maximumPlaylistLength = maximumPlaylistLength
    }
}

// MARK: - Streaming Stats
public struct StreamingStats: Codable {
    public let totalListeningTime: Int // in minutes
    public let topArtists: [ArtistStats]
    public let topTracks: [TrackStats]
    public let weeklyStats: WeeklyStats
    public let listeningHistory: [ListeningSession]
    
    public init(totalListeningTime: Int, topArtists: [ArtistStats], topTracks: [TrackStats], weeklyStats: WeeklyStats, listeningHistory: [ListeningSession]) {
        self.totalListeningTime = totalListeningTime
        self.topArtists = topArtists
        self.topTracks = topTracks
        self.weeklyStats = weeklyStats
        self.listeningHistory = listeningHistory
    }
}

public struct ArtistStats: Codable, Identifiable {
    public let id: String
    public let name: String
    public let playCount: Int
    public let totalListeningTime: Int // in minutes
    public let topTracks: [Track]
    
    public init(id: String, name: String, playCount: Int, totalListeningTime: Int, topTracks: [Track]) {
        self.id = id
        self.name = name
        self.playCount = playCount
        self.totalListeningTime = totalListeningTime
        self.topTracks = topTracks
    }
}

public struct TrackStats: Codable, Identifiable {
    public let id: String
    public let track: Track
    public let playCount: Int
    public let totalListeningTime: Int // in minutes
    public let lastPlayed: Date
    
    public init(id: String, track: Track, playCount: Int, totalListeningTime: Int, lastPlayed: Date) {
        self.id = id
        self.track = track
        self.playCount = playCount
        self.totalListeningTime = totalListeningTime
        self.lastPlayed = lastPlayed
    }
}

public struct WeeklyStats: Codable {
    public let weekStartDate: Date
    public let totalTracks: Int
    public let totalArtists: Int
    public let totalListeningTime: Int // in minutes
    public let topGenres: [String]
    public let mostActiveDay: String
    public let averageTracksPerDay: Int
    
    public init(weekStartDate: Date, totalTracks: Int, totalArtists: Int, totalListeningTime: Int, topGenres: [String], mostActiveDay: String, averageTracksPerDay: Int) {
        self.weekStartDate = weekStartDate
        self.totalTracks = totalTracks
        self.totalArtists = totalArtists
        self.totalListeningTime = totalListeningTime
        self.topGenres = topGenres
        self.mostActiveDay = mostActiveDay
        self.averageTracksPerDay = averageTracksPerDay
    }
}

public struct ListeningSession: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let duration: Int // in minutes
    public let tracks: [Track]
    
    public init(id: String, startTime: Date, duration: Int, tracks: [Track]) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.tracks = tracks
    }
}

// MARK: - Social
public struct Post: Identifiable, Codable {
    public let id: String
    public let userId: String
    public let content: String
    public let track: Track?
    public let playlist: Playlist?
    public let createdAt: Date
    public var likes: Int
    public var comments: Int
    public var isLiked: Bool
    
    public init(id: String, userId: String, content: String, track: Track?, playlist: Playlist?, createdAt: Date, likes: Int, comments: Int, isLiked: Bool) {
        self.id = id
        self.userId = userId
        self.content = content
        self.track = track
        self.playlist = playlist
        self.createdAt = createdAt
        self.likes = likes
        self.comments = comments
        self.isLiked = isLiked
    }
}

public struct Comment: Identifiable, Codable {
    public let id: String
    public let postId: String
    public let userId: String
    public let content: String
    public let createdAt: Date
    public var likes: Int
    public var isLiked: Bool
    
    public init(id: String, postId: String, userId: String, content: String, createdAt: Date, likes: Int, isLiked: Bool) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.likes = likes
        self.isLiked = isLiked
    }
}

public struct UserProfile: Identifiable, Codable {
    public let id: String
    public let username: String
    public let bio: String?
    public let avatarURL: String?
    public let favoriteGenres: [String]
    public let topArtists: [String]
    public var followers: Int
    public var following: Int
    public var isFollowing: Bool
    
    public var posts: [Post]
    public var likedPosts: [Post]
    public var playlists: [Playlist]
    
    public init(id: String, username: String, bio: String?, avatarURL: String?, favoriteGenres: [String], topArtists: [String], followers: Int, following: Int, isFollowing: Bool, posts: [Post], likedPosts: [Post], playlists: [Playlist]) {
        self.id = id
        self.username = username
        self.bio = bio
        self.avatarURL = avatarURL
        self.favoriteGenres = favoriteGenres
        self.topArtists = topArtists
        self.followers = followers
        self.following = following
        self.isFollowing = isFollowing
        self.posts = posts
        self.likedPosts = likedPosts
        self.playlists = playlists
    }
}

// MARK: - Blog
public struct Article: Identifiable, Codable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let content: String
    public let author: String
    public let category: ArticleCategory
    public let coverImageURL: String?
    public let createdAt: Date
    public let readTime: Int // in minutes
    public var likes: Int
    public var comments: Int
    public var isLiked: Bool
    
    public var relatedTracks: [Track]?
    public var relatedPlaylists: [Playlist]?
    
    public init(id: String, title: String, subtitle: String?, content: String, author: String, category: ArticleCategory, coverImageURL: String?, createdAt: Date, readTime: Int, likes: Int, comments: Int, isLiked: Bool, relatedTracks: [Track]? = nil, relatedPlaylists: [Playlist]? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.author = author
        self.category = category
        self.coverImageURL = coverImageURL
        self.createdAt = createdAt
        self.readTime = readTime
        self.likes = likes
        self.comments = comments
        self.isLiked = isLiked
        self.relatedTracks = relatedTracks
        self.relatedPlaylists = relatedPlaylists
    }
}

public enum ArticleCategory: String, Codable, CaseIterable {
    case newReleases = "New Releases"
    case artistSpotlight = "Artist Spotlight"
    case genreDeep = "Genre Deep Dive"
    case industryNews = "Industry News"
    case reviews = "Reviews"
    case playlists = "Playlists"
}

struct DailyDispatch: Codable {
    let date: Date
    let recommendations: [Track]
    let newReleases: [Track]
    let articles: [Article]
    let trendingPlaylists: [Playlist]
}

// MARK: - News
public struct NewsArticle: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let url: String
    public let urlToImage: String?
    public let publishedAt: String
    public let source: NewsSource
    
    public init(id: String, title: String, description: String?, url: String, urlToImage: String?, publishedAt: String, source: NewsSource) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.source = source
    }
    
    public enum CodingKeys: String, CodingKey {
        case title, description, url, urlToImage, publishedAt, source
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        url = try container.decode(String.self, forKey: .url)
        urlToImage = try container.decodeIfPresent(String.self, forKey: .urlToImage)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        source = try container.decode(NewsSource.self, forKey: .source)
        
        // Generate a unique ID from the URL since News API doesn't provide one
        id = url.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_")
    }
}

public struct NewsSource: Codable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
