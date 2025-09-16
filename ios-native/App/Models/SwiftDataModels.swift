import Foundation
import SwiftData

@Model
final class SDTaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var scheduledHour: Int
    var scheduledMinute: Int
    var dayKey: String
    var isCompleted: Bool
    var completedAt: Date?
    var snoozedUntil: Date?

    init(id: UUID, title: String, scheduledAt: DateComponents, dayKey: String, isCompleted: Bool, completedAt: Date?, snoozedUntil: Date?) {
        self.id = id
        self.title = title
        self.scheduledHour = scheduledAt.hour ?? 0
        self.scheduledMinute = scheduledAt.minute ?? 0
        self.dayKey = dayKey
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
    }
}

@Model
final class SDPetState {
    var stageIndex: Int
    var stageXP: Int
    var lastCloseoutDayKey: String

    init(stageIndex: Int, stageXP: Int, lastCloseoutDayKey: String) {
        self.stageIndex = stageIndex
        self.stageXP = stageXP
        self.lastCloseoutDayKey = lastCloseoutDayKey
    }
}




