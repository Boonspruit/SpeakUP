import Foundation

// MARK: - Practice Mode

enum PracticeMode: String, CaseIterable, Codable, Identifiable {
    case presentation
    case speech
    case salesPitch
    case interview
    case elevatorPitch

    var id: String { rawValue }

    var categoryKey: String {
        switch self {
        case .presentation:  return "presentation"
        case .speech:        return "speech"
        case .salesPitch:    return "sales"
        case .interview:     return "interview"
        case .elevatorPitch: return "storytelling"
        }
    }

    var icon: String {
        switch self {
        case .presentation: return "chart.bar.doc.horizontal"
        case .speech:       return "mic.fill"
        case .salesPitch:   return "dollarsign.circle.fill"
        case .interview:    return "person.2.fill"
        case .elevatorPitch: return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .presentation: return "Presentation"
        case .speech:       return "Speech"
        case .salesPitch:   return "Sales Pitch"
        case .interview:    return "Interview"
        case .elevatorPitch: return "Elevator Pitch"
        }
    }
}

enum FocusTrack: String, CaseIterable, Codable, Hashable, Identifiable {
    case work
    case interviews
    case social
    case school
    case storytelling

    var id: String { rawValue }

    var label: String {
        switch self {
        case .work: return "Work"
        case .interviews: return "Interviews"
        case .social: return "Social"
        case .school: return "School"
        case .storytelling: return "Storytelling"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .interviews: return "person.crop.rectangle.fill"
        case .social: return "person.3.fill"
        case .school: return "graduationcap.fill"
        case .storytelling: return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .work: return "Updates, meetings, and professional speaking"
        case .interviews: return "Answers that sound calm and prepared"
        case .social: return "Toasts, intros, and everyday confidence"
        case .school: return "Class talks, explanations, and questions"
        case .storytelling: return "Personal stories that feel natural"
        }
    }

    var description: String {
        switch self {
        case .work: return "Practice updates, recommendations, and clear professional communication."
        case .interviews: return "Rehearse interview answers that feel confident and concise."
        case .social: return "Build confidence for intros, toasts, and speaking around other people."
        case .school: return "Practice classroom speaking, presentations, and short explanations."
        case .storytelling: return "Get better at telling short, memorable personal stories."
        }
    }

    var practiceMode: PracticeMode {
        switch self {
        case .work: return .presentation
        case .interviews: return .interview
        case .social: return .speech
        case .school: return .presentation
        case .storytelling: return .elevatorPitch
        }
    }
}

enum ScriptSource: String, Codable, Hashable {
    case curated
    case generated

    var badgeLabel: String {
        switch self {
        case .curated: return "Curated"
        case .generated: return "Generated"
        }
    }
}

// MARK: - Script

struct Script: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var category: String
    var focusTrack: FocusTrack
    var scenario: String
    var difficulty: String
    var targetDurationSec: Int
    var tone: String
    var coachingGoal: String
    var focusHint: String?
    var sections: ScriptSections
    var source: ScriptSource = .curated
    var generatedAt: Date?
    var originDrillID: String?
    var isPinned: Bool = false
    var createdAt: Date = Date()

    var fullText: String {
        [sections.opening, sections.point1, sections.point2, sections.point3, sections.closing]
            .joined(separator: "\n\n")
    }

    var practiceMode: PracticeMode {
        focusTrack.practiceMode
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, focusTrack, scenario, difficulty, targetDurationSec, tone, coachingGoal, focusHint, sections, source, generatedAt, originDrillID, isPinned, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(String.self, forKey: .category)
        focusTrack = (try? c.decode(FocusTrack.self, forKey: .focusTrack)) ?? Script.defaultFocusTrack(for: category)
        scenario = try c.decode(String.self, forKey: .scenario)
        difficulty = try c.decode(String.self, forKey: .difficulty)
        targetDurationSec = try c.decode(Int.self, forKey: .targetDurationSec)
        tone = try c.decode(String.self, forKey: .tone)
        coachingGoal = (try? c.decode(String.self, forKey: .coachingGoal)) ?? "Practice sounding clear and confident."
        focusHint = try? c.decodeIfPresent(String.self, forKey: .focusHint)
        sections = try c.decode(ScriptSections.self, forKey: .sections)
        source = (try? c.decode(ScriptSource.self, forKey: .source)) ?? .curated
        generatedAt = try? c.decodeIfPresent(Date.self, forKey: .generatedAt)
        originDrillID = try? c.decodeIfPresent(String.self, forKey: .originDrillID)
        isPinned = (try? c.decode(Bool.self, forKey: .isPinned)) ?? false
        createdAt = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
    }

    init(id: String, title: String, category: String, scenario: String,
         focusTrack: FocusTrack, difficulty: String, targetDurationSec: Int, tone: String,
         coachingGoal: String, focusHint: String? = nil,
         sections: ScriptSections, source: ScriptSource = .curated, generatedAt: Date? = nil,
         originDrillID: String? = nil, isPinned: Bool = false, createdAt: Date = Date()) {
        self.id = id; self.title = title; self.category = category
        self.focusTrack = focusTrack; self.scenario = scenario; self.difficulty = difficulty
        self.targetDurationSec = targetDurationSec; self.tone = tone
        self.coachingGoal = coachingGoal; self.focusHint = focusHint
        self.sections = sections; self.source = source; self.generatedAt = generatedAt
        self.originDrillID = originDrillID; self.isPinned = isPinned; self.createdAt = createdAt
    }

    private static func defaultFocusTrack(for category: String) -> FocusTrack {
        switch category {
        case "presentation": return .work
        case "interview": return .interviews
        case "speech": return .social
        case "storytelling": return .storytelling
        default: return .work
        }
    }
}

struct ScriptSections: Codable, Hashable {
    var opening: String
    var point1: String
    var point2: String
    var point3: String
    var closing: String

    enum CodingKeys: String, CodingKey {
        case opening
        case point1 = "point_1"
        case point2 = "point_2"
        case point3 = "point_3"
        case closing
    }
}

struct ScriptSeedResponse: Codable {
    let scripts: [Script]
}

// MARK: - Practice Session & Result

struct PracticeSession: Identifiable, Codable {
    let id: String
    let drillID: String
    let scriptTitle: String
    let focusTrack: FocusTrack
    let mode: PracticeMode
    let date: Date
    var result: PracticeResult

    enum CodingKeys: String, CodingKey {
        case id
        case drillID
        case scriptTitle
        case focusTrack
        case mode
        case date
        case result
    }

    init(
        id: String = UUID().uuidString,
        drillID: String,
        scriptTitle: String,
        focusTrack: FocusTrack,
        mode: PracticeMode,
        date: Date = Date(),
        result: PracticeResult
    ) {
        self.id = id
        self.drillID = drillID
        self.scriptTitle = scriptTitle
        self.focusTrack = focusTrack
        self.mode = mode
        self.date = date
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        scriptTitle = try container.decode(String.self, forKey: .scriptTitle)
        mode = try container.decode(PracticeMode.self, forKey: .mode)
        date = try container.decode(Date.self, forKey: .date)
        result = try container.decode(PracticeResult.self, forKey: .result)
        drillID = (try? container.decode(String.self, forKey: .drillID)) ?? id
        focusTrack = (try? container.decode(FocusTrack.self, forKey: .focusTrack)) ?? PracticeSession.defaultFocusTrack(for: mode)
    }

    func updating(result: PracticeResult) -> PracticeSession {
        PracticeSession(
            id: id,
            drillID: drillID,
            scriptTitle: scriptTitle,
            focusTrack: focusTrack,
            mode: mode,
            date: date,
            result: result
        )
    }

    private static func defaultFocusTrack(for mode: PracticeMode) -> FocusTrack {
        switch mode {
        case .presentation: return .work
        case .speech: return .social
        case .salesPitch: return .work
        case .interview: return .interviews
        case .elevatorPitch: return .storytelling
        }
    }
}

struct PracticeResult: Codable {
    let durationSeconds: Int
    let wordsPerMinute: Int
    let fillerWordCount: Int
    let score: Int
    let tips: [String]
    let transcript: String?
    let transcriptSegments: [SpeechTranscriptSegment]
    let metrics: PracticeSpeechMetrics?
    let feedback: PracticeSpeechFeedback?
    let transcriptionSource: SpeechTranscriptionSource
    let processingStatus: SpeechProcessingStatus

    enum CodingKeys: String, CodingKey {
        case durationSeconds
        case wordsPerMinute
        case fillerWordCount
        case score
        case tips
        case transcript
        case transcriptSegments
        case metrics
        case feedback
        case transcriptionSource
        case processingStatus
    }

    init(
        durationSeconds: Int,
        wordsPerMinute: Int,
        fillerWordCount: Int,
        score: Int,
        tips: [String],
        transcript: String? = nil,
        transcriptSegments: [SpeechTranscriptSegment] = [],
        metrics: PracticeSpeechMetrics? = nil,
        feedback: PracticeSpeechFeedback? = nil,
        transcriptionSource: SpeechTranscriptionSource = .unavailable,
        processingStatus: SpeechProcessingStatus = .localOnly
    ) {
        self.durationSeconds = durationSeconds
        self.wordsPerMinute = wordsPerMinute
        self.fillerWordCount = fillerWordCount
        self.score = score
        self.tips = tips
        self.transcript = transcript
        self.transcriptSegments = transcriptSegments
        self.metrics = metrics
        self.feedback = feedback
        self.transcriptionSource = transcriptionSource
        self.processingStatus = processingStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        wordsPerMinute = try container.decode(Int.self, forKey: .wordsPerMinute)
        fillerWordCount = try container.decode(Int.self, forKey: .fillerWordCount)
        score = try container.decode(Int.self, forKey: .score)
        tips = (try? container.decode([String].self, forKey: .tips)) ?? []
        transcript = try? container.decodeIfPresent(String.self, forKey: .transcript)
        transcriptSegments = (try? container.decode([SpeechTranscriptSegment].self, forKey: .transcriptSegments)) ?? []
        metrics = try? container.decodeIfPresent(PracticeSpeechMetrics.self, forKey: .metrics)
        feedback = try? container.decodeIfPresent(PracticeSpeechFeedback.self, forKey: .feedback)
        transcriptionSource = (try? container.decode(SpeechTranscriptionSource.self, forKey: .transcriptionSource)) ?? .unavailable
        processingStatus = (try? container.decode(SpeechProcessingStatus.self, forKey: .processingStatus)) ?? .localOnly
    }

    static let mock = PracticeResult(
        durationSeconds: 180, wordsPerMinute: 128, fillerWordCount: 4, score: 87,
        tips: ["Try pausing between key points for emphasis.",
               "Great pacing! You stayed within your target time."],
        transcript: "Welcome everyone. Thanks for being here today.",
        transcriptSegments: [],
        metrics: PracticeSpeechMetrics(
            transcriptWordCount: 8,
            pauseCount: 3,
            averagePauseDuration: 0.8,
            fillerBreakdown: ["um": 2, "uh": 1]
        ),
        feedback: PracticeSpeechFeedback(
            strength: "You kept a steady pace through most of your speech.",
            suggestions: [
                "Try pausing between key points for emphasis.",
                "Great pacing! You stayed within your target time."
            ],
            claritySummary: "Steady",
            source: .local
        ),
        transcriptionSource: .sfSpeechRecognizer,
        processingStatus: .complete
    )
}

enum PracticeState: Equatable {
    case setup, practicing, paused, complete
}

// MARK: - Streak

struct UserStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastPracticeDate: Date?
    var weeklyCompletions: [Bool]

    static let initial = UserStreak(currentStreak: 0, longestStreak: 0, lastPracticeDate: nil, weeklyCompletions: Array(repeating: false, count: 7))
    static let mock = UserStreak(currentStreak: 5, longestStreak: 12, lastPracticeDate: Date(), weeklyCompletions: [true, true, true, true, true, false, false])
}

// MARK: - Badge

struct Badge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    var isUnlocked: Bool

    static let allBadges: [Badge] = [
        Badge(id: "first_practice", title: "First Steps", description: "Complete your first drill", iconName: "star.fill", isUnlocked: false),
        Badge(id: "streak_3", title: "On a Roll", description: "Reach a 3-day streak", iconName: "flame.fill", isUnlocked: false),
        Badge(id: "streak_7", title: "Week Warrior", description: "Reach a 7-day streak", iconName: "flame.circle.fill", isUnlocked: false),
        Badge(id: "streak_30", title: "Unstoppable", description: "Reach a 30-day streak", iconName: "crown.fill", isUnlocked: false),
        Badge(id: "sessions_10", title: "Practice Pro", description: "Complete 10 drills", iconName: "hands.clap.fill", isUnlocked: false),
        Badge(id: "sessions_50", title: "Stage Master", description: "Complete 50 drills", iconName: "trophy.fill", isUnlocked: false),
        Badge(id: "all_modes", title: "Versatile Speaker", description: "Practice every focus track at least once", iconName: "sparkles", isUnlocked: false),
        Badge(id: "score_95", title: "Near Perfect", description: "Score 95+ on a drill", iconName: "bolt.fill", isUnlocked: false),
    ]
}

// MARK: - Duration Options

enum DurationOption: Int, CaseIterable, Identifiable {
    case thirty = 30, sixty = 60, ninety = 90
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .thirty: return "30 sec"
        case .sixty: return "60 sec"
        case .ninety: return "90 sec"
        }
    }
}
