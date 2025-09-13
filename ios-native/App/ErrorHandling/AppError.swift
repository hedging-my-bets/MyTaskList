import Foundation

enum AppError: LocalizedError {
    case dataCorruption
    case migrationFailed
    case widgetLoadFailed
    case plannerLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .dataCorruption:
            return "Data corruption detected. Please restart the app."
        case .migrationFailed:
            return "Failed to migrate data. Please restart the app."
        case .widgetLoadFailed:
            return "Widget failed to load. Please try again."
        case .plannerLoadFailed:
            return "Planner failed to load. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataCorruption, .migrationFailed:
            return "If the problem persists, delete and reinstall the app."
        case .widgetLoadFailed, .plannerLoadFailed:
            return "Try removing and re-adding the widget."
        }
    }
}


