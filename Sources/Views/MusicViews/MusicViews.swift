import SwiftUI
import MusicKit
import Services
import Components

// MARK: - MusicViews Module Public Interface

/// The main namespace for the MusicViews module
public enum MusicViews {}

// MARK: - Public Components Extensions

extension MusicViews {
    // Using Components versions of these UI components
    public typealias GradientCard = Components.GradientCard
    public typealias LoadingView = Components.LoadingView
    public typealias ErrorView = Components.ErrorView
    public typealias TrackRowModern = Components.TrackRowModern
    public typealias SectionHeader = Components.SectionHeader
    public typealias QuickActionButton = Components.QuickActionButton
}

// MARK: - Data Models
extension MusicViews {
    // Playlist info model for generated playlists
    public struct PlaylistInfo {
        public let name: String
        public let tracks: [Services.Track]
        
        public init(name: String, tracks: [Services.Track]) {
            self.name = name
            self.tracks = tracks
        }
    }
}

// MARK: - Main Music View
extension MusicViews {
    public struct MusicView: View {
        @State private var authorizationStatus: MusicAuthorization.Status = .notDetermined
        
        public init() {}
        
        public var body: some View {
            VStack {
                if authorizationStatus == .authorized {
                    // Show music content when authorized
                    MusicContentView()
                } else {
                    // Show authorization request
                    VStack(spacing: 20) {
                        Text("Apple Music Access Required")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("This app needs access to your Apple Music account to provide personalized music recommendations.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal)
                        
                        Button("Authorize Apple Music") {
                            requestMusicAuthorization()
                        }
                        .padding()
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(AppTheme.textOnDark)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppTheme.surfaceBackground)
                    .cornerRadius(16)
                    .padding()
                }
            }
            .background(AppTheme.background)
            .onAppear {
                // Check current authorization status when view appears
                authorizationStatus = AppleMusicService.shared.checkAuthorizationStatus()
                if authorizationStatus != .authorized {
                    requestMusicAuthorization()
                }
            }
        }
        
        private func requestMusicAuthorization() {
            Task {
                authorizationStatus = await AppleMusicService.shared.requestAuthorization()
            }
        }
    }
}

// Supporting views for MusicView
fileprivate struct MusicContentView: View {
    @State private var tracks: [Services.Track] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.background.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Loading music...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppTheme.mediumPurple)
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(AppTheme.error)
                            
                            Text(error)
                                .font(.body)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Retry") {
                                loadMusic()
                            }
                            .padding()
                            .background(AppTheme.primaryGradient)
                            .foregroundColor(AppTheme.textOnDark)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(AppTheme.surfaceBackground)
                        .cornerRadius(16)
                        .padding()
                    } else if tracks.isEmpty {
                        Text("No tracks found")
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(tracks, id: \.id) { track in
                                    TrackRow(track: track)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.surfaceBackground)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Apple Music")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadMusic()
            }
        }
    }
    
    private func loadMusic() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get real music data from Apple Music
                tracks = try await AppleMusicService.shared.getRecommendedTracks()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

fileprivate struct TrackRow: View {
    let track: Services.Track
    
    var body: some View {
        HStack {
            // Display artwork if available
            if let artwork = track.artwork {
                AsyncImage(url: artwork.url(width: 60, height: 60)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppTheme.mediumPurple)
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    case .failure:
                        AppTheme.mediumPurple.opacity(0.3)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(AppTheme.textOnDark.opacity(0.6))
                            )
                    @unknown default:
                        AppTheme.mediumPurple.opacity(0.3)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(AppTheme.textOnDark.opacity(0.6))
                            )
                    }
                }
                .frame(width: 60, height: 60)
            } else {
                // Placeholder for missing artwork
                AppTheme.mediumPurple.opacity(0.3)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(AppTheme.textOnDark.opacity(0.6))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.mediumPurple)
        }
    }
}
