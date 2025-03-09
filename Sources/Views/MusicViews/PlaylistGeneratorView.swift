import SwiftUI
import MusicKit
import Services
import Components

@available(iOS 16.0, macOS 12.0, *)
public struct PlaylistGeneratorView: View {
    @Binding var generatedPlaylist: MusicViews.PlaylistInfo?
    @State private var isGenerating = false
    @State private var isSaving = false
    @State private var error: String?
    @State private var successMessage: String?
    @State private var playlistName = "My Custom Playlist"
    @State private var selectedGenre: String = "Pop"
    @State private var selectedMood: String = "Energetic"
    @State private var trackCount: Int = 15
    
    private let availableGenres = ["Pop", "Rock", "Hip-Hop", "Electronic", "Jazz", "Classical", "R&B", "Country", "Latin", "K-Pop"]
    private let availableMoods = ["Energetic", "Chill", "Focus", "Workout", "Party", "Relaxing", "Upbeat", "Melancholic"]
    
    public init(generatedPlaylist: Binding<MusicViews.PlaylistInfo?>) {
        self._generatedPlaylist = generatedPlaylist
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Playlist Name
                VStack(alignment: .leading) {
                    Text("Playlist Name")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    TextField("Enter playlist name", text: $playlistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Genre Selection
                VStack(alignment: .leading) {
                    Text("Genre")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Picker("Select Genre", selection: $selectedGenre) {
                        ForEach(availableGenres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(8)
                    .background(AppTheme.surfaceBackground)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Mood Selection
                VStack(alignment: .leading) {
                    Text("Mood")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Picker("Select Mood", selection: $selectedMood) {
                        ForEach(availableMoods, id: \.self) { mood in
                            Text(mood).tag(mood)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(8)
                    .background(AppTheme.surfaceBackground)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Track Count
                VStack(alignment: .leading) {
                    Text("Number of Tracks: \(trackCount)")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Slider(value: Binding(
                        get: { Double(trackCount) },
                        set: { trackCount = Int($0) }
                    ), in: 5...30, step: 1)
                }
                .padding(.horizontal)
                
                // Generate Button
                if isGenerating || isSaving {
                    MusicViews.LoadingView()
                        .padding()
                } else if let error = error {
                    MusicViews.ErrorView(message: error)
                        .padding()
                    
                    Button("Try Again") {
                        generatePlaylist()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.secondaryGradient)
                    .foregroundColor(AppTheme.textOnDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if let successMessage = successMessage {
                    // Success message
                    Text(successMessage)
                        .foregroundColor(Color.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding()
                    
                    // Generate another button
                    Button("Generate Another Playlist") {
                        successMessage = nil
                        generatedPlaylist = nil
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.secondaryGradient)
                    .foregroundColor(AppTheme.textOnDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if let playlist = generatedPlaylist {
                    // Display generated playlist
                    VStack(spacing: 16) {
                        Text("Playlist Generated!")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("\(playlist.tracks.count) tracks based on \(selectedGenre) with \(selectedMood) mood")
                            .foregroundColor(AppTheme.textSecondary)
                        
                        // Save to Apple Music button
                        Button("Save to Apple Music") {
                            saveToAppleMusic(playlist: playlist)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(AppTheme.textOnDark)
                        .cornerRadius(12)
                        
                        // Generate another button
                        Button("Generate Another") {
                            generatedPlaylist = nil
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.secondaryGradient)
                        .foregroundColor(AppTheme.textOnDark)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    Button("Generate Playlist") {
                        generatePlaylist()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryGradient)
                    .foregroundColor(AppTheme.textOnDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Playlist Generator")
        .background(AppTheme.background)
    }
    
    private func generatePlaylist() {
        isGenerating = true
        error = nil
        
        Task {
            do {
                // Get tracks based on genre and mood
                let searchTerm = "\(selectedGenre) \(selectedMood) music"
                let tracks = try await AppleMusicService.shared.searchTracks(term: searchTerm, limit: trackCount)
                
                if tracks.isEmpty {
                    throw NSError(domain: "PlaylistGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "No tracks found for the selected criteria"])
                }
                
                generatedPlaylist = MusicViews.PlaylistInfo(name: playlistName, tracks: tracks)
            } catch {
                self.error = "Failed to generate playlist: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
    
    private func saveToAppleMusic(playlist: MusicViews.PlaylistInfo) {
        isSaving = true
        error = nil
        
        Task {
            do {
                // Save playlist to Apple Music
                let success = try await AppleMusicService.shared.saveToAppleMusic(name: playlist.name, tracks: playlist.tracks)
                
                if success {
                    successMessage = "Playlist '\(playlist.name)' saved to Apple Music!"
                    generatedPlaylist = nil
                } else {
                    throw NSError(domain: "PlaylistGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save playlist to Apple Music"])
                }
            } catch {
                self.error = "Failed to save playlist: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
