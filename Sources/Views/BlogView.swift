import SwiftUI

@available(iOS 17.0, *)
public struct BlogView: View {
    @State private var articles: [Article] = []
    @State private var selectedCategory: ArticleCategory?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                selectedCategory = nil
                            } label: {
                                Text("All")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == nil ? AppTheme.accent : AppTheme.surfaceBackground)
                                    .foregroundColor(selectedCategory == nil ? .white : AppTheme.textSecondary)
                                    .clipShape(Capsule())
                            }
                            
                            ForEach(ArticleCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? AppTheme.accent : AppTheme.surfaceBackground)
                                        .foregroundColor(selectedCategory == category ? .white : AppTheme.textSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.error)
                            .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredArticles) { article in
                                ArticleCard(article: article)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Blog")
            .background(AppTheme.darkBackground)
            .onAppear {
                loadArticles()
            }
            .refreshable {
                loadArticles()
            }
        }
    }
    
    private var filteredArticles: [Article] {
        guard let category = selectedCategory else { return articles }
        return articles.filter { $0.category == category }
    }
    
    private func loadArticles() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                articles = try await SocialService.shared.getArticles()
                isLoading = false
            } catch {
                errorMessage = "Failed to load articles"
                isLoading = false
            }
        }
    }
}

@available(iOS 17.0, *)
public struct ArticleCard: View {
    let article: Article
    
    public init(article: Article) {
        self.article = article
    }
    
    public var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 12) {
                if let coverImageURL = article.coverImageURL {
                    AsyncImage(url: URL(string: coverImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(AppTheme.surfaceBackground)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(article.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.surfaceBackground)
                    .foregroundColor(AppTheme.textSecondary)
                    .clipShape(Capsule())
                
                Text(article.title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(AppTheme.textPrimary)
                
                if let subtitle = article.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                HStack {
                    Text(article.author)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(article.readTime) min read")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                if let tracks = article.relatedTracks, !tracks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Tracks")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        ForEach(tracks.prefix(3)) { track in
                            TrackRow(track: track, isSelected: false, onTap: nil)
                        }
                    }
                }
                
                if let playlists = article.relatedPlaylists, !playlists.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Playlists")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        ForEach(playlists.prefix(2)) { playlist in
                            PlaylistRow(playlist: playlist)
                        }
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

@available(iOS 17.0, *)
public struct BlogView_Previews: PreviewProvider {
    public static var previews: some View {
        BlogView()
            .preferredColorScheme(.dark)
    }
}
