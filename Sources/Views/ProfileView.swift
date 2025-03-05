import SwiftUI

@available(iOS 17.0, *)
public struct UserProfileView: View {
    let userId: String
    @State private var profile: UserProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init(userId: String) {
        self.userId = userId
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else if let profile = profile {
                        // Profile Header
                        VStack(spacing: 16) {
                            if let avatarURL = profile.avatarURL {
                                AsyncImage(url: URL(string: avatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color(AppTheme.surfaceBackground)
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            }
                            
                            Text(profile.username)
                                .font(.title2)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            if let bio = profile.bio {
                                Text(bio)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Stats
                            HStack(spacing: 32) {
                                VStack {
                                    Text("\(profile.followers)")
                                        .font(.headline)
                                    Text("Followers")
                                        .font(.caption)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                
                                VStack {
                                    Text("\(profile.following)")
                                        .font(.headline)
                                    Text("Following")
                                        .font(.caption)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                            }
                            
                            if userId != "user1" {
                                Button {
                                    toggleFollow()
                                } label: {
                                    Text(profile.isFollowing ? "Following" : "Follow")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120)
                                        .padding(.vertical, 8)
                                        .background(profile.isFollowing ? AppTheme.accent : AppTheme.surfaceBackground)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        
                        // Posts
                        LazyVStack(spacing: 16) {
                            ForEach(profile.posts) { post in
                                PostCard(post: post)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .background(AppTheme.darkBackground)
            .onAppear {
                loadProfile()
            }
            .refreshable {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                profile = try await SocialService.shared.getProfile(userId: userId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load profile"
                isLoading = false
            }
        }
    }
    
    private func toggleFollow() {
        guard var currentProfile = profile else { return }
        
        Task {
            do {
                if currentProfile.isFollowing {
                    currentProfile = try await SocialService.shared.unfollowUser(userId: userId)
                } else {
                    currentProfile = try await SocialService.shared.followUser(userId: userId)
                }
                profile = currentProfile
            } catch {
                errorMessage = "Failed to update follow status"
            }
        }
    }
}

@available(iOS 17.0, *)
public struct UserProfileView_Previews: PreviewProvider {
    public static var previews: some View {
        UserProfileView(userId: "user1")
            .preferredColorScheme(.dark)
    }
}
