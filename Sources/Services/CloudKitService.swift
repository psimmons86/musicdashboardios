import Foundation
import CloudKit

public class CloudKitService {
    public static let shared = CloudKitService()
    private let container = CKContainer.default()
    private let database: CKDatabase
    
    private init() {
        self.database = container.privateCloudDatabase
        print("[CloudKit] Service initialized")
    }
    
    // MARK: - Play Count Tracking
    
    public func incrementPlayCount(for track: Track) async throws {
        let recordID = CKRecord.ID(recordName: "track-\(track.id)")
        
        do {
            print("[CloudKit] Incrementing play count for track: \(track.title)")
            
            // Try to fetch existing record
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
                let currentCount = record["playCount"] as? Int ?? 0
                record["playCount"] = currentCount + 1
                record["lastPlayed"] = Date()
                
                print("[CloudKit] Updating play count to \(currentCount + 1)")
            } catch {
                // Create new record if it doesn't exist
                record = CKRecord(recordType: "Track", recordID: recordID)
                record["id"] = track.id
                record["title"] = track.title
                record["artist"] = track.artist
                record["albumTitle"] = track.albumTitle
                record["artworkURL"] = track.artworkURL
                record["playCount"] = 1
                record["lastPlayed"] = Date()
                
                print("[CloudKit] Creating new track record with play count 1")
            }
            
            try await database.save(record)
            print("[CloudKit] Successfully saved record")
        } catch {
            print("[CloudKit] Error tracking play count: \(error)")
            throw error
        }
    }
    
    public func getPlayCount(for track: Track) async throws -> Int {
        let recordID = CKRecord.ID(recordName: "track-\(track.id)")
        
        do {
            print("[CloudKit] Fetching play count for track: \(track.title)")
            let record = try await database.record(for: recordID)
            let playCount = record["playCount"] as? Int ?? 0
            print("[CloudKit] Found play count: \(playCount)")
            return playCount
        } catch {
            print("[CloudKit] No existing record found, returning 0")
            return 0
        }
    }
    
    public func getAllPlayCounts() async throws -> [String: Int] {
        print("[CloudKit] Fetching all play counts")
        
        let query = CKQuery(recordType: "Track", predicate: NSPredicate(value: true))
        let records = try await database.records(matching: query)
        
        var playCounts: [String: Int] = [:]
        for record in records.matchResults.compactMap({ try? $0.1.get() }) {
            if let id = record["id"] as? String,
               let count = record["playCount"] as? Int {
                playCounts[id] = count
            }
        }
        
        print("[CloudKit] Found \(playCounts.count) play count records")
        return playCounts
    }
    
    // MARK: - Listening History
    
    public func saveListeningSession(_ session: ListeningSession) async throws {
        let recordID = CKRecord.ID(recordName: session.id)
        let record = CKRecord(recordType: "ListeningSession", recordID: recordID)
        
        print("[CloudKit] Saving listening session: \(session.id)")
        
        record["startTime"] = session.startTime
        record["duration"] = session.duration
        record["trackIds"] = session.tracks.map { $0.id }
        
        try await database.save(record)
        print("[CloudKit] Successfully saved listening session")
    }
    
    public func getListeningSessions(since date: Date) async throws -> [ListeningSession] {
        print("[CloudKit] Fetching listening sessions since: \(date)")
        
        let predicate = NSPredicate(format: "startTime >= %@", date as NSDate)
        let query = CKQuery(recordType: "ListeningSession", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        let records = try await database.records(matching: query)
        var sessions: [ListeningSession] = []
        
        for record in records.matchResults.compactMap({ try? $0.1.get() }) {
            if let startTime = record["startTime"] as? Date,
               let duration = record["duration"] as? Int,
               let trackIds = record["trackIds"] as? [String] {
                // Fetch tracks for each session
                let tracks = try await fetchTracks(ids: trackIds)
                let session = ListeningSession(
                    id: record.recordID.recordName,
                    startTime: startTime,
                    duration: duration,
                    tracks: tracks
                )
                sessions.append(session)
            }
        }
        
        print("[CloudKit] Found \(sessions.count) listening sessions")
        return sessions
    }
    
    private func fetchTracks(ids: [String]) async throws -> [Track] {
        let records = try await database.records(for: ids.map { CKRecord.ID(recordName: "track-\($0)") })
        return records.compactMap { recordResult in
            guard let record = try? recordResult.get() else { return nil }
            return Track(
                id: record["id"] as? String ?? "",
                title: record["title"] as? String ?? "",
                artist: record["artist"] as? String ?? "",
                albumTitle: record["albumTitle"] as? String ?? "",
                artworkURL: record["artworkURL"] as? String ?? ""
            )
        }
    }
}
