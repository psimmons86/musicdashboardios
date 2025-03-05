import CloudKit
import Foundation
import AppKit

class SchemaSetup: NSObject, NSApplicationDelegate {
    let container: CKContainer
    let database: CKDatabase
    
    override init() {
        container = CKContainer(identifier: "iCloud.com.musicdashboard.stats")
        database = container.privateCloudDatabase
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[CloudKit] Starting setup script...")
        checkContainerAccess()
    }
    
    func checkContainerAccess() {
        print("[CloudKit] Checking container access...")
        container.accountStatus { (accountStatus, error) in
            if let error = error {
                print("[CloudKit] Error checking account status: \(error)")
                NSApplication.shared.terminate(nil)
                return
            }
            
            guard accountStatus == .available else {
                print("[CloudKit] iCloud account not available. Status: \(accountStatus)")
                NSApplication.shared.terminate(nil)
                return
            }
            
            print("[CloudKit] ✓ Container access verified")
            self.createTrackRecord()
        }
    }
    
    func createTrackRecord() {
        print("[CloudKit] Creating Track record type...")
        let trackRecord = CKRecord(recordType: "Track")
        trackRecord["id"] = "sample-id" as CKRecordValue
        trackRecord["title"] = "Sample Title" as CKRecordValue
        trackRecord["artist"] = "Sample Artist" as CKRecordValue
        trackRecord["albumTitle"] = "Sample Album" as CKRecordValue
        trackRecord["artworkURL"] = "https://example.com/artwork.jpg" as CKRecordValue
        trackRecord["playCount"] = 0 as CKRecordValue
        trackRecord["lastPlayed"] = Date() as CKRecordValue
        
        print("[CloudKit] Saving Track record...")
        database.save(trackRecord) { (record, error) in
            if let error = error {
                print("[CloudKit] Error saving Track record: \(error)")
                if let cloudError = error as? CKError {
                    print("[CloudKit] CloudKit error code: \(cloudError.errorCode)")
                    print("[CloudKit] Error description: \(cloudError.localizedDescription)")
                    for (key, value) in cloudError.errorUserInfo {
                        print("[CloudKit] Error info - \(key): \(value)")
                    }
                }
                NSApplication.shared.terminate(nil)
                return
            }
            
            print("[CloudKit] ✓ Created Track record type")
            self.createListeningSessionRecord()
        }
    }
    
    func createListeningSessionRecord() {
        print("[CloudKit] Creating ListeningSession record type...")
        let sessionRecord = CKRecord(recordType: "ListeningSession")
        sessionRecord["startTime"] = Date() as CKRecordValue
        sessionRecord["duration"] = 180 as CKRecordValue
        sessionRecord["trackIds"] = "sample-id-1,sample-id-2" as CKRecordValue
        
        print("[CloudKit] Saving ListeningSession record...")
        database.save(sessionRecord) { (record, error) in
            if let error = error {
                print("[CloudKit] Error saving ListeningSession record: \(error)")
                if let cloudError = error as? CKError {
                    print("[CloudKit] CloudKit error code: \(cloudError.errorCode)")
                    print("[CloudKit] Error description: \(cloudError.localizedDescription)")
                    for (key, value) in cloudError.errorUserInfo {
                        print("[CloudKit] Error info - \(key): \(value)")
                    }
                }
                NSApplication.shared.terminate(nil)
                return
            }
            
            print("[CloudKit] ✓ Created ListeningSession record type")
            print("[CloudKit] Schema setup complete!")
            NSApplication.shared.terminate(nil)
        }
    }
}

// Create and run application
let app = NSApplication.shared
let setup = SchemaSetup()
app.delegate = setup
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
