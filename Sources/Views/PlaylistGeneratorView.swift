import SwiftUI

@available(iOS 17.0, *)
public struct PlaylistGeneratorView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [Track] = []
    @State private var selectedTracks: [Track] = []
    @State private var selectedGenre: String? = nil
    @State private var availableGenres: [String] = []
    @State private var generatedPlaylist: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    SearchBar(
                        text: $searchQuery,
                        placeholder: "Search for tracks",
                        onSubmit: search
                    )
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else {
                        // Genre Picker
                        Menu {
                            Button("All Genres") {
                                selectedGenre = nil
                            }
                            Divider()
                            ForEach(availableGenres, id: \.self) { genre in
                                Button(genre) {
                                    selectedGenre = genre
                                }
                            }
                        } label: {
                            Label(selectedGenre ?? "All Genres", systemImage: "music.note.list")
                                .foregroundColor(AppTheme.accent)
                        }
                        .padding(.horizontal)
                        
                        // Search Results
                        if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Search Results")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(searchResults) { track in
                                            TrackCard(track: track)
                                                .onTapGesture {
                                                    if selectedTracks.contains(track) {
                                                        selectedTracks.removeAll { $0.id == track.id }
                                                    } else if selectedTracks.count < 5 {
                                                        selectedTracks.append(track)
                                                    }
                                                }
                                                .overlay(
                                                    selectedTracks.contains(track) ?
                                                    Circle()
                                                        .fill(AppTheme.accent)
                                                        .frame(width: 24, height: 24)
                                                        .overlay(
                                                            Image(systemName: "checkmark")
                                                                .font(.caption)
                                                                .foregroundColor(.white)
                                                        )
                                                        .padding(8)
                                                    : nil,
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Selected Tracks
                        if !selectedTracks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Selected Tracks")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(selectedTracks) { track in
                                            TrackCard(track: track)
                                                .onTapGesture {
                                                    selectedTracks.removeAll { $0.id == track.id }
                                                }
                                                .overlay(
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundColor(.white)
                                                        .padding(8),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            StyledButton(
                                "Generate Playlist",
                                icon: "wand.and.stars",
                                action: generatePlaylist
                            )
                            .padding(.horizontal)
                            .disabled(selectedTracks.isEmpty)
                        }
                        
                        // Generated Playlist
                        if !generatedPlaylist.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Generated Playlist")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(generatedPlaylist) { track in
                                            TrackCard(track: track)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Playlist Generator")
            .background(AppTheme.darkBackground)
            .onAppear {
                loadGenres()
            }
        }
    }
    
    private func loadGenres() {
        Task {
            do {
                availableGenres = try await AppleMusicService.shared.getAvailableGenres()
            } catch {
                errorMessage = "Failed to load genres"
            }
        }
    }
    
    private func search() {
        guard !searchQuery.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                searchResults = try await AppleMusicService.shared.searchTracks(query: searchQuery)
                isLoading = false
            } catch {
                errorMessage = "Failed to search tracks"
                isLoading = false
            }
        }
    }
    
    private func generatePlaylist() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                generatedPlaylist = try await AppleMusicService.shared.generatePlaylist(from: selectedTracks, genre: selectedGenre)
                isLoading = false
            } catch {
                errorMessage = "Failed to generate playlist"
                isLoading = false
            }
        }
    }
}

@available(iOS 17.0, *)
public struct PlaylistGeneratorView_Previews: PreviewProvider {
    public static var previews: some View {
        PlaylistGeneratorView()
            .preferredColorScheme(.dark)
    }
}
