import SwiftUI

@available(iOS 17.0, *)
public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            PlaylistGeneratorView()
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }
            
            StreamingStatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
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
    }
}

@available(iOS 17.0, *)
public struct ContentView_Previews: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }
}
