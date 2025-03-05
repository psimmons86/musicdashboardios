import SwiftUI
import MusicKit

@main
struct MusicDashboardApp: App {
    @State private var isAuthorized = false
    
    init() {
        // Configure appearance
        UITabBar.appearance().backgroundColor = UIColor(AppTheme.surfaceBackground)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textPrimary)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textPrimary)
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
                    .preferredColorScheme(.dark)
                    .task {
                        await checkAuthorization()
                    }
            } else {
                Text("This app requires iOS 17.0 or later")
                    .foregroundColor(.white)
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    private func checkAuthorization() async {
        // Request authorization
        let status = await MusicAuthorization.request()
        if status == MusicAuthorization.Status.authorized {
            isAuthorized = true
        }
    }
}
