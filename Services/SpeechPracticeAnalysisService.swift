import Foundation

final class SpeechPracticeAnalysisService {
    private let recordingService: AudioRecordingService
    private let transcriptionService: SpeechTranscribing
    private let feedbackService: SpeechFeedbackService

    private(set) var authorizationStatus: SpeechCaptureAuthorizationStatus = .granted

    init(
        recordingService: AudioRecordingService = AudioRecordingService(),
        transcriptionService: SpeechTranscribing = SpeechTranscriptionService(),
        feedbackService: SpeechFeedbackService = SpeechFeedbackService()
    ) {
        self.recordingService = recordingService
        self.transcriptionService = transcriptionService
        self.feedbackService = feedbackService
    }

    func setAudioLevelHandler(_ handler: ((Double) -> Void)?) {
        recordingService.onAudioLevel = handler
    }

    @discardableResult
    func startSession() async -> SpeechCaptureAuthorizationStatus {
        let permissions = await recordingService.requestPermissions()
        authorizationStatus = permissions

        guard permissions != .microphoneDenied else {
            return permissions
        }

        do {
            try await recordingService.startRecording()
        } catch {
            authorizationStatus = .microphoneDenied
        }

        return authorizationStatus
    }

    func pauseSession() {
        recordingService.pauseRecording()
    }

    func resumeSession() {
        try? recordingService.resumeRecording()
    }

    func cancelSession() async {
        _ = await recordingService.stopRecording()
    }

    func finishSession(durationSeconds: Int, mode _: PracticeMode, locale: Locale = .current) async -> SpeechSessionAnalysis? {
        let audioURL = await recordingService.stopRecording(discardAudio: false)
        defer {
            if let audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }

        guard let audioURL else { return nil }
        guard authorizationStatus != .speechDenied else { return nil }

        do {
            let transcription = try await transcriptionService.transcribeAudioFile(at: audioURL, locale: locale)
            let metrics = Self.makeMetrics(transcript: transcription.transcript, segments: transcription.segments)

            return SpeechSessionAnalysis(
                transcript: transcription.transcript,
                segments: transcription.segments,
                source: transcription.source,
                metrics: metrics
            )
        } catch {
            return nil
        }
    }

    func requestRemoteFeedback(
        for analysis: SpeechSessionAnalysis,
        durationSeconds: Int,
        mode: PracticeMode,
        drill: Script?
    ) async -> PracticeSpeechFeedback? {
        let wordsPerMinute = Self.wordsPerMinute(
            wordCount: analysis.metrics.transcriptWordCount,
            durationSeconds: durationSeconds
        )
        let fillerWordCount = analysis.metrics.fillerBreakdown.values.reduce(0, +)

        return await feedbackService.requestRemoteFeedback(
            SpeechFeedbackRequest(
                transcript: analysis.transcript,
                durationSeconds: durationSeconds,
                wordsPerMinute: wordsPerMinute,
                fillerWordCount: fillerWordCount,
                pauseCount: analysis.metrics.pauseCount,
                averagePauseDuration: analysis.metrics.averagePauseDuration,
                practiceMode: mode.rawValue,
                focusTrack: drill?.focusTrack.rawValue,
                drillTitle: drill?.title,
                drillScenario: drill?.scenario
            )
        )
    }

    static func makeMetrics(transcript: String, segments: [SpeechTranscriptSegment]) -> PracticeSpeechMetrics {
        let normalizedTranscript = transcript.lowercased()
        let fillerTerms = ["um", "uh", "like", "you know", "actually", "basically"]

        let fillerBreakdown = fillerTerms.reduce(into: [String: Int]()) { partialResult, filler in
            partialResult[filler] = countOccurrences(of: filler, in: normalizedTranscript)
        }

        let wordCount = transcript
            .split { $0.isWhitespace || $0.isNewline }
            .count

        let gaps = zip(segments, segments.dropFirst()).compactMap { current, next -> Double? in
            let gap = next.startTime - (current.startTime + current.duration)
            guard gap > 0.45 else { return nil }
            return gap
        }

        let averagePauseDuration = gaps.isEmpty ? 0 : gaps.reduce(0, +) / Double(gaps.count)

        return PracticeSpeechMetrics(
            transcriptWordCount: wordCount,
            pauseCount: gaps.count,
            averagePauseDuration: averagePauseDuration,
            fillerBreakdown: fillerBreakdown.filter { $0.value > 0 }
        )
    }

    static func wordsPerMinute(wordCount: Int, durationSeconds: Int) -> Int {
        guard durationSeconds > 0 else { return 0 }
        return Int((Double(wordCount) / Double(durationSeconds)) * 60)
    }

    private static func countOccurrences(of filler: String, in transcript: String) -> Int {
        guard !transcript.isEmpty else { return 0 }

        let escaped = NSRegularExpression.escapedPattern(for: filler)
        let pattern = filler.contains(" ")
            ? "\\b\(escaped)\\b"
            : "(?<![A-Za-z])\(escaped)(?![A-Za-z])"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return 0
        }

        let range = NSRange(transcript.startIndex..<transcript.endIndex, in: transcript)
        return regex.numberOfMatches(in: transcript, options: [], range: range)
    }
}
