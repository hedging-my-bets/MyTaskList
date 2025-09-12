import Foundation

// Mirror types so Widget can link without importing app target
public struct TaskItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var scheduledAt: DateComponents
    public var dayKey: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var snoozedUntil: Date?
}

public struct PetState: Codable, Hashable {
    public var stageIndex: Int
    public var stageXP: Int
    public var lastCloseoutDayKey: String
}

public struct AppState: Codable {
    public var schemaVersion: Int
    public var dayKey: String
    public var tasks: [TaskItem]
    public var pet: PetState
    public var series: [TaskSeries]
    public var overrides: [TaskInstanceOverride]
    public var completions: [String: Set<UUID>] // dayKey -> completed instance ids
    public var rolloverEnabled: Bool
    public var graceMinutes: Int?
    public var resetTime: DateComponents?
}

public struct Stage: Codable, Equatable {
    public let i: Int
    public let name: String
    public let threshold: Int
    public let asset: String
}

public struct StageCfg: Codable, Equatable {
    public let stages: [Stage]

    public static func defaultConfig() -> StageCfg {
        let thresholds = [10,20,30,40,50,60,75,90,110,135,165,200,240,285,335,390,450,515,585,0]
        let names = ["Tadpole","Minnow","Frog","Hermit Crab","Starfish","Jellyfish","Squid","Seahorse","Dolphin","Shark","Otter","Fox","Lynx","Wolf","Bear","Bison","Elephant","Rhino","Lion","Floating God"]
        let assets = ["pet_tadpole","pet_minnow","pet_frog","pet_hermit","pet_starfish","pet_jellyfish","pet_squid","pet_seahorse","pet_dolphin","pet_shark","pet_otter","pet_fox","pet_lynx","pet_wolf","pet_bear","pet_bison","pet_elephant","pet_rhino","pet_lion","pet_god"]
        let stages = (0..<20).map { Stage(i: $0, name: names[$0], threshold: thresholds[$0], asset: assets[$0]) }
        return StageCfg(stages: stages)
    }
}

public final class SharedStore {
    private let appGroupID = "group.com.petprogress.app"
    private let fileName = "State.json"
    private let queue = DispatchQueue(label: "SharedStore.SerialQueue")

    private func fileURL() throws -> URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return container.appendingPathComponent(fileName)
        }
        // Fallback for unit tests where app group may be unavailable
        return FileManager.default.temporaryDirectory.appendingPathComponent("PetProgress_" + fileName)
    }

    public init() {}

    public func loadState() throws -> AppState {
        try queue.sync {
            let url = try fileURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw NSError(domain: "SharedStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "State not found"]) }
            let data = try Data(contentsOf: url)
            var state = try JSONDecoder().decode(AppState.self, from: data)
            // Migration to schema v2
            if state.schemaVersion < 2 {
                state.series = []
                state.overrides = []
                state.completions = [:]
                state.graceMinutes = 60
                state.resetTime = nil
                state.schemaVersion = 2
            }
            return state
        }
    }

    public func saveState(_ state: AppState) throws {
        try queue.sync {
            let url = try fileURL()
            var st = state
            if st.schemaVersion < 2 { st.schemaVersion = 2 }
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

public enum PetEngine {
    public static func threshold(for stageIndex: Int, cfg: StageCfg) -> Int {
        cfg.stages[safe: stageIndex]?.threshold ?? 0
    }

    public static func onCheck(onTime: Bool, pet: inout PetState, cfg: StageCfg) {
        pet.stageXP += onTime ? 2 : 1
        evolveIfNeeded(&pet, cfg: cfg)
    }

    public static func onMiss(pet: inout PetState, cfg: StageCfg) {
        pet.stageXP -= 2
        deEvolveIfNeeded(&pet, cfg: cfg)
    }

    public static func onDailyCloseout(rate: Double, pet: inout PetState, cfg: StageCfg) {
        if rate >= 0.8 {
            pet.stageXP += 3
            evolveIfNeeded(&pet, cfg: cfg)
        } else if rate < 0.4 {
            pet.stageXP -= 3
            deEvolveIfNeeded(&pet, cfg: cfg)
        }
    }

    public static func evolveIfNeeded(_ pet: inout PetState, cfg: StageCfg) {
        guard pet.stageIndex < cfg.stages.count - 1 else { return }
        let thresholdValue = threshold(for: pet.stageIndex, cfg: cfg)
        guard thresholdValue > 0 else { return }
        if pet.stageXP >= thresholdValue {
            pet.stageIndex = min(pet.stageIndex + 1, cfg.stages.count - 1)
            pet.stageXP = 0
        }
    }

    public static func deEvolveIfNeeded(_ pet: inout PetState, cfg: StageCfg) {
        if pet.stageXP < 0 {
            if pet.stageIndex > 0 {
                pet.stageIndex -= 1
                let newThreshold = max(0, threshold(for: pet.stageIndex, cfg: cfg))
                pet.stageXP = max(0, newThreshold - 1)
            } else {
                pet.stageXP = 0
            }
        }
    }
}

public func dayKey(for date: Date, in tz: TimeZone = .current) -> String {
    var cal = Calendar.current
    cal.timeZone = tz
    let comps = cal.dateComponents([.year, .month, .day], from: date)
    let y = comps.year ?? 0
    let m = comps.month ?? 0
    let d = comps.day ?? 0
    return String(format: "%04d-%02d-%02d", y, m, d)
}

public func isOnTime(task: TaskItem, now: Date, graceMinutes: Int = 60) -> Bool {
    let cal = Calendar.current
    let due = cal.date(bySettingHour: task.scheduledAt.hour ?? 0, minute: task.scheduledAt.minute ?? 0, second: 0, of: now) ?? now
    let windowStart = due.addingTimeInterval(TimeInterval(-graceMinutes * 60))
    let windowEnd = due.addingTimeInterval(TimeInterval(graceMinutes * 60))
    return now >= windowStart && now <= windowEnd
}

public func nextUncompletedTask(for tasks: [TaskItem], dayKey: String) -> TaskItem? {
    tasks.filter { $0.dayKey == dayKey && !$0.isCompleted }
        .sorted { (l, r) in
            (l.scheduledAt.hour ?? 0, l.scheduledAt.minute ?? 0) < (r.scheduledAt.hour ?? 0, r.scheduledAt.minute ?? 0)
        }
        .first
}

extension Array {
    subscript(safe index: Int) -> Element? {
        (0..<count).contains(index) ? self[index] : nil
    }
}

