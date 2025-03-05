import SwiftUI
import Charts

@available(iOS 17.0, *)
public struct StreamingStatsView: View {
    @State private var stats: StreamingStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        LoadingView()
                    } else if let error = errorMessage {
                        ErrorView(message: error)
                    } else if let stats = stats {
                        // Overview Card
                        StatsOverviewCard(stats: stats)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Top Artists Card
                        TopArtistsCard(artists: stats.topArtists)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Top Tracks Card
                        TopTracksCard(tracks: stats.topTracks)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Genre Distribution
                        GenreDistributionCard(genres: stats.weeklyStats.topGenres)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Listening History
                        ListeningHistoryCard(history: stats.listeningHistory)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        EmptyStateView()
                    }
                }
                .padding()
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLoading)
            }
            .navigationTitle("Streaming Stats")
            .background(Color(UIColor.systemBackground))
            .onAppear {
                loadStats()
            }
            .refreshable {
                await refreshStats()
            }
            .overlay {
                if isLoading {
                    Color(UIColor.systemBackground)
                        .opacity(0.8)
                        .ignoresSafeArea()
                    
                    ProgressView("Loading stats...")
                        .controlSize(.large)
                }
            }
        }
    }
    
    private func loadStats() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await AppleMusicService.shared.getStreamingStats()
                withAnimation {
                    stats = result
                    isLoading = false
                }
            } catch {
                print("Stats loading error: \(error)")
                withAnimation {
                    errorMessage = "Failed to load stats. Please check your connection and try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func refreshStats() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await AppleMusicService.shared.getStreamingStats()
            withAnimation {
                stats = result
                isLoading = false
            }
        } catch {
            print("Stats refresh error: \(error)")
            withAnimation {
                errorMessage = "Failed to refresh stats. Please try again."
                isLoading = false
            }
        }
    }
}

// MARK: - Loading View
@available(iOS 17.0, *)
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            
            Text("Loading your stats...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
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
                .foregroundStyle(.red.gradient)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Trigger refresh
                NotificationCenter.default.post(name: NSNotification.Name("RefreshStats"), object: nil)
            }) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.purple.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Empty State View
@available(iOS 17.0, *)
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.purple.gradient)
            
            Text("No Stats Available")
                .font(.title3.weight(.semibold))
            
            Text("Start listening to music to see your stats")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Stats Overview Card
@available(iOS 17.0, *)
private struct StatsOverviewCard: View {
    let stats: StreamingStats
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Overview")
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatBox(
                    title: "Listening Time",
                    value: "\(stats.totalListeningTime / 60)h",
                    icon: "clock.fill",
                    gradient: [.purple, .blue]
                )
                
                StatBox(
                    title: "Most Active",
                    value: stats.weeklyStats.mostActiveDay,
                    icon: "calendar",
                    gradient: [.orange, .red]
                )
            }
            
            HStack(spacing: 20) {
                StatBox(
                    title: "Total Artists",
                    value: "\(stats.weeklyStats.totalArtists)",
                    icon: "music.mic",
                    gradient: [.green, .blue]
                )
                
                StatBox(
                    title: "Total Tracks",
                    value: "\(stats.weeklyStats.totalTracks)",
                    icon: "music.note.list",
                    gradient: [.pink, .purple]
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Stat Box
@available(iOS 17.0, *)
private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

// MARK: - Top Artists Card
@available(iOS 17.0, *)
private struct TopArtistsCard: View {
    let artists: [ArtistStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Artists")
                .font(.title2.weight(.bold))
            
            ForEach(artists.prefix(5)) { artist in
                HStack {
                    Text(artist.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(artist.playCount) plays")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Top Tracks Card
@available(iOS 17.0, *)
private struct TopTracksCard: View {
    let tracks: [TrackStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Tracks")
                .font(.title2.weight(.bold))
            
            ForEach(tracks.prefix(5)) { trackStats in
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: trackStats.track.artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trackStats.track.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(trackStats.track.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("\(trackStats.playCount)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Genre Distribution Card
@available(iOS 17.0, *)
private struct GenreDistributionCard: View {
    let genres: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Genres")
                .font(.title2.weight(.bold))
            
            Chart {
                ForEach(Array(genres.enumerated()), id: \.0) { index, genre in
                    BarMark(
                        x: .value("Genre", genre),
                        y: .value("Count", Double(genres.count - index))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(value.as(String.self) ?? "", orientation: .vertical)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Listening History Card
@available(iOS 17.0, *)
private struct ListeningHistoryCard: View {
    let history: [ListeningSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Listening History")
                .font(.title2.weight(.bold))
            
            Chart {
                ForEach(history.prefix(7)) { session in
                    LineMark(
                        x: .value("Time", session.startTime),
                        y: .value("Duration", Double(session.duration) / 60.0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel("\(value.as(Double.self)?.formatted() ?? "")m")
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

@available(iOS 17.0, *)
public struct StreamingStatsView_Previews: PreviewProvider {
    public static var previews: some View {
        StreamingStatsView()
    }
}
