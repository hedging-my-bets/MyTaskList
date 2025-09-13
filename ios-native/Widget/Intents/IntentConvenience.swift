import AppIntents

@available(iOS 17.0, *)
extension CompleteTaskIntent {
    init(taskId: String, dayKey: String) {
        self.init()
        self.taskId = .init(taskId)
        self.dayKey = .init(dayKey)
    }
}

@available(iOS 17.0, *)
extension SnoozeNextTaskIntent {
    init(taskId: String, dayKey: String) {
        self.init()
        self.taskId = .init(taskId)
        self.dayKey = .init(dayKey)
    }
}

@available(iOS 17.0, *)
extension MarkNextTaskDoneIntent {
    init(dayKey: String) {
        self.init()
        self.dayKey = .init(dayKey)
    }
}


