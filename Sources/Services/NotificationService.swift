import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func schedulePlaylistNotification(for playlist: Playlist) {
        guard let schedule = playlist.schedule else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Weekly Playlist"
        content.body = "Your \(playlist.name) has been updated with fresh tracks!"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: schedule.time)
        if schedule.frequency == .weekly {
            dateComponents.weekday = schedule.dayOfWeek
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "playlist-\(playlist.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelPlaylistNotifications(for playlistId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["playlist-\(playlistId)"])
    }
    
    func scheduleNewReleaseNotification(title: String, artist: String, releaseDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "New Release"
        content.body = "\"\(title)\" by \(artist) is now available!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: releaseDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "release-\(title)-\(artist)".replacingOccurrences(of: " ", with: "-"),
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling release notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleRecommendationNotification(time: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Music Recommendations"
        content.body = "Check out today's personalized music picks!"
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-recommendations",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling recommendation notification: \(error.localizedDescription)")
            }
        }
    }
}
