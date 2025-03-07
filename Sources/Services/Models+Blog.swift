import Foundation
import MusicKit
import SwiftUI

// Define a local AppTheme for use in this file
// This avoids the "No such module 'Views'" error
fileprivate enum AppTheme {
    static let accent = Color.blue
}

// Blog-related models extension
extension Models {
    
    public struct Article: Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let content: String
        public let author: String
        public let authorImageURL: String?
        public let coverImageURL: String?
        public let publishDate: Date
        public let readTime: Int
        public let category: ArticleCategory
        public let relatedTracks: [Services.Track]?
        public let relatedPlaylists: [Playlist]?
        
        public init(
            id: String,
            title: String,
            subtitle: String? = nil,
            content: String,
            author: String,
            authorImageURL: String? = nil,
            coverImageURL: String? = nil,
            publishDate: Date,
            readTime: Int,
            category: ArticleCategory,
            relatedTracks: [Services.Track]? = nil,
            relatedPlaylists: [Playlist]? = nil
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.content = content
            self.author = author
            self.authorImageURL = authorImageURL
            self.coverImageURL = coverImageURL
            self.publishDate = publishDate
            self.readTime = readTime
            self.category = category
            self.relatedTracks = relatedTracks
            self.relatedPlaylists = relatedPlaylists
        }
    }
    
    public enum ArticleCategory: String, CaseIterable {
        case news = "News"
        case review = "Review"
        case artists = "Artists"
        case industry = "Industry"
        case features = "Features"
    }
}

// Public typealias for backward compatibility
public typealias Article = Models.Article
public typealias ArticleCategory = Models.ArticleCategory

// Necessary track and playlist rows used in article views
public struct TrackRow: View {
    let track: Services.Track
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    public init(track: Services.Track, isSelected: Bool, onTap: (() -> Void)?) {
        self.track = track
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let artwork = track.artwork {
                AsyncImage(url: artwork.url(width: 40, height: 40)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.callout)
                    .foregroundColor(isSelected ? AppTheme.accent : .primary)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let onTap = onTap {
                Button(action: onTap) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

public struct PlaylistRow: View {
    let playlist: Models.Playlist
    
    public init(playlist: Models.Playlist) {
        self.playlist = playlist
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Simple playlist artwork placeholder
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(playlist.tracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
