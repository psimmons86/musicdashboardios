import SwiftUI

@available(iOS 17.0, *)
public struct SocialViews: View {
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            SocialFeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
                .tag(0)
            
            UserProfileView(userId: "user1")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
        }
    }
}

@available(iOS 17.0, *)
public struct SocialViews_Previews: PreviewProvider {
    public static var previews: some View {
        SocialViews()
            .preferredColorScheme(.dark)
    }
}
