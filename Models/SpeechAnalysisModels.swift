import Foundation

enum SpeechTranscriptionSource: String, Codable {
    case unavailable
    case speechTranscriber
    case sfSpeechRecognizer
    case server
}

enum SpeechProcessingStatus: String, Codable {
    case processing
    case localOnly
    case complete
    case failed
}

enum SpeechCaptureAuthorizationStatus: Equatable {
    case granted
    case microphoneDenied
    case speechDenied
}

enum SpeechFeedbackSource: String, Codable {
    case local
    case remote
}

struct SpeechTranscriptSegment: Codable, Hashable {
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval
    let confidence: Double?
}

struct PracticeSpeechMetrics: Codable {
    let transcriptWordCount: Int
    let pauseCount: Int
    let averagePauseDuration: Double
    let fillerBreakdown: [String: Int]
}

struct PracticeSpeechFeedback: Codable {
    let strength: String
    let suggestions: [String]
    let claritySummary: String
    let source: SpeechFeedbackSource
}

struct SpeechSessionAnalysis {
    let transcript: String
    let segments: [SpeechTranscriptSegment]
    let source: SpeechTranscriptionSource
    let metrics: PracticeSpeechMetrics
}

struct SpeechFeedbackRequest: Codable {
    let transcript: String
    let durationSeconds: Int
    let wordsPerMinute: Int
    let fillerWordCount: Int
    let pauseCount: Int
    let averagePauseDuration: Double
    let practiceMode: String
    let focusTrack: String?
    let drillTitle: String?
    let drillScenario: String?
}

struct SpeechFeedbackResponse: Codable {
    let strength: String
    let suggestions: [String]
    let claritySummary: String
}

struct DrillGenerationRequest: Codable {
    let focusTrack: String
    let difficulty: String
    let targetDurationSec: Int
    let tone: String
    let seedScenario: String?
    let similarToDrillID: String?
    let similarToDrillTitle: String?
}

struct DrillGenerationResponse: Codable {
    let title: String
    let category: String
    let focusTrack: FocusTrack
    let scenario: String
    let difficulty: String
    let targetDurationSec: Int
    let tone: String
    let coachingGoal: String
    let focusHint: String?
    let sections: ScriptSections
}
