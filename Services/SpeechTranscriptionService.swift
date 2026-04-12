import Foundation
import AVFAudio
import Speech
import CoreMedia

struct SpeechTranscriptionResult {
    let transcript: String
    let segments: [SpeechTranscriptSegment]
    let source: SpeechTranscriptionSource
}

enum SpeechTranscriptionError: Error {
    case recognizerUnavailable
    case localeUnsupported
    case noTranscript
}

protocol SpeechTranscribing {
    func transcribeAudioFile(at url: URL, locale: Locale) async throws -> SpeechTranscriptionResult
}

final class SpeechTranscriptionService: SpeechTranscribing {
    private let legacyTranscriber: SpeechTranscribing

    init(legacyTranscriber: SpeechTranscribing = LegacySpeechRecognizerTranscriber()) {
        self.legacyTranscriber = legacyTranscriber
    }

    func transcribeAudioFile(at url: URL, locale: Locale) async throws -> SpeechTranscriptionResult {
        if #available(iOS 26.0, *) {
            do {
                return try await ModernSpeechAnalyzerTranscriber().transcribeAudioFile(at: url, locale: locale)
            } catch {
                return try await legacyTranscriber.transcribeAudioFile(at: url, locale: locale)
            }
        }

        return try await legacyTranscriber.transcribeAudioFile(at: url, locale: locale)
    }
}

private final class LegacySpeechRecognizerTranscriber: SpeechTranscribing {
    func transcribeAudioFile(at url: URL, locale: Locale) async throws -> SpeechTranscriptionResult {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            var recognitionTask: SFSpeechRecognitionTask?
            var hasResumed = false
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }

                if let error {
                    hasResumed = true
                    recognitionTask?.cancel()
                    continuation.resume(throwing: error)
                    return
                }

                guard let result, result.isFinal else { return }

                let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                let segments = result.bestTranscription.segments.map {
                    SpeechTranscriptSegment(
                        text: $0.substring,
                        startTime: $0.timestamp,
                        duration: $0.duration,
                        confidence: Double($0.confidence)
                    )
                }
                hasResumed = true

                if transcript.isEmpty {
                    continuation.resume(throwing: SpeechTranscriptionError.noTranscript)
                } else {
                    continuation.resume(
                        returning: SpeechTranscriptionResult(
                            transcript: transcript,
                            segments: segments,
                            source: .sfSpeechRecognizer
                        )
                    )
                }
            }
        }
    }
}

@available(iOS 26.0, *)
private final class ModernSpeechAnalyzerTranscriber: SpeechTranscribing {
    func transcribeAudioFile(at url: URL, locale: Locale) async throws -> SpeechTranscriptionResult {
        guard SpeechTranscriber.isAvailable else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }

        guard let supportedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw SpeechTranscriptionError.localeUnsupported
        }

        let transcriber = SpeechTranscriber(
            locale: supportedLocale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: url)

        async let collectedSegments = collectFinalResults(from: transcriber)
        if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
            try await analyzer.finalizeAndFinish(through: lastSample)
        } else {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        let segments = try await collectedSegments

        let transcript = segments
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw SpeechTranscriptionError.noTranscript
        }

        return SpeechTranscriptionResult(
            transcript: transcript,
            segments: segments,
            source: .speechTranscriber
        )
    }

    private func collectFinalResults(from transcriber: SpeechTranscriber) async throws -> [SpeechTranscriptSegment] {
        var segments: [SpeechTranscriptSegment] = []

        for try await result in transcriber.results {
            guard result.isFinal else { continue }

            let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let startTime = max(0, CMTimeGetSeconds(result.range.start))
            let duration = max(0, CMTimeGetSeconds(result.range.duration))
            segments.append(
                SpeechTranscriptSegment(
                    text: text,
                    startTime: startTime.isFinite ? startTime : 0,
                    duration: duration.isFinite ? duration : 0,
                    confidence: nil
                )
            )
        }

        return segments
    }
}
