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
            var state = try JSONDecoder().decode(AppState.self, from: data)

            // Migration to schema v3
            if state.schemaVersion < 3 {
                state.series = []
                state.overrides = []
                state.completions = [:]
                state.graceMinutes = 60
                state.resetTime = DateComponents(hour: 0, minute: 0)
                state.schemaVersion = 3
            }

            return state
        }
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