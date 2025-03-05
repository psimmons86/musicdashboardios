import SwiftUI

public struct PlaylistPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PlaylistPreferencesViewModel()
    @State private var notificationsEnabled = true
    @State private var notificationTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Genres") {
                    ForEach(viewModel.preferences.preferredGenres, id: \.self) { genre in
                        Text(genre)
                    }
                }
                
                Section("Moods") {
                    ForEach(viewModel.preferences.preferredMoods, id: \.self) { mood in
                        Text(mood.rawValue.capitalized)
                    }
                }
                
                Section("Tempo") {
                    HStack {
                        Text("\(Int(viewModel.preferences.tempoRange.lowerBound)) BPM")
                        Spacer()
                        Text("\(Int(viewModel.preferences.tempoRange.upperBound)) BPM")
                    }
                }
                
                Section("Options") {
                    Toggle("Include High Energy Songs", isOn: $viewModel.minimumEnergySongs)
                        .onChange(of: viewModel.minimumEnergySongs) { _ in
                            viewModel.updatePreferences()
                        }
                    Stepper("Maximum Length: \(viewModel.maximumPlaylistLength)", 
                           value: $viewModel.maximumPlaylistLength,
                           in: 10...50)
                        .onChange(of: viewModel.maximumPlaylistLength) { _ in
                            viewModel.updatePreferences()
                        }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    if notificationsEnabled {
                        DatePicker("Update Time", 
                                 selection: $notificationTime,
                                 displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Playlist Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.updatePreferences()
                        if notificationsEnabled {
                            NotificationService.shared.scheduleRecommendationNotification(time: notificationTime)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

public class PlaylistPreferencesViewModel: ObservableObject {
    @Published private(set) var preferences: PlaylistPreferences
    @Published var minimumEnergySongs: Bool
    @Published var maximumPlaylistLength: Int
    
    public init() {
        let initialPreferences = PlaylistPreferences(
            preferredGenres: ["Rock", "Pop", "Jazz"],
            preferredMoods: [.energetic, .happy],
            tempoRange: 80...160,
            excludedArtists: [],
            minimumEnergySongs: true,
            maximumPlaylistLength: 20
        )
        self.preferences = initialPreferences
        self.minimumEnergySongs = initialPreferences.minimumEnergySongs
        self.maximumPlaylistLength = initialPreferences.maximumPlaylistLength
    }
    
    func updatePreferences() {
        preferences.minimumEnergySongs = minimumEnergySongs
        preferences.maximumPlaylistLength = maximumPlaylistLength
    }
}

public struct PlaylistPreferencesView_Previews: PreviewProvider {
    public static var previews: some View {
        PlaylistPreferencesView()
    }
}
