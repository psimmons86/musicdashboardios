import SwiftUI
import Services
import MusicKit
import PhotosUI


@available(iOS 17.0, *)
public struct UserProfileView: View {
    let userId: String
    @State private var profile: SocialService.ExtendedUserProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isCurrentUser = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isUploadingImage = false
    
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
                            // Profile Picture with upload option for current user
                            ZStack(alignment: .bottomTrailing) {
                                if let avatarUrl = profile.avatarUrl {
                                    AsyncImage(url: avatarUrl) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color(AppTheme.surfaceBackground)
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Text(profile.displayName.prefix(1).uppercased())
                                                .foregroundColor(.white)
                                                .font(.title)
                                        )
                                }
                                
                                // Edit button for current user
                                if isCurrentUser {
                                    Button {
                                        showingImagePicker = true
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Circle().fill(AppTheme.accent))
                                    }
                                    .disabled(isUploadingImage)
                                    .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
                                    .onChange(of: selectedImage) { newValue in
                                        if let newValue = newValue {
                                            loadTransferable(from: newValue)
                                        }
                                    }
                                }
                            }
                            .overlay(
                                Group {
                                    if isUploadingImage {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                }
                            )
                            
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
                                PostView(post: post)
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
                // For demo purposes, treat "user1" as current user
                isCurrentUser = (userId == "user1")
                
                profile = try await SocialService.shared.getProfile(userId: userId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load profile"
                isLoading = false
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        Task {
            do {
                // Show loading indicator
                isUploadingImage = true
                
                // Load the image data from the picker
                if let data = try await imageSelection.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        // Update the UI with the selected image
                        profileImage = Image(uiImage: uiImage)
                        
                        // Upload the image to the server
                        let imageUrl = try await SocialService.shared.uploadProfilePicture(imageData: data)
                        
                        // Update the user's profile with the new avatar URL
                        profile = try await SocialService.shared.updateProfileAvatar(avatarUrl: imageUrl)
                    }
                }
                
                // Hide loading indicator
                isUploadingImage = false
            } catch {
                // Handle error
                errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
                isUploadingImage = false
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
