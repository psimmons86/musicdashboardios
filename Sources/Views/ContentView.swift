import SwiftUI
import Services
import MusicViews
import MusicKit
import NewsViews

// Helper components for Dashboard
fileprivate struct LoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .tint(AppTheme.mediumPurple)
            Text("Loading...")
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

fileprivate struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.error)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(AppTheme.error)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppTheme.background)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

fileprivate struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    let content: () -> Content
    
    init(gradient: LinearGradient = AppTheme.primaryGradient, @ViewBuilder content: @escaping () -> Content) {
        self.gradient = gradient
        self.content = content
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
            
            VStack(alignment: .leading) {
                content()
            }
            .padding(16)
        }
    }
}

fileprivate struct ServiceConnectionCard: View {
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(isConnected ? "Apple Music Connected" : "Connect Apple Music")
                    .font(.headline)
                    .foregroundColor(AppTheme.textOnDark)
                
                Text(isConnected ? "Streaming data is available" : "Connect to access your music data")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textOnDark.opacity(0.8))
            }
            
            Spacer()
            
            if !isConnected {
                Button(action: onConnect) {
                    Text("Connect")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(AppTheme.mintGreen)
                        .foregroundColor(AppTheme.deepPurple)
                        .cornerRadius(20)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.mintGreen)
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
                .foregroundColor(AppTheme.mediumPurple)
            
            Text("Connect to Apple Music")
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Connect your Apple Music account to see your recent plays, favorites, and personalized playlists.")
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textSecondary)
            
            Button(action: onConnect) {
                Text("Connect Now")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppTheme.deepPurple, AppTheme.mediumPurple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(AppTheme.textOnDark)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.surfaceBackground)
        .cornerRadius(20)
    }
}

fileprivate struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Apple Music Authorization")
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)
            
            Text("This will open Apple Music to request permission to access your library and listening data.")
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textSecondary)
            
            Button("Request Permission") {
                requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepPurple)
            .controlSize(.large)
            
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .foregroundColor(AppTheme.mediumPurple)
            .padding(.top)
        }
        .padding(30)
        .background(AppTheme.surfaceBackground)
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

// Dashboard View with real data
@available(iOS 16.0, *)
struct DashboardView: View {
    // State variables
    @State private var isAuthorized = false
    @State private var showingAuthSheet = false
    
    // News state
    @State private var newsArticles: [NewsArticle] = []
    @State private var isLoadingNews = false
    @State private var newsError: String? = nil
    @State private var selectedNewsGenre: String? = nil
    @State private var availableGenres: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Connection Card
                    connectionCard
                    
                    // Content based on authorization
                    if isAuthorized {
                        authorizedContent
                    } else {
                        connectPrompt
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                checkAuthorization()
                Task {
                    await loadNewsData()
                }
            }
            .refreshable {
                checkAuthorization()
                await loadNewsData()
            }
            .background(AppTheme.background)
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthSheet()
        }
        .tint(AppTheme.accent) // Sets the accent color for the navigation bar
    }
    
    // Connection Card
    private var connectionCard: some View {
        GradientCard(gradient: AppTheme.primaryGradient) {
            ServiceConnectionCard(
                isConnected: isAuthorized,
                onConnect: { showingAuthSheet = true }
            )
        }
    }
    
    // Content when authorized
    private var authorizedContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Tracks Section
            topTracksSection
            
            // News Section
            newsSection
        }
    }
    
    // Top Tracks Section
    private var topTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Tracks")
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)
            
            // Sample tracks for now
            ForEach(1...3, id: \.self) { index in
                HStack {
                    Text("Track \(index)")
                        .font(.body)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text("Artist \(index)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(AppTheme.surfaceBackground)
        .cornerRadius(12)
    }
    
    // News Section with real data
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Music News")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if isLoadingNews {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(AppTheme.mediumPurple)
                } else {
                    Button(action: {
                        Task {
                            await loadNewsData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppTheme.mediumPurple)
                    }
                }
            }
            
            // Genre selector (simplified)
            if !availableGenres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: { 
                            selectedNewsGenre = nil
                            Task {
                                await loadNewsData()
                            }
                        }) {
                            Text("All")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedNewsGenre == nil ? AppTheme.mediumPurple : Color.gray.opacity(0.2))
                                .foregroundColor(selectedNewsGenre == nil ? .white : AppTheme.textPrimary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(availableGenres.prefix(5), id: \.self) { genre in
                            Button(action: { 
                                selectedNewsGenre = genre
                                Task {
                                    await loadNewsData()
                                }
                            }) {
                                Text(genre)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedNewsGenre == genre ? AppTheme.mediumPurple : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedNewsGenre == genre ? .white : AppTheme.textPrimary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            if let error = newsError {
                Text("Error loading news: \(error)")
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding()
            } else if newsArticles.isEmpty && !isLoadingNews {
                Text("No news articles available")
                    .foregroundColor(AppTheme.textSecondary)
                    .padding()
            } else {
                // Real news articles
                ForEach(newsArticles.prefix(3)) { article in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(article.description)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(2)
                        
                        HStack {
                            Text(article.source)
                                .font(.caption)
                                .foregroundColor(AppTheme.mediumPurple)
                            
                            Spacer()
                            
                            Text(article.publishedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppTheme.surfaceBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppTheme.surfaceBackground.opacity(0.5))
        .cornerRadius(12)
    }
    
    // Load news data from the service
    private func loadNewsData() async {
        isLoadingNews = true
        newsError = nil
        
        do {
            // Load genres
            availableGenres = try await NewsService.shared.getAvailableGenres()
            
            // Load news articles
            let articles = try await NewsService.shared.getMusicNews(
                genre: selectedNewsGenre,
                searchTerm: nil
            )
            
            newsArticles = articles
        } catch {
            print("Error loading news: \(error)")
            newsError = error.localizedDescription
        }
        
        isLoadingNews = false
    }
    
    // Connect Prompt
    private var connectPrompt: some View {
        ConnectPromptView(onConnect: { showingAuthSheet = true })
    }
    
    // Check authorization
    private func checkAuthorization() {
        isAuthorized = MusicAuthorization.currentStatus == .authorized
    }
}

@available(iOS 17.0, *)
public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        TabView {
            // Use our functional Dashboard view
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            PlaylistGeneratorView(generatedPlaylist: .constant(nil))
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }
            
            MusicViews.MusicView()
                .tabItem {
                    Label("Music", systemImage: "music.note")
                }
            
            BlogView()
                .tabItem {
                    Label("Blog", systemImage: "newspaper.fill")
                }
            
            SocialFeedView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
        }
        .accentColor(AppTheme.accent) // Sets the accent color for the tab bar
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Set the selected item color
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(AppTheme.textSecondary)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.textSecondary)]
            itemAppearance.selected.iconColor = UIColor(AppTheme.accent)
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.accent)]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

@available(iOS 17.0, *)
public struct ContentView_Previews: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }
}
