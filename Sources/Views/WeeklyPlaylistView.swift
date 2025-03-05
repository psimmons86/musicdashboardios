import SwiftUI

@available(iOS 17.0, *)
public struct WeeklyPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playlist: Playlist?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPreferences = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else if let playlist = playlist {
                        // Playlist Info
                        StyledCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(playlist.name)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                if let description = playlist.description {
                                    Text(description)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                HStack(spacing: 16) {
                                    Label("\(playlist.tracks.count) tracks", systemImage: "music.note")
                                    if let genre = playlist.genre {
                                        Label(genre, systemImage: "guitars")
                                    }
                                    if let mood = playlist.mood {
                                        Label(mood.rawValue.capitalized, systemImage: "sparkles")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Schedule Info
                        if let schedule = playlist.schedule {
                            StyledCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Schedule")
                                            .font(.headline)
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button {
                                            showingPreferences = true
                                        } label: {
                                            Image(systemName: "gear")
                                                .font(.title2)
                                                .foregroundColor(AppTheme.accent)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Updates \(schedule.frequency.rawValue)")
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Next update: \(schedule.nextUpdate.formatted(date: .abbreviated, time: .shortened))")
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Tracks List
                        StyledCard {
                            VStack(spacing: 0) {
                                ForEach(playlist.tracks) { track in
                                    TrackRow(track: track, isSelected: false, onTap: nil)
                                        .padding(.vertical, 8)
                                    
                                    if track.id != playlist.tracks.last?.id {
                                        Divider()
                                            .background(AppTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let playlist = playlist {
                        Button {
                            NotificationService.shared.schedulePlaylistNotification(for: playlist)
                        } label: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPreferences) {
                PlaylistPreferencesView()
            }
            .onAppear {
                loadWeeklyPlaylist()
            }
            .background(AppTheme.darkBackground)
        }
    }
    
    private func loadWeeklyPlaylist() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                playlist = try await AppleMusicService.shared.getWeeklyPlaylist()
                isLoading = false
            } catch {
                errorMessage = "Failed to load weekly playlist"
                isLoading = false
            }
        }
    }
}


@available(iOS 17.0, *)
public struct WeeklyPlaylistView_Previews: PreviewProvider {
    public static var previews: some View {
        WeeklyPlaylistView()
    }
}
