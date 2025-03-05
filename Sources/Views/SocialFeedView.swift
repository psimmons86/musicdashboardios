import SwiftUI

@available(iOS 17.0, *)
public struct SocialFeedView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else {
                        ForEach(posts) { post in
                            PostCard(post: post)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Feed")
            .background(AppTheme.darkBackground)
            .onAppear {
                loadFeed()
            }
            .refreshable {
                loadFeed()
            }
        }
    }
    
    private func loadFeed() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                posts = try await SocialService.shared.getFeedPosts()
                isLoading = false
            } catch {
                errorMessage = "Failed to load feed"
                isLoading = false
            }
        }
    }
}

@available(iOS 17.0, *)
public struct PostCard: View {
    let post: Post
    @State private var comments: [Comment] = []
    @State private var showComments = false
    @State private var newComment = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init(post: Post) {
        self.post = post
    }
    
    public var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(post.userId)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Content
                Text(post.content)
                    .foregroundColor(AppTheme.textPrimary)
                
                // Track or Playlist
                if let track = post.track {
                    TrackRow(track: track, isSelected: false, onTap: nil)
                        .padding(.vertical, 4)
                }
                
                if let playlist = post.playlist {
                    PlaylistRow(playlist: playlist)
                        .padding(.vertical, 4)
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button {
                        toggleLike()
                    } label: {
                        Label("\(post.likes)", systemImage: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? AppTheme.accent : AppTheme.textSecondary)
                    }
                    
                    Button {
                        loadComments()
                        showComments.toggle()
                    } label: {
                        Label("\(post.comments)", systemImage: "bubble.right")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                // Comments Section
                if showComments {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 8)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(AppTheme.error)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                            
                            HStack {
                                TextField("Add a comment...", text: $newComment)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button {
                                    submitComment()
                                } label: {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private func toggleLike() {
        Task {
            do {
                if post.isLiked {
                    _ = try await SocialService.shared.unlikePost(postId: post.id)
                } else {
                    _ = try await SocialService.shared.likePost(postId: post.id)
                }
            } catch {
                errorMessage = "Failed to update like"
            }
        }
    }
    
    private func loadComments() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                comments = try await SocialService.shared.getComments(postId: post.id)
                isLoading = false
            } catch {
                errorMessage = "Failed to load comments"
                isLoading = false
            }
        }
    }
    
    private func submitComment() {
        guard !newComment.isEmpty else { return }
        
        Task {
            do {
                let comment = try await SocialService.shared.addComment(postId: post.id, content: newComment)
                comments.append(comment)
                newComment = ""
            } catch {
                errorMessage = "Failed to add comment"
            }
        }
    }
}

@available(iOS 17.0, *)
public struct CommentRow: View {
    let comment: Comment
    
    public init(comment: Comment) {
        self.comment = comment
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.userId)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Text(comment.content)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack {
                Button {
                    // Toggle like
                } label: {
                    Label("\(comment.likes)", systemImage: comment.isLiked ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(comment.isLiked ? AppTheme.accent : AppTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 17.0, *)
public struct SocialFeedView_Previews: PreviewProvider {
    public static var previews: some View {
        SocialFeedView()
            .preferredColorScheme(.dark)
    }
}
