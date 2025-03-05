import SwiftUI

public enum AppTheme {
    // Modern color palette
    public static let darkBackground = Color(hex: "1A1B1E")
    public static let surfaceBackground = Color(hex: "26282B")
    public static let accent = Color(hex: "60A5FA") // Modern blue
    public static let error = Color(hex: "EF4444") // Softer red
    
    // Secondary accents
    public static let success = Color(hex: "34D399") // Soft green
    public static let warning = Color(hex: "FBBF24") // Soft yellow
    public static let info = Color(hex: "818CF8") // Soft purple
    
    // Text colors
    public static let textPrimary = Color(hex: "F3F4F6")
    public static let textSecondary = Color(hex: "9CA3AF")
    
    // Refined shadows
    public static let shadowColor = Color.black.opacity(0.15)
    public static let shadowRadius: CGFloat = 12
    public static let shadowY: CGFloat = 6
    
    // Modern shapes
    public static let cardShape = RoundedRectangle(cornerRadius: 16)
    public static let buttonShape = RoundedRectangle(cornerRadius: 12)
    
    // Spacing
    public static let spacing: CGFloat = 16
    public static let paddingSmall: CGFloat = 8
    public static let paddingMedium: CGFloat = 16
    public static let paddingLarge: CGFloat = 24
    
    // Animation
    public static let defaultAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Styled Components
public struct StyledButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    public init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.paddingSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding(.horizontal, AppTheme.paddingMedium)
            .padding(.vertical, AppTheme.paddingSmall)
            .frame(maxWidth: style == .block ? .infinity : nil)
            .background(style.backgroundColor)
            .foregroundColor(style.textColor)
            .clipShape(AppTheme.buttonShape)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius / 2, y: AppTheme.shadowY / 2)
        }
    }
    
    public enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case block
        
        var backgroundColor: Color {
            switch self {
            case .primary, .block: return AppTheme.accent
            case .secondary: return AppTheme.surfaceBackground
            case .destructive: return AppTheme.error
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive, .block: return .white
            case .secondary: return AppTheme.textPrimary
            }
        }
    }
}

public struct StyledCard<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(AppTheme.paddingMedium)
            .background(AppTheme.surfaceBackground)
            .clipShape(AppTheme.cardShape)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, y: AppTheme.shadowY)
    }
}

public struct TrackRow: View {
    let track: Track
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    public init(track: Track, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.track = track
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: AppTheme.paddingMedium) {
                if let artworkURL = track.artworkURLForSize(width: 60, height: 60) {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding(.vertical, AppTheme.paddingSmall)
            .contentShape(Rectangle())
        }
    }
}
