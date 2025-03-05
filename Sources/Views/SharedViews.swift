import SwiftUI

@available(iOS 17.0, *)
public struct TrackRow: View {
    let track: Track
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    public init(track: Track, isSelected: Bool, onTap: (() -> Void)?) {
        self.track = track
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: track.artworkURLForSize(width: 60, height: 60)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(AppTheme.surfaceBackground)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: AppTheme.shadowColor, radius: 4, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
private struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
            .padding(.horizontal, AppTheme.paddingSmall)
            .padding(.vertical, 4)
            .background(AppTheme.surfaceBackground.opacity(0.6))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

@available(iOS 17.0, *)
public struct PlaylistRow: View {
    let playlist: Playlist
    
    public init(playlist: Playlist) {
        self.playlist = playlist
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(playlist.name)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if let description = playlist.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: AppTheme.paddingSmall) {
                if let genre = playlist.genre {
                    TagView(text: genre)
                }
                
                if let mood = playlist.mood {
                    TagView(text: mood.rawValue.capitalized)
                }
                
                if let tempo = playlist.tempo {
                    TagView(text: "\(tempo) BPM")
                }
            }
        }
    }
}

@available(iOS 17.0, *)
public struct StyledCard<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(AppTheme.surfaceBackground)
            .clipShape(AppTheme.cardShape)
            .shadow(
                color: AppTheme.shadowColor,
                radius: AppTheme.shadowRadius,
                x: 0,
                y: AppTheme.shadowY
            )
    }
}

@available(iOS 17.0, *)
public struct StyledButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    public init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.paddingSmall) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.paddingMedium)
            .padding(.horizontal, AppTheme.paddingLarge)
            .background(
                AppTheme.accent
                    .opacity(0.9)
            )
            .clipShape(AppTheme.buttonShape)
            .shadow(
                color: AppTheme.accent.opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

@available(iOS 17.0, *)
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.defaultAnimation, value: configuration.isPressed)
    }
}
