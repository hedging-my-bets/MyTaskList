import Foundation

// MARK: - Public API Exports

// Export all public types and functions from SharedKit
public typealias TimeSlot = TimeSlot
public typealias DayModel = DayModel
public typealias TaskEntity = TaskEntity
public typealias StageConfig = StageConfig
public typealias PetEvolutionEngine = PetEvolutionEngine
public typealias SharedStore = SharedStore
public typealias TaskPlanner = TaskPlanner
public typealias TaskFeedItem = TaskFeedItem
public typealias TaskStatus = TaskStatus
public typealias AssetPipeline = AssetPipeline
public typealias AssetValidationResult = AssetValidationResult

// MARK: - Module Info

public struct SharedKitInfo {
    public static let version = "1.0.0"
    public static let minimumIOSVersion = "17.0"
}
