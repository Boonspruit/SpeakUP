import Foundation

enum PracticeCompletionDestination {
    case practiceAgain
    case reviewDrill
    case home
    case progress
}

struct SpeechCompletionSummary {
    let heroEyebrow: String
    let heroTitle: String
    let heroSubtitle: String
    let durationValue: String
    let paceValue: String
    let fillerValue: String
    let clarityValue: String
    let modeValue: String
    let dateValue: String
    let strengthText: String
    let improvementSuggestions: [String]
    let streakTitle: String
    let streakSubtitle: String
    let milestoneTitle: String?
    let milestoneSubtitle: String?
    let saveConfirmationText: String

    init(
        heroEyebrow: String,
        heroTitle: String,
        heroSubtitle: String,
        durationValue: String,
        paceValue: String,
        fillerValue: String,
        clarityValue: String,
        modeValue: String,
        dateValue: String,
        strengthText: String,
        improvementSuggestions: [String],
        streakTitle: String,
        streakSubtitle: String,
        milestoneTitle: String?,
        milestoneSubtitle: String?,
        saveConfirmationText: String
    ) {
        self.heroEyebrow = heroEyebrow
        self.heroTitle = heroTitle
        self.heroSubtitle = heroSubtitle
        self.durationValue = durationValue
        self.paceValue = paceValue
        self.fillerValue = fillerValue
        self.clarityValue = clarityValue
        self.modeValue = modeValue
        self.dateValue = dateValue
        self.strengthText = strengthText
        self.improvementSuggestions = improvementSuggestions
        self.streakTitle = streakTitle
        self.streakSubtitle = streakSubtitle
        self.milestoneTitle = milestoneTitle
        self.milestoneSubtitle = milestoneSubtitle
        self.saveConfirmationText = saveConfirmationText
    }

    init(session: PracticeSession, streak: UserStreak, totalSessions: Int) {
        let result = session.result
        let weeklyCount = streak.weeklyCompletions.filter { $0 }.count
        let feedback = result.feedback
        let clarityText = feedback?.claritySummary ?? SpeechCompletionSummary.clarityFallback(for: result)
        let suggestions = feedback?.suggestions ?? SpeechCompletionSummary.suggestions(for: result)
        let strength = feedback?.strength ?? SpeechCompletionSummary.strengthText(for: result)

        heroEyebrow = SpeechCompletionSummary.heroEyebrow(for: result)
        heroTitle = SpeechCompletionSummary.heroTitle(for: totalSessions)
        heroSubtitle = SpeechCompletionSummary.heroSubtitle(for: session, result: result)

        durationValue = SpeechCompletionSummary.durationText(for: result.durationSeconds)
        paceValue = "\(result.wordsPerMinute) wpm"
        fillerValue = "\(result.fillerWordCount)"
        clarityValue = clarityText
        modeValue = session.focusTrack.label
        dateValue = SpeechCompletionSummary.dateText(for: session.date)

        strengthText = strength
        improvementSuggestions = suggestions

        streakTitle = "Streak saved: \(streak.currentStreak) \(streak.currentStreak == 1 ? "day" : "days")"
        streakSubtitle = SpeechCompletionSummary.streakSubtitle(weeklyCount: weeklyCount)

        let milestone = SpeechCompletionSummary.milestone(totalSessions: totalSessions, streak: streak)
        milestoneTitle = milestone.title
        milestoneSubtitle = milestone.subtitle

        saveConfirmationText = SpeechCompletionSummary.saveConfirmationText(for: result)
    }

    static let mock = SpeechCompletionSummary(
        heroEyebrow: "Nice job",
        heroTitle: "Great practice session",
        heroSubtitle: "You completed today's drill.",
        durationValue: "3m 00s",
        paceValue: "128 wpm",
        fillerValue: "4",
        clarityValue: "87%",
        modeValue: "Work",
        dateValue: "Today - 3:45 PM",
        strengthText: "You kept a steady pace through most of your speech, which made your delivery feel calm and clear.",
        improvementSuggestions: [
            "Try slowing down slightly when you introduce key points.",
            "Consider adding a short pause between sections to give each idea more space."
        ],
        streakTitle: "Streak saved: 6 days",
        streakSubtitle: "One more drill this week to hit your target.",
        milestoneTitle: "You completed today's drill goal",
        milestoneSubtitle: "Small daily drills like this are what build real speaking confidence.",
        saveConfirmationText: "Saved to your recent drills."
    )

    private static func heroEyebrow(for result: PracticeResult) -> String {
        switch result.processingStatus {
        case .processing:
            return "Nice job"
        case .complete where result.score >= 92:
            return "Strong finish"
        case .complete where result.score >= 82:
            return "Nice job"
        case .localOnly where result.score >= 82:
            return "Nice job"
        default:
            return "Great effort"
        }
    }

    private static func heroTitle(for totalSessions: Int) -> String {
        switch totalSessions {
        case 1: return "First drill complete"
        case 2...9: return "Great practice session"
        default: return "Another drill in the books"
        }
    }

    private static func durationText(for seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return "\(minutes)m \(String(format: "%02ds", remainder))"
    }

    private static func heroSubtitle(for session: PracticeSession, result: PracticeResult) -> String {
        switch result.processingStatus {
        case .processing:
            return "You completed today's \(session.focusTrack.label.lowercased()) drill. We're wrapping up your transcript and feedback."
        case .failed:
            return "You completed today's drill. Your session is still saved locally."
        case .localOnly, .complete:
            return "You completed today's drill."
        }
    }

    private static func dateText(for date: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        if calendar.isDateInToday(date) {
            return "Today - \(timeFormatter.string(from: date))"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d - h:mm a"
        return formatter.string(from: date)
    }

    private static func strengthText(for result: PracticeResult) -> String {
        switch result.processingStatus {
        case .processing:
            return "Your drill is saved, and your AI coaching is being generated now."
        case .failed:
            return "Your drill is saved, but AI coaching isn't available right now."
        case .localOnly:
            return "Your drill is saved."
        case .complete:
            return "Your AI coaching is ready."
        }
    }

    private static func suggestions(for result: PracticeResult) -> [String] {
        switch result.processingStatus {
        case .processing:
            return []
        case .failed:
            return []
        case .localOnly:
            return []
        case .complete:
            return []
        }
    }

    private static func clarityFallback(for result: PracticeResult) -> String {
        switch result.processingStatus {
        case .processing:
            return "Generating"
        case .failed:
            return "Unavailable"
        case .localOnly:
            return "Pending"
        case .complete:
            return "--"
        }
    }

    private static func streakSubtitle(weeklyCount: Int) -> String {
        switch weeklyCount {
        case 5...:
            return "You completed today's drill goal and your week is looking strong."
        case 4:
            return "One more drill this week to hit your target."
        case 1...3:
            return "\(max(0, 5 - weeklyCount)) more drills this week to reach your goal."
        default:
            return "Today's practice puts real momentum behind your streak."
        }
    }

    private static func milestone(totalSessions: Int, streak: UserStreak) -> (title: String?, subtitle: String?) {
        switch (streak.currentStreak, totalSessions) {
        case (30..., _):
            return ("Monthly momentum", "You're building the kind of consistency that turns practice into a real habit.")
        case (7..., _):
            return ("Week Warrior", "A full week of practice is a big confidence builder.")
        case (3..., _):
            return ("On a roll", "Three days in a row is real momentum. Keep it going.")
        case (_, 10...):
            return ("Practice Pro", "Ten completed drills is a strong foundation to build on.")
        case (_, 1):
            return ("First drill saved", "You've officially started your speaking streak.")
        default:
            return ("You completed today's drill goal", "Small daily drills like this are what build real speaking confidence.")
        }
    }

    private static func saveConfirmationText(for result: PracticeResult) -> String {
        switch result.processingStatus {
        case .processing:
            return "Saved locally. Your transcript and feedback will keep updating."
        case .localOnly:
            return "Saved locally."
        case .failed:
            return "Saved locally. AI feedback is unavailable right now."
        case .complete:
            return "Saved to your recent drills."
        }
    }
}
