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
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else {
                        // Service Connection Status
                        ServiceConnectionCard(
                            isConnected: isAuthorized,
                            onConnect: { showingAuthSheet = true }
                        )
                        .padding(.horizontal)
                        
                        if isAuthorized {
                            // Widgets Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                RecentlyPlayedWidget(tracks: recentlyPlayed)
                                TopTracksWidget(tracks: topTracks)
                                
                                MusicNewsWidget(
                                    newsArticles: newsArticles,
                                    availableGenres: availableGenres,
                                    selectedGenre: selectedNewsGenre,
                                    onGenreSelected: { genre in
                                        selectedNewsGenre = genre
                                        Task { await loadDashboard() }
                                    }
                                )
                                
                                QuickActionsWidget()
                            }
                            .padding(.vertical)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "music.mic")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Text("Connect to Apple Music to view your music stats")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                StyledButton(
                                    title: "Connect Apple Music",
                                    icon: "link",
                                    action: { showingAuthSheet = true }
                                )
                                .padding(.horizontal)
                            }
                            .padding()
                        }
                    }
                }
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
            .background(AppTheme.darkBackground)
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
        
        // Load Apple Music data first
        do {
            let (recent, top) = try await (
                AppleMusicService.shared.getRecentlyPlayed(),
                AppleMusicService.shared.getTopTracks()
            )
            recentlyPlayed = recent
            topTracks = top
            
            // Try to load news data, but don't let it block the dashboard
            Task {
                do {
                    let (genres, news) = try await (
                        NewsService.shared.getAvailableGenres(),
                        NewsService.shared.getMusicNews(genre: selectedNewsGenre)
                    )
                    availableGenres = genres
                    newsArticles = news
                } catch {
                    print("Failed to load news: \(error)")
                }
            }
            
            isLoading = false
        } catch {
            print("Dashboard load error: \(error)")
            errorMessage = "Failed to load music data. Please check your Apple Music connection."
            isLoading = false
        }
    }
}

@available(iOS 17.0, *)
private struct RecentlyPlayedWidget: View {
    let tracks: [Track]
    
    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently Played")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                if tracks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(tracks.prefix(3)) { track in
                        TrackRow(track: track, isSelected: false, onTap: nil)
                        if track.id != tracks.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

@available(iOS 17.0, *)
private struct TopTracksWidget: View {
    let tracks: [Track]
    
    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Tracks")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                if tracks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(tracks.prefix(3)) { track in
                        TrackRow(track: track, isSelected: false, onTap: nil)
                        if track.id != tracks.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

@available(iOS 17.0, *)
private struct MusicNewsWidget: View {
    let newsArticles: [NewsArticle]
    let availableGenres: [String]
    let selectedGenre: String?
    let onGenreSelected: (String?) -> Void
    
    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Music News")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Menu {
                        Button("All Genres") {
                            onGenreSelected(nil)
                        }
                        Divider()
                        ForEach(availableGenres, id: \.self) { genre in
                            Button(genre) {
                                onGenreSelected(genre)
                            }
                        }
                    } label: {
                        Label(selectedGenre ?? "All Genres", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accent)
                    }
                }
                
                if newsArticles.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(newsArticles.prefix(3)) { article in
                        NewsArticleRow(article: article)
                        if article.id != newsArticles.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

@available(iOS 17.0, *)
private struct QuickActionsWidget: View {
    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 12) {
                    NavigationLink(destination: PlaylistGeneratorView()) {
                        QuickActionCard(
                            title: "Generate",
                            systemImage: "wand.and.stars",
                            gradient: LinearGradient(
                                colors: [Color(hex: "4A90E2"), Color(hex: "1E62B0")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    
                    NavigationLink(destination: StreamingStatsView()) {
                        QuickActionCard(
                            title: "Stats",
                            systemImage: "chart.bar.fill",
                            gradient: LinearGradient(
                                colors: [Color(hex: "9B59B6"), Color(hex: "6C3483")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

@available(iOS 17.0, *)
private struct ServiceConnectionCard: View {
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        StyledCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "music.mic")
                            .font(.title2)
                        Text("Apple Music")
                            .font(.headline)
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    
                    Text(isConnected ? "Connected" : "Not connected")
                        .font(.subheadline)
                        .foregroundColor(isConnected ? Color.green : AppTheme.textSecondary)
                }
                
                Spacer()
                
                if !isConnected {
                    Button(action: onConnect) {
                        Text("Connect")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
        }
    }
}

@available(iOS 17.0, *)
private struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "music.mic")
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.accent)
                
                Text("Connect to Apple Music")
                    .font(.title2)
                    .bold()
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Sign in to access your music library, playlists, and listening history")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(AppTheme.error)
                        .padding()
                } else {
                    StyledButton(
                        title: "Sign in with Apple Music",
                        icon: "arrow.right.circle.fill",
                        action: {
                            isLoading = true
                            errorMessage = nil
                            Task {
                                let status = await MusicAuthorization.request()
                                if status == .authorized {
                                    // Test connection
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
                        }
                    )
                    .padding(.horizontal)
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
            .preferredColorScheme(.dark)
    }
}
