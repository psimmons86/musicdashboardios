import SwiftUI
import MusicKit
import CloudKit

// Import CloudKitService for play count tracking
@_exported import CloudKitService

struct NewsArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlToImage = article.urlToImage,
               let imageURL = URL(string: urlToImage) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 180)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = article.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

public struct QuickActionCard: View {
    let title: String
    let systemImage: String
    let gradient: LinearGradient
    
    public init(
        title: String,
        systemImage: String,
        gradient: LinearGradient
    ) {
        self.title = title
        self.systemImage = systemImage
        self.gradient = gradient
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.paddingMedium)
        .background(gradient)
        .clipShape(AppTheme.cardShape)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius / 2, y: AppTheme.shadowY / 2)
    }
}

public struct TrackCard: View {
    let track: Track
    let action: () -> Void
    @State private var isPlaying = false
    @State private var errorMessage: String?
    
    public init(track: Track, action: @escaping () -> Void) {
        self.track = track
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let artworkURL = track.artworkURLForSize(width: 60, height: 60) {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                    
                    Text(track.albumTitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button {
                    playTrack()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding()
            .background(AppTheme.surfaceBackground)
            .clipShape(AppTheme.cardShape)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius / 2, y: AppTheme.shadowY / 2)
        }
        .alert("Playback Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func playTrack() {
        Task {
            do {
                let request = MusicCatalogSearchRequest(term: "\(track.artist) \(track.title)", types: [Song.self])
                let response = try await request.response()
                
                if let song = response.songs.first {
                    if isPlaying {
                        try await MusicPlayer.shared.stop()
                        isPlaying = false
                    } else {
                        try await MusicPlayer.shared.queue = [song]
                        try await MusicPlayer.shared.play()
                        isPlaying = true
                        
                        // Track play count
                        try await CloudKitService.shared.incrementPlayCount(for: track)
                        print("[Player] Tracked play for: \(track.title)")
                    }
                } else {
                    errorMessage = "Track not found in Apple Music"
                }
            } catch {
                print("[Player] Error playing track: \(error)")
                errorMessage = "Failed to play track: \(error.localizedDescription)"
            }
        }
    }
}

public struct PlaylistRow: View {
    let playlist: Playlist
    let onTap: (() -> Void)?
    
    public init(playlist: Playlist, onTap: (() -> Void)? = nil) {
        self.playlist = playlist
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        if let description = playlist.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(playlist.tracks.count) tracks")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                HStack(spacing: AppTheme.paddingSmall) {
                    // Type badge
                    Text(playlist.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent.opacity(0.2))
                        .foregroundColor(AppTheme.accent)
                        .clipShape(Capsule())
                    
                    // Mood badge if available
                    if let mood = playlist.mood {
                        Text(mood.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.info.opacity(0.2))
                            .foregroundColor(AppTheme.info)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Creation date
                    Text(playlist.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(AppTheme.paddingMedium)
            .background(AppTheme.surfaceBackground)
            .clipShape(AppTheme.cardShape)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius / 2, y: AppTheme.shadowY / 2)
        }
    }
}

public struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: (() -> Void)?
    
    public init(
        text: Binding<String>,
        placeholder: String,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
