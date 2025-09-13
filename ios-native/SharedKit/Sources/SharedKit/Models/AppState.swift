import Foundation

public struct AppState: Codable {
    public var schemaVersion: Int
    public var dayKey: String
    public var tasks: [TaskItem]
    public var pet: PetState
    public var series: [TaskSeries]
    public var overrides: [TaskInstanceOverride]
    public var completions: [String: Set<UUID>] // dayKey -> completed instance ids
    public var rolloverEnabled: Bool
    public var graceMinutes: Int
    public var resetTime: DateComponents

    public init(
        schemaVersion: Int = 3,
        dayKey: String,
        tasks: [TaskItem] = [],
        pet: PetState,
        series: [TaskSeries] = [],
        overrides: [TaskInstanceOverride] = [],
        completions: [String: Set<UUID>] = [:],
        rolloverEnabled: Bool = false,
        graceMinutes: Int = 60,
        resetTime: DateComponents = DateComponents(hour: 0, minute: 0)
    ) {
        self.schemaVersion = schemaVersion
        self.dayKey = dayKey
        self.tasks = tasks
        self.pet = pet
        self.series = series
        self.overrides = overrides
        self.completions = completions
        self.rolloverEnabled = rolloverEnabled
        self.graceMinutes = graceMinutes
        self.resetTime = resetTime
    }
}