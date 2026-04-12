import Foundation

struct AIBackendErrorResponse: Decodable {
    let error: String
    let code: String?
    let userMessage: String?
    let retryable: Bool?
    let detail: String?
}

enum AIServiceError: LocalizedError {
    case backend(message: String)
    case decoding
    case unavailable

    var errorDescription: String? {
        switch self {
        case let .backend(message):
            return message
        case .decoding:
            return "The backend returned an unexpected response. Check the server logs and try again."
        case .unavailable:
            return "The AI service is unavailable right now. Please try again shortly."
        }
    }
}

final class SpeechFeedbackService {
    private let session: URLSession
    private let endpointURL: URL?

    init(session: URLSession = .shared, endpointURL: URL? = SpeechFeedbackService.defaultEndpointURL()) {
        self.session = session
        self.endpointURL = endpointURL
    }

    func generateLocalFeedback(
        metrics: PracticeSpeechMetrics,
        durationSeconds: Int,
        wordsPerMinute: Int,
        fillerWordCount: Int
    ) -> PracticeSpeechFeedback {
        let strength: String
        if (115...150).contains(wordsPerMinute) {
            strength = "You kept a steady pace through most of your speech, which made your delivery easy to follow."
        } else if fillerWordCount <= 2 {
            strength = "Your delivery felt clean and composed, with very few filler words pulling attention away from your points."
        } else if metrics.pauseCount >= 3 {
            strength = "You gave your ideas room to land, and those pauses helped your speech feel more intentional."
        } else {
            strength = "You finished the full session, and that kind of consistency is exactly how strong speaking habits are built."
        }

        var suggestions: [String] = []
        if wordsPerMinute > 155 {
            suggestions.append("Try slowing down a little during your key points so your audience has more time to absorb them.")
        } else if wordsPerMinute < 105 {
            suggestions.append("You can pick up the pace slightly in the middle of your speech to keep your momentum moving.")
        } else {
            suggestions.append("Consider adding a brief pause before each new section to make your transitions feel even clearer.")
        }

        if fillerWordCount >= 4 {
            suggestions.append("A steady breath before you begin a new thought can help cut down on filler words without sounding stiff.")
        } else if metrics.averagePauseDuration < 0.45 && durationSeconds >= 90 {
            suggestions.append("Try letting your pauses last just a little longer so your strongest lines have more space.")
        }

        if suggestions.isEmpty {
            suggestions.append("Keep repeating this session a few more times to make your pacing feel even more natural.")
        }

        let claritySummary: String
        switch fillerWordCount {
        case ..<2:
            claritySummary = "Strong"
        case 2...4:
            claritySummary = "Steady"
        default:
            claritySummary = "Building"
        }

        return PracticeSpeechFeedback(
            strength: strength,
            suggestions: Array(suggestions.prefix(2)),
            claritySummary: claritySummary,
            source: .local
        )
    }

    func requestRemoteFeedback(_ requestBody: SpeechFeedbackRequest) async throws -> PracticeSpeechFeedback {
        guard let endpointURL else { throw AIServiceError.unavailable }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.unavailable
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw Self.decodeBackendError(from: data)
            }

            let feedbackResponse = try JSONDecoder().decode(SpeechFeedbackResponse.self, from: data)
            return PracticeSpeechFeedback(
                strength: feedbackResponse.strength,
                suggestions: Array(feedbackResponse.suggestions.prefix(2)),
                claritySummary: feedbackResponse.claritySummary,
                source: .remote
            )
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.unavailable
        }
    }

    private static func defaultEndpointURL() -> URL? {
        guard
            let endpoint = Bundle.main.object(forInfoDictionaryKey: "SpeakUpFeedbackEndpoint") as? String,
            !endpoint.isEmpty
        else {
            return nil
        }

        return URL(string: endpoint)
    }
}

final class DrillGenerationService {
    private let session: URLSession
    private let endpointURL: URL?

    init(session: URLSession = .shared, endpointURL: URL? = DrillGenerationService.defaultEndpointURL()) {
        self.session = session
        self.endpointURL = endpointURL
    }

    func generateDrill(from requestBody: DrillGenerationRequest) async throws -> Script {
        guard let endpointURL else { throw AIServiceError.unavailable }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.unavailable
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw SpeechFeedbackService.decodeBackendError(from: data)
            }

            let responseBody = try JSONDecoder().decode(DrillGenerationResponse.self, from: data)
            return makeGeneratedScript(from: responseBody, requestBody: requestBody)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.unavailable
        }
    }

    private func makeGeneratedScript(from response: DrillGenerationResponse, requestBody: DrillGenerationRequest) -> Script {
        let now = Date()
        return Script(
            id: UUID().uuidString,
            title: response.title,
            category: response.category,
            scenario: response.scenario,
            focusTrack: response.focusTrack,
            difficulty: response.difficulty,
            targetDurationSec: response.targetDurationSec,
            tone: response.tone,
            coachingGoal: response.coachingGoal,
            focusHint: response.focusHint,
            sections: response.sections,
            source: .generated,
            generatedAt: now,
            originDrillID: requestBody.similarToDrillID,
            createdAt: now
        )
    }

    private static func defaultEndpointURL() -> URL? {
        guard
            let endpoint = Bundle.main.object(forInfoDictionaryKey: "SpeakUpDrillGenerationEndpoint") as? String,
            !endpoint.isEmpty
        else {
            return nil
        }

        return URL(string: endpoint)
    }
}

private extension SpeechFeedbackService {
    static func decodeBackendError(from data: Data) -> AIServiceError {
        if let backendError = try? JSONDecoder().decode(AIBackendErrorResponse.self, from: data) {
            return .backend(message: backendError.userMessage ?? backendError.error)
        }
        return .decoding
    }
}
