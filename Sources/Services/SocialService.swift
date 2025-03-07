import Foundation
import MusicKit
import SwiftUI // Required for the Views defined in Models+Social.swift
import CloudKit

// No typealiases needed - we'll use fully qualified names

// Comment type definition
public struct Comment: Identifiable {
    public let id: String
    public let content: String
    public let author: Models.UserProfile
    public let createdAt: Date
    public let likes: Int
    
    public init(id: String, content: String, author: Models.UserProfile, createdAt: Date, likes: Int) {
        self.id = id
        self.content = content
        self.author = author
        self.createdAt = createdAt
        self.likes = likes
    }
}

/// Service for handling social and blog-related functionality
public class SocialService {
    /// Shared instance of the service
    public static let shared = SocialService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Blog Articles
    
    // Blog-related models
    public enum ArticleCategory: String, CaseIterable {
        case news = "News"
        case review = "Review"
        case artists = "Artists"
        case industry = "Industry"
        case features = "Features"
    }
    
    public struct Article: Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let content: String
        public let author: String
        public let authorImageURL: String?
        public let coverImageURL: String?
        public let publishDate: Date
        public let readTime: Int
        public let category: SocialService.ArticleCategory
        public let relatedTracks: [MusicKit.Track]?
        public let relatedPlaylists: [Models.Playlist]?
        
        public init(
            id: String,
            title: String,
            subtitle: String? = nil,
            content: String,
            author: String,
            authorImageURL: String? = nil,
            coverImageURL: String? = nil,
            publishDate: Date,
            readTime: Int,
            category: SocialService.ArticleCategory,
            relatedTracks: [MusicKit.Track]? = nil,
            relatedPlaylists: [Models.Playlist]? = nil
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.content = content
            self.author = author
            self.authorImageURL = authorImageURL
            self.coverImageURL = coverImageURL
            self.publishDate = publishDate
            self.readTime = readTime
            self.category = category
            self.relatedTracks = relatedTracks
            self.relatedPlaylists = relatedPlaylists
        }
    }
    
    /// Fetch all blog articles
    /// - Returns: Array of social posts
    /// - Throws: Error if the operation fails
    public func getArticles() async throws -> [SocialService.Article] {
        // In a real app, this would fetch from a social API
        // For demo purposes, return mock data
        return [
            SocialService.Article(
                id: "1",
                title: "The Evolution of Electronic Music",
                subtitle: "From analog synthesizers to digital production",
                content: "Electronic music has come a long way...",
                author: "Alex Johnson",
                authorImageURL: nil,
                coverImageURL: "https://example.com/images/electronic-music.jpg",
                publishDate: Date().addingTimeInterval(-86400 * 3),
                readTime: 5,
                category: .industry
            ),
            SocialService.Article(
                id: "2",
                title: "Artist Spotlight: The Rise of Indie Pop",
                subtitle: "How independent artists are reshaping the music landscape",
                content: "Independent artists have been making waves...",
                author: "Maya Rodriguez",
                authorImageURL: "https://example.com/images/maya.jpg",
                coverImageURL: "https://example.com/images/indie-pop.jpg",
                publishDate: Date().addingTimeInterval(-86400 * 7),
                readTime: 8,
                category: .artists
            ),
            SocialService.Article(
                id: "3",
                title: "Review: The Latest Album from Sonic Pioneers",
                content: "The new album pushes boundaries and explores new sonic territories...",
                author: "Chris Taylor",
                coverImageURL: "https://example.com/images/album-review.jpg",
                publishDate: Date().addingTimeInterval(-86400 * 1),
                readTime: 4,
                category: .review
            )
        ]
    }
    
    // MARK: - Mock CloudKit Service
    
    // Create a mock CloudKit service to use until the real one is available
    private class MockCloudKitService {
        static let shared = MockCloudKitService()
        
        func getCurrentUserID() async throws -> String {
            return "mock-user-id"
        }
        
        func getUserProfile(userID: String) async throws -> Models.UserProfile {
            return Models.UserProfile(
                id: userID,
                username: "mock_user",
                displayName: "Mock User",
                bio: "This is a mock user profile",
                avatarUrl: nil,
                followers: 100,
                following: 50,
                favoriteTracks: []
            )
        }
        
        func isFollowing(followerID: String, followedID: String) async throws -> Bool {
            return false
        }
        
        func getFollowersCount(userID: String) async throws -> Int {
            return 100
        }
        
        func getFollowingCount(userID: String) async throws -> Int {
            return 50
        }
        
        func getUserPosts(userID: String) async throws -> [Models.Post] {
            return []
        }
        
        func followUser(followerID: String, followedID: String) async throws -> Bool {
            return true
        }
        
        func unfollowUser(followerID: String, followedID: String) async throws -> Bool {
            return true
        }
        
        func likePost(postID: String, userID: String) async throws -> Models.Post {
            let author = Models.UserProfile(
                id: "mock-author-id",
                username: "mock_author",
                displayName: "Mock Author",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
            
            return Models.Post(
                id: postID,
                content: "Mock post content",
                author: author,
                track: nil,
                createdAt: Date(),
                likes: 1,
                comments: 0
            )
        }
        
        func getComments(postID: String) async throws -> [Comment] {
            return []
        }
        
        func addComment(postID: String, userID: String, content: String) async throws -> Comment {
            let author = Models.UserProfile(
                id: userID,
                username: "mock_user",
                displayName: "Mock User",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
            
            return Comment(
                id: "mock-comment-id",
                content: content,
                author: author,
                createdAt: Date(),
                likes: 0
            )
        }
        
        func createPost(content: String, userID: String, trackID: String? = nil) async throws -> Models.Post {
            let author = Models.UserProfile(
                id: userID,
                username: "mock_user",
                displayName: "Mock User",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
            
            return Models.Post(
                id: "mock-post-id",
                content: content,
                author: author,
                track: nil,
                createdAt: Date(),
                likes: 0,
                comments: 0
            )
        }
        
        func getPosts() async throws -> [Models.Post] {
            let author = Models.UserProfile(
                id: "mock-author-id",
                username: "mock_author",
                displayName: "Mock Author",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
            
            return [
                Models.Post(
                    id: "mock-post-1",
                    content: "This is a mock post",
                    author: author,
                    track: nil,
                    createdAt: Date(),
                    likes: 5,
                    comments: 2
                ),
                Models.Post(
                    id: "mock-post-2",
                    content: "Another mock post",
                    author: author,
                    track: nil,
                    createdAt: Date().addingTimeInterval(-3600),
                    likes: 10,
                    comments: 3
                )
            ]
        }
    }
    
    // MARK: - Social Posts
    
    /// Fetch social posts from the user's network
    /// - Returns: Array of social posts
    /// - Throws: Error if the operation fails
    public func getPosts() async throws -> [Models.Post] {
        // Use mock CloudKit service
        return try await MockCloudKitService.shared.getPosts()
    }
    
    /// Extended UserProfile with additional properties for the UI
    public struct ExtendedUserProfile: Identifiable {
        public let id: String
        public let username: String
        public let displayName: String
        public let bio: String?
        public let avatarUrl: URL?
        public let followers: Int
        public let following: Int
        public let favoriteTracks: [MusicKit.Track]
        public let isFollowing: Bool
        public let posts: [Models.Post]
        
        public init(
            id: String,
            username: String,
            displayName: String,
            bio: String?,
            avatarUrl: URL?,
            followers: Int,
            following: Int,
            favoriteTracks: [MusicKit.Track],
            isFollowing: Bool,
            posts: [Models.Post]
        ) {
            self.id = id
            self.username = username
            self.displayName = displayName
            self.bio = bio
            self.avatarUrl = avatarUrl
            self.followers = followers
            self.following = following
            self.favoriteTracks = favoriteTracks
            self.isFollowing = isFollowing
            self.posts = posts
        }
        
        // Convert from Models.UserProfile
        public init(from profile: Models.UserProfile, isFollowing: Bool = false, posts: [Models.Post] = []) {
            self.id = profile.id
            self.username = profile.username
            self.displayName = profile.displayName
            self.bio = profile.bio
            self.avatarUrl = profile.avatarUrl
            self.followers = profile.followers
            self.following = profile.following
            self.favoriteTracks = [] as [MusicKit.Track] // Explicitly cast to MusicKit.Track array
            self.isFollowing = isFollowing
            self.posts = posts
        }
    }
    
    /// Get a user profile
    /// - Parameter userId: The ID of the user
    /// - Returns: The user profile
    /// - Throws: Error if the operation fails
    public func getProfile(userId: String) async throws -> ExtendedUserProfile {
        // Get the current user ID to check if we're following this user
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Get the user profile from CloudKit
        let profile = try await MockCloudKitService.shared.getUserProfile(userID: userId)
        
        // Check if the current user is following this user
        let isFollowing = try await MockCloudKitService.shared.isFollowing(followerID: currentUserId, followedID: userId)
        
        // Get followers and following counts
        let followers = try await MockCloudKitService.shared.getFollowersCount(userID: userId)
        let following = try await MockCloudKitService.shared.getFollowingCount(userID: userId)
        
        // Get user's posts
        let userPosts = try await MockCloudKitService.shared.getUserPosts(userID: userId)
        
        // Create an extended profile with the additional information
        let extendedProfile = Models.UserProfile(
            id: profile.id,
            username: profile.username,
            displayName: profile.displayName,
            bio: profile.bio,
            avatarUrl: profile.avatarUrl,
            followers: followers,
            following: following,
            favoriteTracks: []
        )
        
        return ExtendedUserProfile(from: extendedProfile, isFollowing: isFollowing, posts: userPosts)
    }
    
    /// Follow a user
    /// - Parameter userId: The ID of the user to follow
    /// - Returns: The updated user profile
    /// - Throws: Error if the operation fails
    public func followUser(userId: String) async throws -> ExtendedUserProfile {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Follow the user in CloudKit
        let success = try await MockCloudKitService.shared.followUser(followerID: currentUserId, followedID: userId)
        
        if success {
            // Get the updated profile
            return try await getProfile(userId: userId)
        } else {
            throw NSError(domain: "SocialService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to follow user"])
        }
    }
    
    /// Unfollow a user
    /// - Parameter userId: The ID of the user to unfollow
    /// - Returns: The updated user profile
    /// - Throws: Error if the operation fails
    public func unfollowUser(userId: String) async throws -> ExtendedUserProfile {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Unfollow the user in CloudKit
        let success = try await MockCloudKitService.shared.unfollowUser(followerID: currentUserId, followedID: userId)
        
        if success {
            // Get the updated profile
            return try await getProfile(userId: userId)
        } else {
            throw NSError(domain: "SocialService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to unfollow user"])
        }
    }
    
    // MARK: - Profile Picture Management
    
    /// Upload a profile picture
    /// - Parameter imageData: The image data to upload
    /// - Returns: URL of the uploaded image
    /// - Throws: Error if the operation fails
    public func uploadProfilePicture(imageData: Data) async throws -> URL {
        // In a real app, this would upload the image to a storage service like CloudKit or Firebase Storage
        // For demo purposes, we'll simulate a successful upload and return a mock URL
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Generate a mock URL
        let mockImageId = UUID().uuidString
        let mockUrl = URL(string: "https://example.com/profile-pictures/\(mockImageId).jpg")!
        
        // Update the current user's profile with the new avatar URL
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // In a real app, you would update the user's profile in CloudKit
        // For now, we'll just return the mock URL
        
        return mockUrl
    }
    
    /// Update the current user's profile with a new avatar URL
    /// - Parameter avatarUrl: The URL of the avatar image
    /// - Returns: The updated user profile
    /// - Throws: Error if the operation fails
    public func updateProfileAvatar(avatarUrl: URL) async throws -> ExtendedUserProfile {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // In a real app, this would update the user's profile in CloudKit
        // For demo purposes, we'll just return the current profile with the updated avatar URL
        
        // Get the current profile
        let currentProfile = try await getProfile(userId: currentUserId)
        
        // Create a new profile with the updated avatar URL
        let updatedProfile = Models.UserProfile(
            id: currentProfile.id,
            username: currentProfile.username,
            displayName: currentProfile.displayName,
            bio: currentProfile.bio,
            avatarUrl: avatarUrl,
            followers: currentProfile.followers,
            following: currentProfile.following,
            favoriteTracks: currentProfile.favoriteTracks
        )
        
        // Return the updated profile
        return ExtendedUserProfile(
            from: updatedProfile,
            isFollowing: currentProfile.isFollowing,
            posts: currentProfile.posts
        )
    }
    
    /// Like a post
    /// - Parameter postId: The ID of the post to like
    /// - Returns: The updated post
    /// - Throws: Error if the operation fails
    public func likePost(postId: String) async throws -> Models.Post {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Like the post in CloudKit
        return try await MockCloudKitService.shared.likePost(postID: postId, userID: currentUserId)
    }
    
    /// Get comments for a specific post
    /// - Parameter postId: The ID of the post
    /// - Returns: Array of comments
    /// - Throws: Error if the operation fails
    public func getComments(forPostId postId: String) async throws -> [Comment] {
        // Get comments from CloudKit
        let cloudKitComments = try await MockCloudKitService.shared.getComments(postID: postId)
        
        // Convert CloudKit comments to our Comment type
        return cloudKitComments.map { cloudKitComment in
            Comment(
                id: cloudKitComment.id,
                content: cloudKitComment.content,
                author: cloudKitComment.author,
                createdAt: cloudKitComment.createdAt,
                likes: cloudKitComment.likes
            )
        }
    }
    
    /// Add a comment to a post
    /// - Parameters:
    ///   - postId: The ID of the post
    ///   - content: The comment content
    /// - Returns: The created comment
    /// - Throws: Error if the operation fails
    public func addComment(postId: String, content: String) async throws -> Comment {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Add the comment in CloudKit
        let cloudKitComment = try await MockCloudKitService.shared.addComment(postID: postId, userID: currentUserId, content: content)
        
        // Convert CloudKit comment to our Comment type
        return Comment(
            id: cloudKitComment.id,
            content: cloudKitComment.content,
            author: cloudKitComment.author,
            createdAt: cloudKitComment.createdAt,
            likes: cloudKitComment.likes
        )
    }
    
    /// Create a new post
    /// - Parameters:
    ///   - content: The post content
    ///   - trackId: Optional track ID to attach to the post
    /// - Returns: The created post
    /// - Throws: Error if the operation fails
    public func createPost(content: String, trackId: String? = nil) async throws -> Models.Post {
        // Get the current user ID
        let currentUserId = try await MockCloudKitService.shared.getCurrentUserID()
        
        // Create the post in CloudKit
        return try await MockCloudKitService.shared.createPost(content: content, userID: currentUserId, trackID: trackId)
    }
}
