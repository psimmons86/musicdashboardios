import CloudKit
import Foundation

// MARK: - Schema Setup

class CloudKitSchemaSetup {
    let container: CKContainer
    let database: CKDatabase
    
    init() {
        container = CKContainer(identifier: "iCloud.com.musicdashboard.stats")
        database = container.privateCloudDatabase
    }
    
    func setupSchema() async throws {
        print("Setting up CloudKit schema...")
        
        // Create Track record type
        try await createTrackRecordType()
        print("✓ Created Track record type")
        
        // Create ListeningSession record type
        try await createListeningSessionRecordType()
        print("✓ Created ListeningSession record type")
        
        print("Schema setup complete!")
    }
    
    private func createTrackRecordType() async throws {
        let recordType = "Track"
        
        // Define fields
        let fields: [(String, CKRecordFieldType)] = [
            ("id", .string),
            ("title", .string),
            ("artist", .string),
            ("albumTitle", .string),
            ("artworkURL", .string),
            ("playCount", .int64),
            ("lastPlayed", .date)
        ]
        
        // Create sample record to establish schema
        let record = CKRecord(recordType: recordType)
        
        // Set sample values for each field
        for (field, type) in fields {
            switch type {
            case .string:
                record[field] = "sample"
            case .int64:
                record[field] = 0
            case .date:
                record[field] = Date()
            default:
                break
            }
        }
        
        // Save record to establish schema
        try await database.save(record)
        print("Created Track schema with fields: \(fields.map { $0.0 }.joined(separator: ", "))")
    }
    
    private func createListeningSessionRecordType() async throws {
        let recordType = "ListeningSession"
        
        // Define fields
        let fields: [(String, CKRecordFieldType)] = [
            ("startTime", .date),
            ("duration", .int64),
            ("trackIds", .string) // Will store as comma-separated string
        ]
        
        // Create sample record to establish schema
        let record = CKRecord(recordType: recordType)
        
        // Set sample values for each field
        for (field, type) in fields {
            switch type {
            case .string:
                record[field] = "sample"
            case .int64:
                record[field] = 0
            case .date:
                record[field] = Date()
            default:
                break
            }
        }
        
        // Save record to establish schema
        try await database.save(record)
        print("Created ListeningSession schema with fields: \(fields.map { $0.0 }.joined(separator: ", "))")
    }
}

// MARK: - Run Setup

@main
struct SchemaSetup {
    static func main() async throws {
        let setup = CloudKitSchemaSetup()
        try await setup.setupSchema()
    }
}
