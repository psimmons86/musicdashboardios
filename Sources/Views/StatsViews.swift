import SwiftUI

@available(iOS 17.0, *)
public struct StatCard<Content: View>: View {
    let title: String
    let value: String
    let content: Content
    
    public init(title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }
    
    public var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.title2)
                        .bold()
                        .foregroundColor(AppTheme.accent)
                }
                
                content
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

@available(iOS 17.0, *)
public struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    public init(title: String, value: String, icon: String) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

@available(iOS 17.0, *)
public struct ChartCard: View {
    let title: String
    let data: [(String, Double)]
    let maxValue: Double
    
    public init(title: String, data: [(String, Double)], maxValue: Double? = nil) {
        self.title = title
        self.data = data
        self.maxValue = maxValue ?? (data.map { $0.1 }.max() ?? 0)
    }
    
    public var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data, id: \.0) { item in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accent)
                                .frame(height: CGFloat(item.1 / maxValue) * 100)
                            
                            Text(item.0)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
                }
                .frame(height: 120)
            }
            .padding()
        }
        .padding(.horizontal)
    }
}
