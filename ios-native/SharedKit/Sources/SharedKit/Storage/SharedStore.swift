import Foundation

public final class SharedStore {
    private let appGroupID = "group.com.petprogress.app"
    private let fileName = "State.json"
    private let queue = DispatchQueue(label: "SharedStore.SerialQueue")

    public init() {}

    private func fileURL() throws -> URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return container.appendingPathComponent(fileName)
        }
        // Fallback for unit tests where app group may be unavailable
        return FileManager.default.temporaryDirectory.appendingPathComponent("PetProgress_\(fileName)")
    }

    public func loadState() throws -> AppState {
        try queue.sync {
            let url = try fileURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw NSError(domain: "SharedStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "State not found"])
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // Try decoding with current schema, fall back to migration if needed
            do {
                let state = try decoder.decode(AppState.self, from: data)
                return try migrateIfNeeded(state: state)
            } catch {
                // If decoding fails, try to recover with a more lenient approach
                throw NSError(domain: "SharedStore", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode state data",
                    NSUnderlyingErrorKey: error
                ])
            }
        }
    }

    private func migrateIfNeeded(state: AppState) throws -> AppState {
        var migratedState = state
        let currentVersion = 3

        // Only migrate if schema is older than current
        guard migratedState.schemaVersion < currentVersion else {
            return migratedState
        }

        // Migration from v1/v2 to v3
        if migratedState.schemaVersion < 3 {
            migratedState = migrateToV3(state: migratedState)
        }

        // Future migrations would go here
        // if migratedState.schemaVersion < 4 {
        //     migratedState = migrateToV4(state: migratedState)
        // }

        migratedState.schemaVersion = currentVersion

        // Save migrated state immediately to ensure persistence
        try saveState(migratedState)

        return migratedState
    }

    private func migrateToV3(state: AppState) -> AppState {
        var migrated = state

        // Initialize new fields introduced in v3
        migrated.series = migrated.series.isEmpty ? [] : migrated.series
        migrated.overrides = migrated.overrides.isEmpty ? [] : migrated.overrides
        migrated.completions = migrated.completions.isEmpty ? [:] : migrated.completions

        // Set defaults for new settings
        if migrated.graceMinutes <= 0 {
            migrated.graceMinutes = 60
        }

        // Ensure resetTime is valid
        if migrated.resetTime.hour == nil && migrated.resetTime.minute == nil {
            migrated.resetTime = DateComponents(hour: 0, minute: 0)
        }

        return migrated
    }

    public func saveState(_ state: AppState) throws {
        try queue.sync {
            let url = try fileURL()
            var st = state
            if st.schemaVersion < 3 { st.schemaVersion = 3 }
            let data = try JSONEncoder().encode(st)
            let tmp = url.appendingPathExtension("tmp")
            try data.write(to: tmp, options: .atomic)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }
}
