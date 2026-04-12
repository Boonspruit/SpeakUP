import Foundation
import Combine

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var scripts: [Script] = []
    @Published var primaryFocusTrack: FocusTrack = .work
    @Published var selectedDuration: DurationOption = .sixty
    @Published var selectedScript: Script?
    @Published var generatedDrillPreview: Script?
    @Published var isGeneratingDrill = false
    @Published var customText: String = ""

    @Published var practiceState: PracticeState = .setup
    @Published var isPaused = false
    @Published var scrollSpeed: Double = 1.0
    @Published var noteOffset: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var audioLevel: Double = 0
    @Published var captureAuthorizationStatus: SpeechCaptureAuthorizationStatus = .granted

    @Published var latestResult: PracticeResult?
    @Published var latestSession: PracticeSession?
    @Published var streak: UserStreak = .initial
    @Published var selectedTab: Int = 0
    @Published var pendingCompletionDestination: PracticeCompletionDestination?
    @Published var shouldDismissPracticeSetup = false
    @Published var generationErrorMessage: String?

    private let speechPracticeService: SpeechPracticeAnalysisService
    private let drillGenerationService: DrillGenerationService
    private var scrollTimer: AnyCancellable?
    private var sessionTimer: AnyCancellable?
    private var analysisTask: Task<Void, Never>?

    init(
        speechPracticeService: SpeechPracticeAnalysisService = SpeechPracticeAnalysisService(),
        drillGenerationService: DrillGenerationService = DrillGenerationService()
    ) {
        self.speechPracticeService = speechPracticeService
        self.drillGenerationService = drillGenerationService
        self.speechPracticeService.setAudioLevelHandler { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
    }

    func loadData() {
        refreshScripts(preserveSelection: false)
        primaryFocusTrack = StorageService.shared.loadPrimaryFocusTrack()
        selectDefaultScript()
        streak = StreakService.shared.resetWeekIfNeeded()
    }

    func selectDefaultScript() {
        selectedScript = featuredDrill ?? scripts.first
        if let selectedScript {
            selectedDuration = durationOption(for: selectedScript.targetDurationSec)
        }
    }

    func selectPrimaryFocusTrack(_ track: FocusTrack) {
        primaryFocusTrack = track
        StorageService.shared.savePrimaryFocusTrack(track)
        selectDefaultScript()
    }

    func prepareDrill(_ script: Script) {
        selectedScript = script
        selectedDuration = durationOption(for: script.targetDurationSec)
    }

    func deleteGeneratedDrill(_ script: Script) {
        guard script.source == .generated else { return }
        StorageService.shared.deleteGeneratedDrill(id: script.id)

        if generatedDrillPreview?.id == script.id {
            generatedDrillPreview = nil
        }

        let deletedWasSelected = selectedScript?.id == script.id
        refreshScripts(preserveSelection: !deletedWasSelected)
        if deletedWasSelected {
            selectDefaultScript()
        }
    }

    @discardableResult
    func generateDrill(
        focusTrack: FocusTrack? = nil,
        difficulty: String? = nil,
        targetDuration: DurationOption? = nil,
        seedScenario: String? = nil,
        similarTo script: Script? = nil
    ) async -> Script? {
        isGeneratingDrill = true
        generationErrorMessage = nil
        defer { isGeneratingDrill = false }

        let request = DrillGenerationRequest(
            focusTrack: (focusTrack ?? script?.focusTrack ?? primaryFocusTrack).rawValue,
            difficulty: difficulty ?? script?.difficulty ?? "medium",
            targetDurationSec: targetDuration?.rawValue ?? script?.targetDurationSec ?? selectedDuration.rawValue,
            tone: script?.tone ?? "supportive",
            seedScenario: seedScenario ?? script?.scenario,
            similarToDrillID: script?.id,
            similarToDrillTitle: script?.title
        )

        do {
            let generatedDrill = try await drillGenerationService.generateDrill(from: request)
            StorageService.shared.upsertGeneratedDrill(generatedDrill)
            refreshScripts(preserveSelection: false)
            prepareDrill(generatedDrill)
            generatedDrillPreview = generatedDrill
            return generatedDrill
        } catch let error as AIServiceError {
            generationErrorMessage = error.errorDescription
            return nil
        } catch {
            generationErrorMessage = "We couldn't generate a new drill right now. The AI service returned an unexpected error."
            return nil
        }
    }

    // MARK: - Practice Lifecycle

    func startPractice() {
        practiceState = .practicing
        isPaused = false
        noteOffset = 0
        elapsedSeconds = 0
        audioLevel = 0
        pendingCompletionDestination = nil
        shouldDismissPracticeSetup = false
        startAutoScroll()
        startSessionTimer()

        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }
            self.captureAuthorizationStatus = await self.speechPracticeService.startSession()
        }
    }

    func pausePractice() {
        isPaused.toggle()
        practiceState = isPaused ? .paused : .practicing
        if isPaused {
            speechPracticeService.pauseSession()
        } else {
            speechPracticeService.resumeSession()
        }
    }

    func resetPractice() {
        noteOffset = 0
        elapsedSeconds = 0
        isPaused = false
        audioLevel = 0
        practiceState = .practicing
    }

    func completePractice() {
        guard practiceState != .complete else { return }

        stopAutoScroll(); stopSessionTimer()
        practiceState = .complete

        let sessionDuration = max(elapsedSeconds, 1)
        let placeholderResult = makePlaceholderResult(durationSeconds: sessionDuration)
        latestResult = placeholderResult

        let session = PracticeSession(
            drillID: selectedScript?.id ?? UUID().uuidString,
            scriptTitle: selectedScript?.title ?? "Practice",
            focusTrack: selectedScript?.focusTrack ?? primaryFocusTrack,
            mode: selectedScript?.practiceMode ?? primaryFocusTrack.practiceMode,
            result: placeholderResult
        )
        latestSession = session
        StorageService.shared.addSession(session)
        streak = StreakService.shared.recordPractice()
        audioLevel = 0

        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }
            let analysis = await self.speechPracticeService.finishSession(
                durationSeconds: sessionDuration,
                mode: self.selectedScript?.practiceMode ?? self.primaryFocusTrack.practiceMode
            )
            await self.finalizeCompletedSession(
                session,
                durationSeconds: sessionDuration,
                analysis: analysis,
                remoteFeedback: nil,
                isFinalRemotePass: false
            )

            guard let analysis else {
                await self.finalizeCompletedSession(
                    session,
                    durationSeconds: sessionDuration,
                    analysis: nil,
                    remoteFeedback: nil,
                    isFinalRemotePass: true
                )
                return
            }
            let remoteFeedback = await self.speechPracticeService.requestRemoteFeedback(
                for: analysis,
                durationSeconds: sessionDuration,
                mode: self.selectedScript?.practiceMode ?? self.primaryFocusTrack.practiceMode,
                drill: self.selectedScript
            )
            await self.finalizeCompletedSession(
                session,
                durationSeconds: sessionDuration,
                analysis: analysis,
                remoteFeedback: remoteFeedback,
                isFinalRemotePass: true
            )
        }
    }

    func dismissResults() {
        practiceState = .setup
        latestResult = nil
    }

    func abandonPractice() {
        stopAutoScroll()
        stopSessionTimer()
        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }
            await self.speechPracticeService.cancelSession()
        }
        practiceState = .setup
        isPaused = false
        audioLevel = 0
    }

    func queueCompletionDestination(_ destination: PracticeCompletionDestination) {
        pendingCompletionDestination = destination
    }

    func clearCompletionDestination() {
        pendingCompletionDestination = nil
    }

    // MARK: - Auto Scroll

    func startAutoScroll() {
        scrollTimer?.cancel()
        scrollTimer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.isPaused else { return }
                self.noteOffset += self.scrollSpeed
            }
    }

    func resetAutoScroll() { noteOffset = 0; isPaused = false }
    func stopAutoScroll() { scrollTimer?.cancel() }

    func cycleSpeed() {
        let presets: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        if let idx = presets.firstIndex(where: { $0 >= scrollSpeed + 0.01 }) {
            scrollSpeed = presets[idx]
        } else { scrollSpeed = presets[0] }
    }

    // MARK: - Session Timer

    private func startSessionTimer() {
        sessionTimer?.cancel()
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.isPaused else { return }
                self.elapsedSeconds += 1
                if self.elapsedSeconds >= self.selectedDuration.rawValue {
                    self.completePractice()
                }
            }
    }

    private func stopSessionTimer() { sessionTimer?.cancel() }

    // MARK: - Helpers

    var formattedElapsed: String {
        String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var recentSessions: [PracticeSession] {
        StorageService.shared.recentSessions(limit: 5)
    }

    var focusTracks: [FocusTrack] {
        FocusTrack.allCases
    }

    var featuredDrill: Script? {
        let drills = scripts(for: primaryFocusTrack)
        guard !drills.isEmpty else { return scripts.first }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % drills.count
        return drills[index]
    }

    var recommendedDrills: [Script] {
        guard let featuredDrill else { return [] }
        return scripts(for: primaryFocusTrack)
            .filter { $0.id != featuredDrill.id }
            .prefix(3)
            .map { $0 }
    }

    func scripts(for track: FocusTrack) -> [Script] {
        scripts
            .filter { $0.focusTrack == track }
            .sorted { lhs, rhs in
                if lhs.difficulty != rhs.difficulty {
                    return lhs.difficulty < rhs.difficulty
                }
                if lhs.source != rhs.source {
                    return lhs.source == .generated
                }
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.title < rhs.title
            }
    }

    var completionSummary: SpeechCompletionSummary {
        if let latestSession {
            return SpeechCompletionSummary(
                session: latestSession,
                streak: streak,
                totalSessions: StorageService.shared.sessionCount()
            )
        }
        return .mock
    }

    private func finalizeCompletedSession(
        _ session: PracticeSession,
        durationSeconds: Int,
        analysis: SpeechSessionAnalysis?,
        remoteFeedback: PracticeSpeechFeedback?,
        isFinalRemotePass: Bool
    ) {
        guard latestSession?.id == session.id else { return }

        guard let analysis else {
            let failedResult = makeRemoteUnavailableResult(from: session.result)
            let updatedSession = session.updating(result: failedResult)
            latestResult = failedResult
            latestSession = updatedSession
            StorageService.shared.updateSession(updatedSession)
            return
        }

        let fillerWordCount = analysis.metrics.fillerBreakdown.values.reduce(0, +)
        let wordsPerMinute = SpeechPracticeAnalysisService.wordsPerMinute(
            wordCount: analysis.metrics.transcriptWordCount,
            durationSeconds: durationSeconds
        )
        let processingStatus: SpeechProcessingStatus
        if let remoteFeedback {
            processingStatus = .complete
        } else {
            processingStatus = isFinalRemotePass ? .failed : .processing
        }
        let updatedResult = PracticeResult(
            durationSeconds: durationSeconds,
            wordsPerMinute: wordsPerMinute,
            fillerWordCount: fillerWordCount,
            score: remoteFeedback.map { clarityScore(from: $0.claritySummary, wordsPerMinute: wordsPerMinute, fillerWordCount: fillerWordCount) } ?? session.result.score,
            tips: remoteFeedback?.suggestions ?? [],
            transcript: analysis.transcript,
            transcriptSegments: analysis.segments,
            metrics: analysis.metrics,
            feedback: remoteFeedback,
            transcriptionSource: analysis.source,
            processingStatus: processingStatus
        )

        let updatedSession = session.updating(result: updatedResult)
        latestResult = updatedResult
        latestSession = updatedSession
        StorageService.shared.updateSession(updatedSession)
    }

    private func makePlaceholderResult(durationSeconds: Int) -> PracticeResult {
        let fallbackText = currentPracticeText
        let wordCount = fallbackText.split { $0.isWhitespace || $0.isNewline }.count
        let wordsPerMinute = SpeechPracticeAnalysisService.wordsPerMinute(wordCount: wordCount, durationSeconds: durationSeconds)

        return PracticeResult(
            durationSeconds: durationSeconds,
            wordsPerMinute: wordsPerMinute,
            fillerWordCount: 0,
            score: 0,
            tips: [],
            transcript: nil,
            transcriptSegments: [],
            metrics: nil,
            feedback: nil,
            transcriptionSource: .unavailable,
            processingStatus: captureAuthorizationStatus == .granted ? .processing : .failed
        )
    }

    private func makeRemoteUnavailableResult(from result: PracticeResult) -> PracticeResult {
        return PracticeResult(
            durationSeconds: result.durationSeconds,
            wordsPerMinute: result.wordsPerMinute,
            fillerWordCount: result.fillerWordCount,
            score: result.score,
            tips: result.tips,
            transcript: result.transcript,
            transcriptSegments: result.transcriptSegments,
            metrics: result.metrics,
            feedback: nil,
            transcriptionSource: result.transcriptionSource,
            processingStatus: .failed
        )
    }

    private var currentPracticeText: String {
        let scriptText = selectedScript?.fullText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !scriptText.isEmpty {
            return scriptText
        }
        return customText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func refreshScripts(preserveSelection: Bool) {
        let currentSelectedID = preserveSelection ? selectedScript?.id : nil
        let currentPreviewID = generatedDrillPreview?.id
        if !preserveSelection {
            selectedScript = nil
        }
        scripts = StorageService.shared.loadAllDrills()

        if let currentSelectedID,
           let matchedScript = scripts.first(where: { $0.id == currentSelectedID }) {
            selectedScript = matchedScript
        }

        if let currentPreviewID,
           let matchedPreview = scripts.first(where: { $0.id == currentPreviewID }) {
            generatedDrillPreview = matchedPreview
        }
    }

    private func durationOption(for seconds: Int) -> DurationOption {
        DurationOption.allCases.min(by: { abs($0.rawValue - seconds) < abs($1.rawValue - seconds) }) ?? .sixty
    }

    private func clarityScore(from claritySummary: String, wordsPerMinute: Int, fillerWordCount: Int) -> Int {
        var score = 82

        if (115...150).contains(wordsPerMinute) {
            score += 8
        } else if wordsPerMinute > 165 || wordsPerMinute < 95 {
            score -= 8
        }

        score -= min(fillerWordCount * 2, 12)

        switch claritySummary.lowercased() {
        case "strong":
            score += 6
        case "building":
            score -= 4
        default:
            break
        }

        return min(99, max(62, score))
    }
}
