import Foundation
import CloudKit
import MusicKit

public class CloudKitService {
    public static let shared = CloudKitService()
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    
    // Record types
    private let userRecordType = "User"
    private let postRecordType = "Post"
    private let commentRecordType = "Comment"
    private let likeRecordType = "Like"
    private let followRecordType = "Follow"
    
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    // MARK: - User Authentication
    
    /// Get the current user's ID
    public func getCurrentUserID() async throws -> String {
        do {
            let userRecord = try await container.userRecordID()
            return userRecord.recordName
        } catch {
            throw NSError(domain: "CloudKitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID: \(error.localizedDescription)"])
        }
    }
    
    /// Check if the user is logged in to iCloud
    public func checkUserLoggedIn() async -> Bool {
        do {
            let _ = try await container.userRecordID()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - User Profile
    
    /// Get a user profile by ID
    public func getUserProfile(userID: String) async throws -> Models.UserProfile {
        let recordID = CKRecord.ID(recordName: userID)
        
        do {
            let record = try await publicDB.record(for: recordID)
            return userRecordToProfile(record)
        } catch {
            throw NSError(domain: "CloudKitService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get user profile: \(error.localizedDescription)"])
        }
    }
    
    /// Create or update a user profile
    public func saveUserProfile(profile: Models.UserProfile) async throws -> Models.UserProfile {
        let recordID = CKRecord.ID(recordName: profile.id)
        
        // Check if record exists
        let record: CKRecord
        do {
            record = try await publicDB.record(for: recordID)
        } catch {
            // Create new record if it doesn't exist
            record = CKRecord(recordType: userRecordType, recordID: recordID)
        }
        
        // Update record fields
        record["username"] = profile.username
        record["displayName"] = profile.displayName
        record["bio"] = profile.bio
        record["avatarUrl"] = profile.avatarUrl?.absoluteString
        
        // Save record
        do {
            let savedRecord = try await publicDB.save(record)
            return userRecordToProfile(savedRecord)
        } catch {
            throw NSError(domain: "CloudKitService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to save user profile: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Posts
    
    /// Get all posts
    public func getPosts() async throws -> [Models.Post] {
        let query = CKQuery(recordType: postRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 50)
            
            var posts: [Models.Post] = []
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let post = try? await postRecordToPost(record) {
                        posts.append(post)
                    }
                case .failure:
                    continue
                }
            }
            
            return posts
        } catch {
            throw NSError(domain: "CloudKitService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to get posts: \(error.localizedDescription)"])
        }
    }
    
    /// Get posts by a specific user
    public func getUserPosts(userID: String) async throws -> [Models.Post] {
        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let predicate = NSPredicate(format: "author == %@", userReference)
        let query = CKQuery(recordType: postRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 50)
            
            var posts: [Models.Post] = []
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let post = try? await postRecordToPost(record) {
                        posts.append(post)
                    }
                case .failure:
                    continue
                }
            }
            
            return posts
        } catch {
            throw NSError(domain: "CloudKitService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to get user posts: \(error.localizedDescription)"])
        }
    }
    
    /// Create a new post
    public func createPost(content: String, userID: String, trackID: String? = nil) async throws -> Models.Post {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: postRecordType, recordID: recordID)
        
        // Set post fields
        record["content"] = content
        record["createdAt"] = Date()
        record["likes"] = 0
        record["comments"] = 0
        
        // Set author reference
        let authorReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        record["author"] = authorReference
        
        // Set track reference if provided
        if let trackID = trackID {
            record["trackID"] = trackID
        }
        
        // Save record
        do {
            let savedRecord = try await publicDB.save(record)
            return try await postRecordToPost(savedRecord)
        } catch {
            throw NSError(domain: "CloudKitService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create post: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Likes
    
    /// Like a post
    public func likePost(postID: String, userID: String) async throws -> Models.Post {
        // Check if user already liked the post
        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let postReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: postID), action: .deleteSelf)
        
        let predicate = NSPredicate(format: "user == %@ AND post == %@", userReference, postReference)
        let query = CKQuery(recordType: likeRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            
            if results.isEmpty {
                // Create new like record
                let likeRecord = CKRecord(recordType: likeRecordType)
                likeRecord["user"] = userReference
                likeRecord["post"] = postReference
                likeRecord["createdAt"] = Date()
                
                try await publicDB.save(likeRecord)
                
                // Increment post likes count
                let postRecord = try await publicDB.record(for: CKRecord.ID(recordName: postID))
                let currentLikes = postRecord["likes"] as? Int ?? 0
                postRecord["likes"] = currentLikes + 1
                
                let updatedPostRecord = try await publicDB.save(postRecord)
                return try await postRecordToPost(updatedPostRecord)
            } else {
                // Already liked, return post
                let postRecord = try await publicDB.record(for: CKRecord.ID(recordName: postID))
                return try await postRecordToPost(postRecord)
            }
        } catch {
            throw NSError(domain: "CloudKitService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to like post: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Comments
    
    /// Get comments for a post
    public func getComments(postID: String) async throws -> [Models.Comment] {
        let postReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: postID), action: .none)
        let predicate = NSPredicate(format: "post == %@", postReference)
        let query = CKQuery(recordType: commentRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 100)
            
            var comments: [Models.Comment] = []
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let comment = try? await commentRecordToComment(record) {
                        comments.append(comment)
                    }
                case .failure:
                    continue
                }
            }
            
            return comments
        } catch {
            throw NSError(domain: "CloudKitService", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to get comments: \(error.localizedDescription)"])
        }
    }
    
    /// Add a comment to a post
    public func addComment(postID: String, userID: String, content: String) async throws -> Models.Comment {
        // Create comment record
        let commentRecord = CKRecord(recordType: commentRecordType)
        
        let postReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: postID), action: .deleteSelf)
        let authorReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        
        commentRecord["post"] = postReference
        commentRecord["author"] = authorReference
        commentRecord["content"] = content
        commentRecord["createdAt"] = Date()
        commentRecord["likes"] = 0
        
        do {
            // Save comment
            let savedComment = try await publicDB.save(commentRecord)
            
            // Increment post comments count
            let postRecord = try await publicDB.record(for: CKRecord.ID(recordName: postID))
            let currentComments = postRecord["comments"] as? Int ?? 0
            postRecord["comments"] = currentComments + 1
            try await publicDB.save(postRecord)
            
            return try await commentRecordToComment(savedComment)
        } catch {
            throw NSError(domain: "CloudKitService", code: 9, userInfo: [NSLocalizedDescriptionKey: "Failed to add comment: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Follow
    
    /// Follow a user
    public func followUser(followerID: String, followedID: String) async throws -> Bool {
        // Check if already following
        let followerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followerID), action: .none)
        let followedReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followedID), action: .none)
        
        let predicate = NSPredicate(format: "follower == %@ AND followed == %@", followerReference, followedReference)
        let query = CKQuery(recordType: followRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            
            if results.isEmpty {
                // Create new follow record
                let followRecord = CKRecord(recordType: followRecordType)
                followRecord["follower"] = followerReference
                followRecord["followed"] = followedReference
                followRecord["createdAt"] = Date()
                
                try await publicDB.save(followRecord)
                return true
            } else {
                // Already following
                return true
            }
        } catch {
            throw NSError(domain: "CloudKitService", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to follow user: \(error.localizedDescription)"])
        }
    }
    
    /// Unfollow a user
    public func unfollowUser(followerID: String, followedID: String) async throws -> Bool {
        let followerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followerID), action: .none)
        let followedReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followedID), action: .none)
        
        let predicate = NSPredicate(format: "follower == %@ AND followed == %@", followerReference, followedReference)
        let query = CKQuery(recordType: followRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            
            for (recordID, result) in results {
                switch result {
                case .success:
                    try await publicDB.deleteRecord(withID: recordID)
                case .failure:
                    continue
                }
            }
            
            return true
        } catch {
            throw NSError(domain: "CloudKitService", code: 11, userInfo: [NSLocalizedDescriptionKey: "Failed to unfollow user: \(error.localizedDescription)"])
        }
    }
    
    /// Check if a user is following another user
    public func isFollowing(followerID: String, followedID: String) async throws -> Bool {
        let followerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followerID), action: .none)
        let followedReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: followedID), action: .none)
        
        let predicate = NSPredicate(format: "follower == %@ AND followed == %@", followerReference, followedReference)
        let query = CKQuery(recordType: followRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            return !results.isEmpty
        } catch {
            throw NSError(domain: "CloudKitService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to check following status: \(error.localizedDescription)"])
        }
    }
    
    /// Get followers count for a user
    public func getFollowersCount(userID: String) async throws -> Int {
        let followedReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let predicate = NSPredicate(format: "followed == %@", followedReference)
        let query = CKQuery(recordType: followRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1000)
            return results.count
        } catch {
            throw NSError(domain: "CloudKitService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Failed to get followers count: \(error.localizedDescription)"])
        }
    }
    
    /// Get following count for a user
    public func getFollowingCount(userID: String) async throws -> Int {
        let followerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let predicate = NSPredicate(format: "follower == %@", followerReference)
        let query = CKQuery(recordType: followRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1000)
            return results.count
        } catch {
            throw NSError(domain: "CloudKitService", code: 14, userInfo: [NSLocalizedDescriptionKey: "Failed to get following count: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert a CKRecord to a UserProfile
    private func userRecordToProfile(_ record: CKRecord) -> Models.UserProfile {
        let id = record.recordID.recordName
        let username = record["username"] as? String ?? "user_\(id.prefix(8))"
        let displayName = record["displayName"] as? String ?? username
        let bio = record["bio"] as? String
        
        var avatarUrl: URL? = nil
        if let avatarUrlString = record["avatarUrl"] as? String {
            avatarUrl = URL(string: avatarUrlString)
        }
        
        // Default values for followers, following, and favoriteTracks
        // In a real implementation, these would be fetched from the database
        let followers = 0
        let following = 0
        let favoriteTracks: [Track] = []
        
        return Models.UserProfile(
            id: id,
            username: username,
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            followers: followers,
            following: following,
            favoriteTracks: favoriteTracks
        )
    }
    
    /// Convert a CKRecord to a Post
    private func postRecordToPost(_ record: CKRecord) async throws -> Models.Post {
        let id = record.recordID.recordName
        let content = record["content"] as? String ?? ""
        let createdAt = record["createdAt"] as? Date ?? Date()
        let likes = record["likes"] as? Int ?? 0
        let comments = record["comments"] as? Int ?? 0
        
        // Get author
        let authorReference = record["author"] as? CKRecord.Reference
        let author: Models.UserProfile
        
        if let authorRef = authorReference {
            do {
                let authorRecord = try await publicDB.record(for: authorRef.recordID)
                author = userRecordToProfile(authorRecord)
            } catch {
                // Create a placeholder author if we can't fetch the real one
                author = Models.UserProfile(
                    id: authorReference?.recordID.recordName ?? "unknown",
                    username: "unknown_user",
                    displayName: "Unknown User",
                    bio: nil,
                    avatarUrl: nil,
                    followers: 0,
                    following: 0,
                    favoriteTracks: []
                )
            }
        } else {
            // Create a placeholder author if there's no reference
            author = Models.UserProfile(
                id: "unknown",
                username: "unknown_user",
                displayName: "Unknown User",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
        }
        
        // Get track if available
        let trackID = record["trackID"] as? String
        var track: MusicKit.Track? = nil
        
        if let trackID = trackID {
            // In a real implementation, we would fetch the track from MusicKit
            // For now, we'll leave it as nil
        }
        
        return Models.Post(
            id: id,
            content: content,
            author: author,
            track: track,
            createdAt: createdAt,
            likes: likes,
            comments: comments
        )
    }
    
    /// Convert a CKRecord to a Comment
    private func commentRecordToComment(_ record: CKRecord) async throws -> Models.Comment {
        let id = record.recordID.recordName
        let content = record["content"] as? String ?? ""
        let createdAt = record["createdAt"] as? Date ?? Date()
        let likes = record["likes"] as? Int ?? 0
        
        // Get author
        let authorReference = record["author"] as? CKRecord.Reference
        let author: Models.UserProfile
        
        if let authorRef = authorReference {
            do {
                let authorRecord = try await publicDB.record(for: authorRef.recordID)
                author = userRecordToProfile(authorRecord)
            } catch {
                // Create a placeholder author if we can't fetch the real one
                author = Models.UserProfile(
                    id: authorReference?.recordID.recordName ?? "unknown",
                    username: "unknown_user",
                    displayName: "Unknown User",
                    bio: nil,
                    avatarUrl: nil,
                    followers: 0,
                    following: 0,
                    favoriteTracks: []
                )
            }
        } else {
            // Create a placeholder author if there's no reference
            author = Models.UserProfile(
                id: "unknown",
                username: "unknown_user",
                displayName: "Unknown User",
                bio: nil,
                avatarUrl: nil,
                followers: 0,
                following: 0,
                favoriteTracks: []
            )
        }
        
        return Models.Comment(
            id: id,
            content: content,
            author: author,
            createdAt: createdAt,
            likes: likes
        )
    }
}
