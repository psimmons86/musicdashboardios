import SwiftUI
import MusicKit
import Services
import NewsViews

/// Namespace for dashboard-related views and components
public enum DashboardViews {}

extension DashboardViews {
    // Internal UI components
    fileprivate struct LoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading...")
                .foregroundColor(.secondary)
        }
    }
}

    fileprivate struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

    fileprivate struct GradientCard<Content: View>: View {
    let colors: [Color]
    let content: () -> Content
    
    init(colors: [Color], @ViewBuilder content: @escaping () -> Content) {
        self.colors = colors
        self.content = content
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading) {
                content()
            }
            .padding(16)
        }
    }
}

    // Internal types
    fileprivate struct PlaylistInfo {
    let name: String
    let tracks: [Services.Track]
}

    fileprivate struct ServiceConnectionCard: View {
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(isConnected ? "Apple Music Connected" : "Connect Apple Music")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(isConnected ? "Streaming data is available" : "Connect to access your music data")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if !isConnected {
                Button(action: onConnect) {
                    Text("Connect")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
    }
}

    fileprivate struct ConnectPromptView: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Connect to Apple Music")
                .font(.title2)
                .bold()
            
            Text("Connect your Apple Music account to see your recent plays, favorites, and personalized playlists.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: onConnect) {
                Text("Connect Now")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

    fileprivate struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Apple Music Authorization")
                .font(.title2.bold())
            
            Text("This will open Apple Music to request permission to access your library and listening data.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Request Permission") {
                requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .padding(.top)
        }
        .padding(30)
    }
    
    private func requestPermission() {
        Task {
            let status = await MusicAuthorization.request()
            if status == .authorized {
                dismiss()
            }
        }
    }
}

    @available(iOS 16.0, macOS 12.0, *)
    public struct DashboardView: View {
    @State private var recentlyPlayed: [Services.Track] = []
    @State private var topTracks: [Services.Track] = []
    @State private var newsArticles: [NewsArticle] = []
    @State private var selectedNewsGenre: String? = nil
    @State private var availableGenres: [String] = []
    @State private var newsSearchTerm: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isAuthorized = false
    @State private var showingAuthSheet = false
    @State private var generatedPlaylist: PlaylistInfo? = nil
    @State private var statsError: String? = nil
    @State private var showingSaveSuccess = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if isLoading {
                        LoadingView()
                    } else if let error = errorMessage {
                        ErrorView(message: error)
                    } else {
                        // Service Connection Status
                        GradientCard(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]) {
                            ServiceConnectionCard(
                                isConnected: isAuthorized,
                                onConnect: { showingAuthSheet = true }
                            )
                        }
                        .padding(.horizontal)
                        
                        if isAuthorized {
                            // Music Stats (simplified for now)
                            VStack(alignment: .leading, spacing: 16) {
                                if statsError != nil {
                                    Text("Unable to load stats: \(statsError ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if !topTracks.isEmpty {
                                    Text("Top Tracks")
                                        .font(.title2.bold())
                                    
                                    ForEach(topTracks.prefix(3)) { track in
                                        HStack {
                                            Text(track.title)
                                                .font(.body)
                                            Spacer()
                                            Text(track.artistName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // News Section
                            NewsViews.NewsSection(
                                newsArticles: newsArticles,
                                availableGenres: availableGenres,
                                selectedGenre: selectedNewsGenre,
                                onGenreSelected: { genre in
                                    selectedNewsGenre = genre
                                    Task {
                                        await loadNews()
                                    }
                                },
                                onSearch: { searchTerm in
                                    newsSearchTerm = searchTerm
                                    Task {
                                        await loadNews()
                                    }
                                }
                            )
                            .padding(.horizontal)
                        } else {
                            ConnectPromptView(onConnect: { showingAuthSheet = true })
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                Task {
                    await checkAuthorization()
                    await loadDashboard()
                }
            }
            .refreshable {
                await checkAuthorization()
                await loadDashboard()
            }
            .background(Color(UIColor.systemBackground))
            .alert("Playlist Saved", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your playlist has been saved to Apple Music")
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthSheet()
        }
    }
    
    private func savePlaylist(name: String, tracks: [Services.Track]) {
        Task {
            do {
                _ = try await AppleMusicService.shared.saveToAppleMusic(name: name, tracks: tracks)
                showingSaveSuccess = true
            } catch {
                print("Failed to save playlist: \(error)")
                errorMessage = "Failed to save playlist to Apple Music"
            }
        }
    }
    
    private func checkAuthorization() async {
        isAuthorized = MusicAuthorization.currentStatus == .authorized
    }
    
    private func loadNews() async {
        do {
            let news = try await NewsService.shared.getMusicNews(genre: selectedNewsGenre, searchTerm: newsSearchTerm)
            newsArticles = news
        } catch {
            print("News load error: \(error)")
            // Don't show error message for news load failures
        }
    }

    private func loadDashboard() async {
        guard isAuthorized else { return }
        
        isLoading = true
        errorMessage = nil
        statsError = nil
        
        async let recentlyPlayedTask = AppleMusicService.shared.getRecentlyPlayed()
        async let topTracksTask = AppleMusicService.shared.getTopTracks()
        async let genresTask = NewsService.shared.getAvailableGenres()
        
        do {
            let (recent, top, genres) = try await (recentlyPlayedTask, topTracksTask, genresTask)
            recentlyPlayed = recent
            topTracks = top
            availableGenres = genres
            
            // Load news separately to handle failures gracefully
            await loadNews()
        } catch {
            print("Dashboard load error: \(error)")
            errorMessage = "Failed to load music data. Please check your connection."
        }
        
        // Load stats separately to handle CloudKit errors gracefully
        do {
            let stats = try await AppleMusicService.shared.getStreamingStats()
            // StreamingStats.topTracks is already a [Track] array
            topTracks = stats.topTracks
            if recentlyPlayed.isEmpty {
                recentlyPlayed = topTracks // Use top tracks as recently played if empty
            }
        } catch {
            print("Stats load error: \(error)")
            statsError = "Unable to load streaming stats. Some features may be limited."
        }
        
        isLoading = false
    }
}

    @available(iOS 16.0, macOS 12.0, *)
    public struct DashboardView_Previews: PreviewProvider {
    public static var previews: some View {
        DashboardView()
    }
}
