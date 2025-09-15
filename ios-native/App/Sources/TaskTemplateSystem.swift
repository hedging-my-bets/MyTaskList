import Foundation
import SwiftUI
import SharedKit

// MARK: - Task Template System

@MainActor
final class TaskTemplateSystem: ObservableObject {
    static let shared = TaskTemplateSystem()

    @Published var availableTemplates: [TaskTemplate] = []
    @Published var categories: [TemplateCategory] = []

    private init() {
        loadTemplates()
    }

    // MARK: - Template Models

    struct TaskTemplate: Identifiable, Codable {
        let id = UUID()
        let name: String
        let description: String
        let category: TemplateCategory
        let tasks: [TemplateTask]
        let estimatedDuration: TimeInterval
        let difficulty: Difficulty
        let tags: [String]
        let icon: String

        enum Difficulty: String, CaseIterable, Codable {
            case beginner = "Beginner"
            case intermediate = "Intermediate"
            case advanced = "Advanced"
            case expert = "Expert"

            var color: Color {
                switch self {
                case .beginner: return .green
                case .intermediate: return .yellow
                case .advanced: return .orange
                case .expert: return .red
                }
            }
        }
    }

    struct TemplateTask: Identifiable, Codable {
        let id = UUID()
        let title: String
        let hour: Int
        let minute: Int
        let duration: TimeInterval
        let priority: Priority
        let notes: String?

        enum Priority: String, CaseIterable, Codable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"

            var color: Color {
                switch self {
                case .low: return .gray
                case .medium: return .blue
                case .high: return .orange
                case .critical: return .red
                }
            }
        }
    }

    enum TemplateCategory: String, CaseIterable, Codable {
        case productivity = "Productivity & Focus"
        case health = "Health & Wellness"
        case learning = "Learning & Development"
        case professional = "Professional & Career"
        case personal = "Personal & Life"

        var icon: String {
            switch self {
            case .productivity: return "brain.head.profile"
            case .health: return "heart.fill"
            case .learning: return "graduationcap.fill"
            case .professional: return "briefcase.fill"
            case .personal: return "house.fill"
            }
        }

        var color: Color {
            switch self {
            case .productivity: return .blue
            case .health: return .green
            case .learning: return .purple
            case .professional: return .orange
            case .personal: return .pink
            }
        }
    }

    // MARK: - Template Creation

    private func loadTemplates() {
        categories = TemplateCategory.allCases

        availableTemplates = [
            // PRODUCTIVITY & FOCUS
            createProductivityTemplates(),
            createFocusTemplates(),
            createDeepWorkTemplate(),

            // HEALTH & WELLNESS
            createMorningRoutineTemplate(),
            createWorkoutTemplate(),
            createSelfCareTemplate(),
            createMindfulnessTemplate(),

            // LEARNING & DEVELOPMENT
            createStudySessionTemplate(),
            createSkillBuildingTemplate(),
            createLanguageLearningTemplate(),
            createReadingTemplate(),

            // PROFESSIONAL & CAREER
            createWorkdayTemplate(),
            createMeetingDayTemplate(),
            createProjectDeadlineTemplate(),
            createNetworkingTemplate(),

            // PERSONAL & LIFE
            createHomeCareTemplate(),
            createFamilyTimeTemplate(),
            createReflectionTemplate(),
            createCreativeTemplate()
        ].flatMap { $0 }
    }

    // MARK: - Productivity Templates

    private func createProductivityTemplates() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Pomodoro Power Session",
                description: "Classic 25-minute focus blocks with strategic breaks",
                category: .productivity,
                tasks: [
                    TemplateTask(title: "Pomodoro 1: Priority Task", hour: 9, minute: 0, duration: 1500, priority: .high, notes: "Focus on your most important task"),
                    TemplateTask(title: "Break: Stretch & Hydrate", hour: 9, minute: 25, duration: 300, priority: .medium, notes: nil),
                    TemplateTask(title: "Pomodoro 2: Secondary Task", hour: 9, minute: 30, duration: 1500, priority: .medium, notes: nil),
                    TemplateTask(title: "Break: Fresh Air", hour: 9, minute: 55, duration: 300, priority: .low, notes: nil),
                    TemplateTask(title: "Pomodoro 3: Admin Tasks", hour: 10, minute: 0, duration: 1500, priority: .medium, notes: nil),
                    TemplateTask(title: "Long Break: Recharge", hour: 10, minute: 25, duration: 900, priority: .medium, notes: "15-minute break to recharge")
                ],
                estimatedDuration: 7200, // 2 hours
                difficulty: .beginner,
                tags: ["focus", "productivity", "time-management"],
                icon: "timer"
            )
        ]
    }

    private func createFocusTemplates() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Deep Focus Flow",
                description: "Extended focus session for complex projects",
                category: .productivity,
                tasks: [
                    TemplateTask(title: "Environment Setup", hour: 8, minute: 30, duration: 600, priority: .medium, notes: "Clear workspace, gather materials"),
                    TemplateTask(title: "Deep Work Block 1", hour: 8, minute: 40, duration: 3600, priority: .critical, notes: "No interruptions, phone on silent"),
                    TemplateTask(title: "Active Break", hour: 9, minute: 40, duration: 1200, priority: .medium, notes: "Walk, stretch, or light exercise"),
                    TemplateTask(title: "Deep Work Block 2", hour: 10, minute: 0, duration: 3600, priority: .critical, notes: "Continue focused work"),
                    TemplateTask(title: "Review & Plan", hour: 11, minute: 0, duration: 1800, priority: .high, notes: "Review progress, plan next steps")
                ],
                estimatedDuration: 10800, // 3 hours
                difficulty: .advanced,
                tags: ["deep-work", "focus", "productivity"],
                icon: "scope"
            )
        ]
    }

    private func createDeepWorkTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Creative Flow State",
                description: "Optimized for creative and intellectual work",
                category: .productivity,
                tasks: [
                    TemplateTask(title: "Mind Dump", hour: 7, minute: 0, duration: 900, priority: .medium, notes: "Clear mental clutter, write everything down"),
                    TemplateTask(title: "Inspiration Gathering", hour: 7, minute: 15, duration: 1800, priority: .medium, notes: "Collect references, ideas, inspiration"),
                    TemplateTask(title: "Creative Work Sprint", hour: 7, minute: 45, duration: 4500, priority: .critical, notes: "Pure creative work, no editing"),
                    TemplateTask(title: "Reflection Break", hour: 9, minute: 0, duration: 900, priority: .low, notes: "Step back, assess work"),
                    TemplateTask(title: "Refinement Session", hour: 9, minute: 15, duration: 2700, priority: .high, notes: "Edit, polish, improve")
                ],
                estimatedDuration: 10800, // 3 hours
                difficulty: .intermediate,
                tags: ["creative", "flow", "inspiration"],
                icon: "paintbrush.fill"
            )
        ]
    }

    // MARK: - Health & Wellness Templates

    private func createMorningRoutineTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Energizing Morning",
                description: "Start your day with intention and energy",
                category: .health,
                tasks: [
                    TemplateTask(title: "Hydration & Supplements", hour: 6, minute: 30, duration: 300, priority: .high, notes: "Glass of water, vitamins"),
                    TemplateTask(title: "Movement & Stretching", hour: 6, minute: 35, duration: 900, priority: .high, notes: "Light yoga or stretching"),
                    TemplateTask(title: "Mindfulness Practice", hour: 6, minute: 50, duration: 600, priority: .medium, notes: "Meditation or breathing exercises"),
                    TemplateTask(title: "Gratitude Journaling", hour: 7, minute: 0, duration: 600, priority: .medium, notes: "Write 3 things you're grateful for"),
                    TemplateTask(title: "Healthy Breakfast", hour: 7, minute: 10, duration: 1200, priority: .high, notes: "Nutritious, balanced meal"),
                    TemplateTask(title: "Day Planning", hour: 7, minute: 30, duration: 600, priority: .high, notes: "Review goals, set intentions")
                ],
                estimatedDuration: 3600, // 1 hour
                difficulty: .beginner,
                tags: ["morning", "wellness", "routine"],
                icon: "sunrise.fill"
            )
        ]
    }

    private func createWorkoutTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Strength & Cardio",
                description: "Balanced workout for strength and endurance",
                category: .health,
                tasks: [
                    TemplateTask(title: "Dynamic Warm-up", hour: 6, minute: 0, duration: 600, priority: .high, notes: "Joint mobility, light movement"),
                    TemplateTask(title: "Strength Training", hour: 6, minute: 10, duration: 2400, priority: .critical, notes: "Compound movements, progressive overload"),
                    TemplateTask(title: "Cardio Interval", hour: 6, minute: 50, duration: 1200, priority: .high, notes: "High intensity intervals"),
                    TemplateTask(title: "Cool Down & Stretch", hour: 7, minute: 10, duration: 600, priority: .medium, notes: "Static stretching, recovery"),
                    TemplateTask(title: "Hydration & Notes", hour: 7, minute: 20, duration: 300, priority: .medium, notes: "Log workout, hydrate")
                ],
                estimatedDuration: 4800, // 80 minutes
                difficulty: .intermediate,
                tags: ["fitness", "strength", "cardio"],
                icon: "figure.strengthtraining.traditional"
            )
        ]
    }

    private func createSelfCareTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Sunday Self-Care",
                description: "Weekly reset and rejuvenation routine",
                category: .health,
                tasks: [
                    TemplateTask(title: "Digital Detox Start", hour: 9, minute: 0, duration: 300, priority: .medium, notes: "Put devices away"),
                    TemplateTask(title: "Skincare Routine", hour: 9, minute: 5, duration: 1800, priority: .medium, notes: "Deep cleansing, masks, moisturizing"),
                    TemplateTask(title: "Relaxing Bath/Shower", hour: 9, minute: 35, duration: 2400, priority: .high, notes: "Aromatherapy, relaxation"),
                    TemplateTask(title: "Meditation & Reflection", hour: 10, minute: 15, duration: 1200, priority: .high, notes: "Weekly reflection, mindfulness"),
                    TemplateTask(title: "Creative Expression", hour: 10, minute: 35, duration: 3600, priority: .medium, notes: "Art, music, writing - whatever brings joy"),
                    TemplateTask(title: "Healthy Meal Prep", hour: 11, minute: 35, duration: 2400, priority: .high, notes: "Prepare nutritious meals for the week")
                ],
                estimatedDuration: 12000, // 3+ hours
                difficulty: .beginner,
                tags: ["self-care", "wellness", "relaxation"],
                icon: "heart.circle.fill"
            )
        ]
    }

    private func createMindfulnessTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Mindful Day",
                description: "Integrate mindfulness throughout your day",
                category: .health,
                tasks: [
                    TemplateTask(title: "Morning Meditation", hour: 7, minute: 0, duration: 1200, priority: .high, notes: "Set intention for the day"),
                    TemplateTask(title: "Mindful Breakfast", hour: 7, minute: 20, duration: 1800, priority: .medium, notes: "Eat slowly, savor flavors"),
                    TemplateTask(title: "Gratitude Check-in", hour: 12, minute: 0, duration: 300, priority: .medium, notes: "Notice 3 good things"),
                    TemplateTask(title: "Walking Meditation", hour: 15, minute: 0, duration: 900, priority: .medium, notes: "Mindful outdoor walk"),
                    TemplateTask(title: "Body Scan", hour: 18, minute: 0, duration: 1200, priority: .medium, notes: "Release tension, check in"),
                    TemplateTask(title: "Evening Reflection", hour: 21, minute: 0, duration: 900, priority: .high, notes: "Journal about the day")
                ],
                estimatedDuration: 6300, // 1.75 hours spread throughout day
                difficulty: .beginner,
                tags: ["mindfulness", "meditation", "awareness"],
                icon: "brain.head.profile"
            )
        ]
    }

    // MARK: - Learning Templates

    private func createStudySessionTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Effective Study Session",
                description: "Optimized learning with active recall and spaced repetition",
                category: .learning,
                tasks: [
                    TemplateTask(title: "Review Previous Material", hour: 9, minute: 0, duration: 900, priority: .medium, notes: "Quick review of last session"),
                    TemplateTask(title: "New Content Learning", hour: 9, minute: 15, duration: 2700, priority: .critical, notes: "Focus on understanding concepts"),
                    TemplateTask(title: "Active Recall Practice", hour: 10, minute: 0, duration: 1800, priority: .high, notes: "Test yourself without notes"),
                    TemplateTask(title: "Break: Movement", hour: 10, minute: 30, duration: 600, priority: .medium, notes: "Physical activity to refresh"),
                    TemplateTask(title: "Application Exercises", hour: 10, minute: 40, duration: 2400, priority: .high, notes: "Practice problems, examples"),
                    TemplateTask(title: "Summary & Next Steps", hour: 11, minute: 20, duration: 600, priority: .medium, notes: "Consolidate learning, plan ahead")
                ],
                estimatedDuration: 7200, // 2 hours
                difficulty: .intermediate,
                tags: ["study", "learning", "recall"],
                icon: "book.fill"
            )
        ]
    }

    private func createSkillBuildingTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Skill Development Sprint",
                description: "Focused practice for building specific skills",
                category: .learning,
                tasks: [
                    TemplateTask(title: "Skill Assessment", hour: 14, minute: 0, duration: 900, priority: .medium, notes: "Identify current level, goals"),
                    TemplateTask(title: "Technique Study", hour: 14, minute: 15, duration: 1800, priority: .high, notes: "Learn proper methods, best practices"),
                    TemplateTask(title: "Deliberate Practice", hour: 14, minute: 45, duration: 3600, priority: .critical, notes: "Focused, challenging practice"),
                    TemplateTask(title: "Feedback Analysis", hour: 15, minute: 45, duration: 900, priority: .high, notes: "Analyze performance, identify improvements"),
                    TemplateTask(title: "Skill Integration", hour: 16, minute: 0, duration: 1800, priority: .medium, notes: "Apply skill in broader context")
                ],
                estimatedDuration: 8100, // 2.25 hours
                difficulty: .advanced,
                tags: ["skill-building", "practice", "improvement"],
                icon: "target"
            )
        ]
    }

    private func createLanguageLearningTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Language Immersion",
                description: "Comprehensive language learning session",
                category: .learning,
                tasks: [
                    TemplateTask(title: "Vocabulary Review", hour: 8, minute: 0, duration: 900, priority: .medium, notes: "Review flashcards, spaced repetition"),
                    TemplateTask(title: "Grammar Study", hour: 8, minute: 15, duration: 1200, priority: .high, notes: "New grammar concepts with examples"),
                    TemplateTask(title: "Listening Practice", hour: 8, minute: 35, duration: 1800, priority: .high, notes: "Podcasts, music, native speakers"),
                    TemplateTask(title: "Speaking Practice", hour: 9, minute: 5, duration: 1800, priority: .critical, notes: "Conversation practice, pronunciation"),
                    TemplateTask(title: "Reading Comprehension", hour: 9, minute: 35, duration: 1500, priority: .medium, notes: "Articles, stories in target language"),
                    TemplateTask(title: "Writing Exercise", hour: 10, minute: 0, duration: 1200, priority: .medium, notes: "Journal, essays, creative writing")
                ],
                estimatedDuration: 7200, // 2 hours
                difficulty: .intermediate,
                tags: ["language", "immersion", "communication"],
                icon: "globe"
            )
        ]
    }

    private func createReadingTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Deep Reading Session",
                description: "Focused reading with comprehension and retention",
                category: .learning,
                tasks: [
                    TemplateTask(title: "Preview & Set Purpose", hour: 19, minute: 0, duration: 600, priority: .medium, notes: "Skim, set reading goals"),
                    TemplateTask(title: "Active Reading", hour: 19, minute: 10, duration: 2400, priority: .high, notes: "Read actively, take notes"),
                    TemplateTask(title: "Reflection Break", hour: 19, minute: 50, duration: 600, priority: .medium, notes: "Process what you've read"),
                    TemplateTask(title: "Continued Reading", hour: 20, minute: 0, duration: 2400, priority: .high, notes: "Continue with focus"),
                    TemplateTask(title: "Summary & Insights", hour: 20, minute: 40, duration: 1200, priority: .high, notes: "Summarize key points, insights")
                ],
                estimatedDuration: 6000, // 1.67 hours
                difficulty: .beginner,
                tags: ["reading", "comprehension", "knowledge"],
                icon: "text.book.closed.fill"
            )
        ]
    }

    // MARK: - Professional Templates

    private func createWorkdayTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Productive Workday",
                description: "Structured workday for maximum productivity",
                category: .professional,
                tasks: [
                    TemplateTask(title: "Day Planning", hour: 8, minute: 30, duration: 900, priority: .high, notes: "Review calendar, set priorities"),
                    TemplateTask(title: "Deep Work Block", hour: 8, minute: 45, duration: 5400, priority: .critical, notes: "Most important project work"),
                    TemplateTask(title: "Email & Communication", hour: 10, minute: 15, duration: 1800, priority: .medium, notes: "Process inbox, respond to messages"),
                    TemplateTask(title: "Team Collaboration", hour: 10, minute: 45, duration: 3600, priority: .high, notes: "Meetings, discussions, planning"),
                    TemplateTask(title: "Administrative Tasks", hour: 11, minute: 45, duration: 1800, priority: .medium, notes: "Reports, documentation, cleanup"),
                    TemplateTask(title: "End-of-Day Review", hour: 12, minute: 15, duration: 900, priority: .medium, notes: "Review progress, plan tomorrow")
                ],
                estimatedDuration: 14400, // 4 hours
                difficulty: .intermediate,
                tags: ["work", "productivity", "professional"],
                icon: "briefcase.fill"
            )
        ]
    }

    private func createMeetingDayTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Meeting-Heavy Day",
                description: "Navigate a day full of meetings effectively",
                category: .professional,
                tasks: [
                    TemplateTask(title: "Meeting Prep", hour: 8, minute: 0, duration: 1800, priority: .high, notes: "Review agendas, prepare materials"),
                    TemplateTask(title: "Morning Meeting Block", hour: 8, minute: 30, duration: 5400, priority: .critical, notes: "Back-to-back meetings"),
                    TemplateTask(title: "Quick Email Check", hour: 10, minute: 0, duration: 900, priority: .medium, notes: "Urgent messages only"),
                    TemplateTask(title: "Afternoon Meeting Block", hour: 10, minute: 15, duration: 5400, priority: .critical, notes: "Continue meetings"),
                    TemplateTask(title: "Meeting Notes Review", hour: 11, minute: 45, duration: 1800, priority: .high, notes: "Process notes, action items"),
                    TemplateTask(title: "Follow-up Actions", hour: 12, minute: 15, duration: 2700, priority: .high, notes: "Send summaries, schedule follow-ups")
                ],
                estimatedDuration: 18000, // 5 hours
                difficulty: .advanced,
                tags: ["meetings", "collaboration", "communication"],
                icon: "person.3.fill"
            )
        ]
    }

    private func createProjectDeadlineTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Deadline Sprint",
                description: "Intensive work session to meet project deadlines",
                category: .professional,
                tasks: [
                    TemplateTask(title: "Priority Assessment", hour: 8, minute: 0, duration: 900, priority: .critical, notes: "Identify must-do vs nice-to-have"),
                    TemplateTask(title: "Focus Block 1", hour: 8, minute: 15, duration: 7200, priority: .critical, notes: "Uninterrupted work on core deliverables"),
                    TemplateTask(title: "Progress Check", hour: 10, minute: 15, duration: 900, priority: .high, notes: "Assess progress, adjust plan"),
                    TemplateTask(title: "Focus Block 2", hour: 10, minute: 30, duration: 5400, priority: .critical, notes: "Continue focused work"),
                    TemplateTask(title: "Quality Review", hour: 12, minute: 0, duration: 1800, priority: .high, notes: "Review, polish, final checks"),
                    TemplateTask(title: "Submission/Delivery", hour: 12, minute: 30, duration: 1800, priority: .critical, notes: "Submit or deliver final work")
                ],
                estimatedDuration: 18000, // 5 hours
                difficulty: .expert,
                tags: ["deadline", "pressure", "delivery"],
                icon: "clock.badge.exclamationmark.fill"
            )
        ]
    }

    private func createNetworkingTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Professional Networking",
                description: "Build and maintain professional relationships",
                category: .professional,
                tasks: [
                    TemplateTask(title: "Contact List Review", hour: 16, minute: 0, duration: 1200, priority: .medium, notes: "Review contacts, identify priorities"),
                    TemplateTask(title: "LinkedIn Engagement", hour: 16, minute: 20, duration: 1800, priority: .medium, notes: "Comment, share, connect"),
                    TemplateTask(title: "Personal Outreach", hour: 16, minute: 50, duration: 2400, priority: .high, notes: "Send personal messages, emails"),
                    TemplateTask(title: "Industry Research", hour: 17, minute: 30, duration: 1800, priority: .medium, notes: "Stay updated on industry trends"),
                    TemplateTask(title: "Event Planning", hour: 18, minute: 0, duration: 1200, priority: .low, notes: "Research upcoming networking events")
                ],
                estimatedDuration: 8400, // 2.33 hours
                difficulty: .intermediate,
                tags: ["networking", "relationships", "career"],
                icon: "network"
            )
        ]
    }

    // MARK: - Personal Templates

    private func createHomeCareTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Home Organization",
                description: "Maintain and organize your living space",
                category: .personal,
                tasks: [
                    TemplateTask(title: "Living Areas Tidy", hour: 10, minute: 0, duration: 1800, priority: .medium, notes: "Living room, dining room cleanup"),
                    TemplateTask(title: "Kitchen Deep Clean", hour: 10, minute: 30, duration: 2400, priority: .high, notes: "Dishes, counters, appliances"),
                    TemplateTask(title: "Bedroom Organization", hour: 11, minute: 10, duration: 1800, priority: .medium, notes: "Make bed, organize closet"),
                    TemplateTask(title: "Bathroom Refresh", hour: 11, minute: 40, duration: 1200, priority: .medium, notes: "Clean surfaces, restock supplies"),
                    TemplateTask(title: "Laundry Management", hour: 12, minute: 0, duration: 1800, priority: .high, notes: "Sort, wash, fold, put away"),
                    TemplateTask(title: "Weekly Planning", hour: 12, minute: 30, duration: 1200, priority: .medium, notes: "Meal planning, schedule review")
                ],
                estimatedDuration: 10200, // 2.83 hours
                difficulty: .beginner,
                tags: ["home", "organization", "cleaning"],
                icon: "house.fill"
            )
        ]
    }

    private func createFamilyTimeTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Quality Family Time",
                description: "Meaningful activities to connect with family",
                category: .personal,
                tasks: [
                    TemplateTask(title: "Family Breakfast", hour: 8, minute: 0, duration: 2400, priority: .high, notes: "Cook and eat together"),
                    TemplateTask(title: "Outdoor Activity", hour: 10, minute: 0, duration: 3600, priority: .high, notes: "Walk, park, outdoor games"),
                    TemplateTask(title: "Creative Project", hour: 11, minute: 0, duration: 2400, priority: .medium, notes: "Art, crafts, building together"),
                    TemplateTask(title: "Family Lunch", hour: 12, minute: 0, duration: 1800, priority: .medium, notes: "Prepare and share meal"),
                    TemplateTask(title: "Story/Reading Time", hour: 14, minute: 0, duration: 1800, priority: .medium, notes: "Read books together"),
                    TemplateTask(title: "Reflection & Planning", hour: 19, minute: 0, duration: 1200, priority: .low, notes: "Discuss day, plan activities")
                ],
                estimatedDuration: 13200, // 3.67 hours
                difficulty: .beginner,
                tags: ["family", "connection", "quality-time"],
                icon: "heart.fill"
            )
        ]
    }

    private func createReflectionTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Weekly Reflection",
                description: "Deep reflection and planning for personal growth",
                category: .personal,
                tasks: [
                    TemplateTask(title: "Week Review", hour: 19, minute: 0, duration: 1800, priority: .high, notes: "Review accomplishments, challenges"),
                    TemplateTask(title: "Goal Assessment", hour: 19, minute: 30, duration: 1800, priority: .high, notes: "Progress on personal goals"),
                    TemplateTask(title: "Gratitude Practice", hour: 20, minute: 0, duration: 900, priority: .medium, notes: "Write down things you're grateful for"),
                    TemplateTask(title: "Learning Insights", hour: 20, minute: 15, duration: 1200, priority: .medium, notes: "What did you learn this week?"),
                    TemplateTask(title: "Next Week Planning", hour: 20, minute: 35, duration: 1800, priority: .high, notes: "Set intentions and goals"),
                    TemplateTask(title: "Vision Alignment", hour: 21, minute: 5, duration: 900, priority: .medium, notes: "Connect actions to bigger picture")
                ],
                estimatedDuration: 8400, // 2.33 hours
                difficulty: .intermediate,
                tags: ["reflection", "planning", "growth"],
                icon: "brain.head.profile"
            )
        ]
    }

    private func createCreativeTemplate() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Creative Expression",
                description: "Unleash creativity through various artistic mediums",
                category: .personal,
                tasks: [
                    TemplateTask(title: "Inspiration Gathering", hour: 14, minute: 0, duration: 1200, priority: .medium, notes: "Browse art, read, observe nature"),
                    TemplateTask(title: "Warm-up Exercises", hour: 14, minute: 20, duration: 1200, priority: .medium, notes: "Quick sketches, writing prompts"),
                    TemplateTask(title: "Main Creative Work", hour: 14, minute: 40, duration: 4800, priority: .critical, notes: "Primary creative project"),
                    TemplateTask(title: "Experimentation", hour: 16, minute: 0, duration: 1800, priority: .medium, notes: "Try new techniques, materials"),
                    TemplateTask(title: "Documentation", hour: 16, minute: 30, duration: 900, priority: .low, notes: "Photo, notes about process"),
                    TemplateTask(title: "Reflection & Next Steps", hour: 16, minute: 45, duration: 900, priority: .medium, notes: "Assess work, plan improvements")
                ],
                estimatedDuration: 10800, // 3 hours
                difficulty: .beginner,
                tags: ["creativity", "art", "expression"],
                icon: "paintbrush.pointed.fill"
            )
        ]
    }

    // MARK: - Public Interface

    func getTemplates(for category: TemplateCategory? = nil) -> [TaskTemplate] {
        if let category = category {
            return availableTemplates.filter { $0.category == category }
        }
        return availableTemplates
    }

    func searchTemplates(query: String) -> [TaskTemplate] {
        let lowercaseQuery = query.lowercased()
        return availableTemplates.filter { template in
            template.name.lowercased().contains(lowercaseQuery) ||
            template.description.lowercased().contains(lowercaseQuery) ||
            template.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }

    func createTasksFromTemplate(_ template: TaskTemplate, for date: Date) -> [MaterializedTask] {
        let calendar = Calendar.current
        let dayKey = dayKey(for: date)

        return template.tasks.map { templateTask in
            let scheduledTime = calendar.date(bySettingHour: templateTask.hour, minute: templateTask.minute, second: 0, of: date) ?? date

            return MaterializedTask(
                id: templateTask.id.uuidString,
                title: templateTask.title,
                scheduledAt: scheduledTime,
                isCompleted: false,
                dayKey: dayKey,
                notes: templateTask.notes
            )
        }
    }

    func saveCustomTemplate(_ template: TaskTemplate) {
        // In a full implementation, this would save to persistent storage
        availableTemplates.append(template)
    }
}

// MARK: - Template Views

struct TemplateListView: View {
    @StateObject private var templateSystem = TaskTemplateSystem.shared
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var searchText = ""

    var filteredTemplates: [TaskTemplate] {
        let categoryFiltered = templateSystem.getTemplates(for: selectedCategory)

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)

                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? category.color : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }

                // Template List
                List(filteredTemplates) { template in
                    TemplateRowView(template: template)
                }
                .searchable(text: $searchText, prompt: "Search templates...")
            }
            .navigationTitle("Task Templates")
        }
    }
}

struct TemplateRowView: View {
    let template: TaskTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.icon)
                    .foregroundColor(template.category.color)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(template.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(template.difficulty.color.opacity(0.2))
                        .foregroundColor(template.difficulty.color)
                        .cornerRadius(8)

                    Text("\(template.tasks.count) tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(template.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}