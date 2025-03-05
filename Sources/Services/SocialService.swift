import Foundation

public class SocialService {
    public static let shared = SocialService()
    
    private init() {}
    
    // Mock data
    private static let mockTracks = [
        Track(id: "1", title: "Bohemian Rhapsody", artist: "Queen", albumTitle: "A Night at the Opera", artworkURL: "https://example.com/artwork/{w}x{h}.jpg"),
        Track(id: "2", title: "Stairway to Heaven", artist: "Led Zeppelin", albumTitle: "Led Zeppelin IV", artworkURL: "https://example.com/artwork/{w}x{h}.jpg"),
        Track(id: "3", title: "Hotel California", artist: "Eagles", albumTitle: "Hotel California", artworkURL: "https://example.com/artwork/{w}x{h}.jpg")
    ]
    
    private let mockPosts = [
        Post(
            id: "1",
            userId: "user1",
            content: "Just discovered this amazing playlist!",
            track: nil,
            playlist: nil,
            createdAt: Date(),
            likes: 42,
            comments: 5,
            isLiked: false
        ),
        Post(
            id: "2",
            userId: "user2",
            content: "Can't stop listening to this track",
            track: SocialService.mockTracks[0],
            playlist: nil,
            createdAt: Date().addingTimeInterval(-3600),
            likes: 24,
            comments: 3,
            isLiked: true
        )
    ]
    
    private let mockProfile = UserProfile(
        id: "user1",
        username: "musiclover",
        bio: "Music is life 🎵",
        avatarURL: "https://example.com/avatar.jpg",
        favoriteGenres: ["Rock", "Jazz", "Classical"],
        topArtists: ["Queen", "Led Zeppelin", "Mozart"],
        followers: 120,
        following: 85,
        isFollowing: false,
        posts: [],
        likedPosts: [],
        playlists: []
    )
    
    public func getFeed() async throws -> [Post] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockPosts
    }
    
    public func getProfile(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 500_000_000)
        var profile = mockProfile
        profile.posts = mockPosts
        return profile
    }
    
    public func likePost(postId: String) async throws -> Post {
        try await Task.sleep(nanoseconds: 500_000_000)
        var post = mockPosts.first { $0.id == postId } ?? mockPosts[0]
        post.isLiked = true
        post.likes += 1
        return post
    }
    
    public func unlikePost(postId: String) async throws -> Post {
        try await Task.sleep(nanoseconds: 500_000_000)
        var post = mockPosts.first { $0.id == postId } ?? mockPosts[0]
        post.isLiked = false
        post.likes -= 1
        return post
    }
    
    public func followUser(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 500_000_000)
        var profile = mockProfile
        profile.isFollowing = true
        profile.followers += 1
        return profile
    }
    
    public func unfollowUser(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 500_000_000)
        var profile = mockProfile
        profile.isFollowing = false
        profile.followers -= 1
        return profile
    }
    
    public func getArticles() async throws -> [Article] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Article(
                id: "1",
                title: "The Evolution of Electronic Music",
                subtitle: "From synthesizers to digital audio workstations",
                content: "A deep dive into the history of electronic music...",
                author: "John Smith",
                category: .genreDeep,
                coverImageURL: "https://example.com/electronic-music.jpg",
                createdAt: Date(),
                readTime: 5,
                likes: 42,
                comments: 7,
                isLiked: false,
                relatedTracks: Array(SocialService.mockTracks.prefix(3))
            ),
            Article(
                id: "2",
                title: "Artist Spotlight: Queen",
                subtitle: "The legends of rock music",
                content: "Exploring the legacy of Queen...",
                author: "Jane Doe",
                category: .artistSpotlight,
                coverImageURL: "https://example.com/queen.jpg",
                createdAt: Date().addingTimeInterval(-86400),
                readTime: 8,
                likes: 128,
                comments: 15,
                isLiked: true,
                relatedTracks: Array(SocialService.mockTracks.prefix(3))
            ),
            Article(
                id: "3",
                title: "Top Summer Playlists",
                subtitle: "Get ready for the sunny season",
                content: "Our curated selection of summer hits...",
                author: "Mike Wilson",
                category: .playlists,
                coverImageURL: "https://example.com/summer.jpg",
                createdAt: Date().addingTimeInterval(-172800),
                readTime: 4,
                likes: 85,
                comments: 12,
                isLiked: false,
                relatedPlaylists: [
                    Playlist(
                        id: UUID().uuidString,
                        name: "Summer Vibes",
                        description: "Perfect for beach days",
                        createdAt: Date(),
                        tracks: Array(SocialService.mockTracks.shuffled().prefix(10)),
                        type: .custom,
                        mood: .happy,
                        genre: "Pop"
                    )
                ]
            )
        ]
    }
    
    public func getFeedPosts() async throws -> [Post] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockPosts
    }
    
    public func getComments(postId: String) async throws -> [Comment] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Comment(
                id: UUID().uuidString,
                postId: postId,
                userId: "user3",
                content: "Great song! 🎵",
                createdAt: Date(),
                likes: 5,
                isLiked: false
            ),
            Comment(
                id: UUID().uuidString,
                postId: postId,
                userId: "user4",
                content: "One of my favorites!",
                createdAt: Date().addingTimeInterval(-1800),
                likes: 3,
                isLiked: true
            )
        ]
    }
    
    public func addComment(postId: String, content: String) async throws -> Comment {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Comment(
            id: UUID().uuidString,
            postId: postId,
            userId: "user1",
            content: content,
            createdAt: Date(),
            likes: 0,
            isLiked: false
        )
    }
}
