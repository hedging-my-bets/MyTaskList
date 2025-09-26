import Foundation
import XCTest
@testable import SharedKit

/// Mock types for test infrastructure
@available(iOS 17.0, *)
final class MockAppGroupStore {
    var state = AppGroupState()

    func isTaskCompleted(_ taskId: UUID, dayKey: String) -> Bool {
        return state.completions[dayKey]?.contains(taskId) ?? false
    }

    func updateCurrentPage(_ page: Int) {
        state.currentPage = page
    }

    func getCurrentTasks() -> [TaskItem] {
        return state.tasks
    }
}

/// Mock App Intent classes for test compatibility
struct CompleteTaskIntent {
    let taskID: String

    func perform() async throws -> String {
        guard !taskID.isEmpty, UUID(uuidString: taskID) != nil else {
            throw IntentError.invalidTaskID
        }
        return "Task completed"
    }
}

struct SkipTaskIntent {
    let taskID: String

    func perform() async throws -> String {
        guard !taskID.isEmpty, UUID(uuidString: taskID) != nil else {
            throw IntentError.invalidTaskID
        }
        return "Task skipped"
    }
}

struct AdvancePageIntent {
    enum Direction {
        case next, previous
    }

    let direction: Direction

    func perform() async throws -> String {
        return "Page advanced"
    }
}

struct PetProgressTaskQuery {
    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        return []
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        return []
    }

    func defaultResult() async throws -> TaskEntity? {
        return nil
    }
}

struct TaskEntity {
    let title: String
    let hour: Int
}

enum IntentError: Error {
    case invalidTaskID
}