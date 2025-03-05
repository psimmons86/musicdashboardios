import SwiftUI
import MusicKit

@available(iOS 17.0, *)
public struct DashboardView: View {
    @State private var recentlyPlayed: [Track] = []
    @State private var topTracks: [Track] = []
    @State private var newsArticles: [NewsArticle] = []
    @State private var selectedNewsGenre: String? = nil
    @State private var availableGenres: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isAuthorized = false
    @State private var showingAuthSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) { // Increased spacing between main sections
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        ErrorView(message: error)
                    } else {
                        // Service Connection Status
                        ServiceConnectionCard(
                            isConnected: isAuthorized,
                            onConnect: { showingAuthSheet = true }
                        )
                        .padding(.horizontal)
                        
                        if isAuthorized {
                            // Quick Actions
                            QuickActionsSection()
                                .padding(.horizontal)
                            
                            // Music Stats
                            MusicStatsSection(
                                recentlyPlayed: recentlyPlayed,
                                topTracks: topTracks
                            )
                            .padding(.horizontal)
                            
                            // News Section
                            NewsSection(
                                newsArticles: newsArticles,
                                availableGenres: availableGenres,
                                selectedGenre: selectedNewsGenre,
                                onGenreSelected: { genre in
                                    selectedNewsGenre = genre
                                    Task { await loadDashboard() }
                                }
                            )
                            .padding(.horizontal)
                        } else {
                            ConnectPromptView(onConnect: { showingAuthSheet = true })
                        }
                    }
                }
                .padding(.vertical, 24) // Add padding at top and bottom
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
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthSheet()
        }
    }
    
    private func checkAuthorization() async {
        isAuthorized = MusicAuthorization.currentStatus == .authorized
    }
    
    private func loadDashboard() async {
        guard isAuthorized else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let recentlyPlayedTask = AppleMusicService.shared.getRecentlyPlayed()
            async let topTracksTask = AppleMusicService.shared.getTopTracks()
            async let newsTask = NewsService.shared.getMusicNews(genre: selectedNewsGenre)
            async let genresTask = NewsService.shared.getAvailableGenres()
            
            let (recent, top, news, genres) = try await (recentlyPlayedTask, topTracksTask, newsTask, genresTask)
            
            recentlyPlayed = recent
            topTracks = top
            newsArticles = news
            availableGenres = genres
            
            isLoading = false
        } catch {
            print("Dashboard load error: \(error)")
            errorMessage = "Failed to load music data. Please check your connection."
            isLoading = false
        }
    }
}

// MARK: - Error View
@available(iOS 17.0, *)
private struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Connect Prompt
@available(iOS 17.0, *)
private struct ConnectPromptView: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.mic")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            Text("Connect to Apple Music")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Text("View your music stats, generate playlists, and discover new music")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onConnect) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.purple.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
        .padding()
    }
}

// MARK: - Quick Actions Section
@available(iOS 17.0, *)
private struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2.weight(.bold))
            
            HStack(spacing: 16) {
                NavigationLink(destination: PlaylistGeneratorView()) {
                    QuickActionButton(
                        title: "Generate Playlist",
                        icon: "wand.and.stars",
                        gradient: [Color.purple, Color.blue]
                    )
                }
                
                NavigationLink(destination: StreamingStatsView()) {
                    QuickActionButton(
                        title: "View Stats",
                        icon: "chart.bar.fill",
                        gradient: [Color.orange, Color.red]
                    )
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

// MARK: - Music Stats Section
@available(iOS 17.0, *)
private struct MusicStatsSection: View {
    let recentlyPlayed: [Track]
    let topTracks: [Track]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Recently Played
            VStack(alignment: .leading, spacing: 16) {
                Text("Recently Played")
                    .font(.title2.weight(.bold))
                
                if recentlyPlayed.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(recentlyPlayed.prefix(3)) { track in
                        TrackRowModern(track: track)
                    }
                }
            }
            
            // Top Tracks
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Tracks")
                    .font(.title2.weight(.bold))
                
                if topTracks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(topTracks.prefix(3)) { track in
                        TrackRowModern(track: track)
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct TrackRowModern: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: track.artworkURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

// MARK: - News Section
@available(iOS 17.0, *)
private struct NewsSection: View {
    let newsArticles: [NewsArticle]
    let availableGenres: [String]
    let selectedGenre: String?
    let onGenreSelected: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Music News")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                Menu {
                    Button("All Genres") {
                        onGenreSelected(nil)
                    }
                    ForEach(availableGenres, id: \.self) { genre in
                        Button(genre) {
                            onGenreSelected(genre)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedGenre ?? "All Genres")
                        Image(systemName: "chevron.down")
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            if newsArticles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(newsArticles.prefix(3)) { article in
                    NewsArticleRowModern(article: article)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct NewsArticleRowModern: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: article.urlToImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = article.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(article.publishedAt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Service Connection Card
@available(iOS 17.0, *)
private struct ServiceConnectionCard: View {
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "music.mic")
                .font(.title)
                .foregroundStyle(.purple.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Music")
                    .font(.headline)
                
                Text(isConnected ? "Connected" : "Not connected")
                    .font(.subheadline)
                    .foregroundColor(isConnected ? .green : .secondary)
            }
            
            Spacer()
            
            if !isConnected {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.purple.gradient)
                        .clipShape(Capsule())
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Auth Sheet
@available(iOS 17.0, *)
private struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "music.mic")
                    .font(.system(size: 72))
                    .foregroundStyle(.purple.gradient)
                
                VStack(spacing: 16) {
                    Text("Connect to Apple Music")
                        .font(.title.weight(.bold))
                    
                    Text("Sign in to access your music library, playlists, and listening history")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Button(action: {
                        isLoading = true
                        errorMessage = nil
                        Task {
                            let status = await MusicAuthorization.request()
                            if status == .authorized {
                                do {
                                    _ = try await AppleMusicService.shared.getTopTracks()
                                    dismiss()
                                } catch {
                                    errorMessage = "Failed to connect to Apple Music"
                                }
                            } else {
                                errorMessage = "Apple Music access not authorized"
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            Text("Sign in with Apple Music")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
public struct DashboardView_Previews: PreviewProvider {
    public static var previews: some View {
        DashboardView()
    }
}
