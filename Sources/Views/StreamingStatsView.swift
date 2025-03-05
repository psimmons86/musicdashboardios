import SwiftUI

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
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else if let stats = stats {
                        // Total Listening Time
                        StatCard(
                            title: "Total Listening Time",
                            value: "\(stats.totalListeningTime / 60)h"
                        ) {
                            StatRow(
                                title: "Weekly Average",
                                value: "\(stats.weeklyStats.totalListeningTime / 60)h",
                                icon: "clock.fill"
                            )
                            StatRow(
                                title: "Most Active Day",
                                value: stats.weeklyStats.mostActiveDay,
                                icon: "calendar"
                            )
                        }
                        
                        // Top Artists
                        StatCard(
                            title: "Top Artists",
                            value: "\(stats.topArtists.count)"
                        ) {
                            VStack(spacing: 8) {
                                ForEach(stats.topArtists.prefix(3)) { artist in
                                    StatRow(
                                        title: artist.name,
                                        value: "\(artist.playCount) plays",
                                        icon: "music.mic"
                                    )
                                }
                            }
                        }
                        
                        // Top Tracks
                        StatCard(
                            title: "Top Tracks",
                            value: "\(stats.topTracks.count)"
                        ) {
                            VStack(spacing: 8) {
                                ForEach(stats.topTracks.prefix(3)) { trackStats in
                                    StatRow(
                                        title: trackStats.track.title,
                                        value: "\(trackStats.playCount) plays",
                                        icon: "music.note"
                                    )
                                }
                            }
                        }
                        
                        // Genre Distribution
                        ChartCard(
                            title: "Top Genres",
                            data: stats.weeklyStats.topGenres.enumerated().map { ($0.element, Double(10 - $0.offset)) }
                        )
                        
                        // Daily Activity
                        ChartCard(
                            title: "Daily Activity",
                            data: stats.listeningHistory.prefix(7).map { session in
                                let weekday = session.startTime.formatted(.dateTime.weekday(.abbreviated))
                                let timestamp = session.startTime.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
                                return (
                                    "\(weekday)-\(timestamp)", // Unique ID combining weekday and hour
                                    Double(session.duration)
                                )
                            }
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Streaming Stats")
            .background(AppTheme.darkBackground)
            .onAppear {
                loadStats()
            }
            .refreshable {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                stats = try await AppleMusicService.shared.getStreamingStats()
                isLoading = false
            } catch {
                errorMessage = "Failed to load stats"
                isLoading = false
            }
        }
    }
}

@available(iOS 17.0, *)
public struct StreamingStatsView_Previews: PreviewProvider {
    public static var previews: some View {
        StreamingStatsView()
            .preferredColorScheme(.dark)
    }
}
