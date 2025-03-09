import SwiftUI
import Services

@available(iOS 16.0, macOS 12.0, *)
public struct PlaylistPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFrequency: Models.UpdateFrequency = .weekly
    @State private var selectedMood: Models.PlaylistMood = .chill
    @State private var selectedGenre: String = "Mixed"
    @State private var isSaving = false
    
    private let availableGenres = ["Mixed", "Pop", "Rock", "Hip-Hop", "Electronic", "Jazz", "Classical"]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Frequency")) {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach([Models.UpdateFrequency.daily, .weekly, .monthly], id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Mood")) {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach([Models.PlaylistMood.energetic, .chill, .focus, .workout, .party], id: \.self) { mood in
                            Text(mood.rawValue.capitalized).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Primary Genre")) {
                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(availableGenres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Playlist Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadSavedPreferences()
            }
        }
    }
    
    private func savePreferences() {
        isSaving = true
        
        Task {
            do {
                // Save preferences to UserDefaults
                let defaults = UserDefaults.standard
                defaults.set(selectedFrequency.rawValue, forKey: "playlistFrequency")
                defaults.set(selectedMood.rawValue, forKey: "playlistMood")
                defaults.set(selectedGenre, forKey: "playlistGenre")
                
                // Notify the system that preferences have changed
                NotificationCenter.default.post(name: Notification.Name("PlaylistPreferencesChanged"), object: nil)
                
                // Simulate a short delay for better UX
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                dismiss()
            } catch {
                print("Failed to save preferences: \(error)")
            }
            isSaving = false
        }
    }
    
    // Load saved preferences when the view appears
    private func loadSavedPreferences() {
        let defaults = UserDefaults.standard
        
        // Load frequency
        if let frequencyString = defaults.string(forKey: "playlistFrequency"),
           let frequency = Models.UpdateFrequency(rawValue: frequencyString) {
            selectedFrequency = frequency
        }
        
        // Load mood
        if let moodString = defaults.string(forKey: "playlistMood"),
           let mood = Models.PlaylistMood(rawValue: moodString) {
            selectedMood = mood
        }
        
        // Load genre
        if let genre = defaults.string(forKey: "playlistGenre") {
            selectedGenre = genre
        }
    }
}
