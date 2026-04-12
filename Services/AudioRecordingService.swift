import Foundation
import AVFAudio
import Speech

enum AudioRecordingError: Error {
    case microphonePermissionDenied
    case failedToCreateOutputFile
    case missingInputNode
}

final class AudioRecordingService {
    var onAudioLevel: ((Double) -> Void)?

    private let audioSession = AVAudioSession.sharedInstance()
    private let audioEngine = AVAudioEngine()
    private var outputFile: AVAudioFile?
    private var outputURL: URL?
    private var isTapInstalled = false
    private var isSessionConfigured = false

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        observeAudioNotifications()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func requestPermissions() async -> SpeechCaptureAuthorizationStatus {
        async let microphoneGranted = requestMicrophonePermission()
        async let speechAuthorized = requestSpeechPermission()

        let microphone = await microphoneGranted
        let speech = await speechAuthorized

        if !microphone {
            return .microphoneDenied
        }

        if !speech {
            return .speechDenied
        }

        return .granted
    }

    func startRecording() async throws {
        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else {
            throw AudioRecordingError.microphonePermissionDenied
        }

        try configureAudioSessionIfNeeded()
        try installTapIfNeeded()

        audioEngine.prepare()
        try audioEngine.start()
    }

    func pauseRecording() {
        guard audioEngine.isRunning else { return }
        audioEngine.pause()
    }

    func resumeRecording() throws {
        guard !audioEngine.isRunning else { return }
        try audioEngine.start()
    }

    func stopRecording(discardAudio: Bool = true) async -> URL? {
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        outputFile = nil
        onAudioLevel?(0)

        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Keep teardown resilient for practice completion.
        }

        defer {
            if discardAudio, let outputURL {
                try? FileManager.default.removeItem(at: outputURL)
            }
            if discardAudio {
                self.outputURL = nil
            }
        }

        return outputURL
    }

    private func configureAudioSessionIfNeeded() throws {
        guard !isSessionConfigured else {
            try audioSession.setActive(true)
            return
        }

        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth, .duckOthers]
        )
        try audioSession.setPreferredSampleRate(44_100)
        try audioSession.setPreferredIOBufferDuration(0.02)
        try audioSession.setActive(true)
        isSessionConfigured = true
    }

    private func installTapIfNeeded() throws {
        guard !isTapInstalled else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let url = makeTemporaryAudioURL()
        outputURL = url
        outputFile = try AVAudioFile(forWriting: url, settings: inputFormat.settings)

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                try self.outputFile?.write(from: buffer)
            } catch {
                return
            }

            let level = Self.normalizedPowerLevel(from: buffer)
            DispatchQueue.main.async {
                self.onAudioLevel?(level)
            }
        }

        isTapInstalled = true
    }

    private func observeAudioNotifications() {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }

    @objc
    private func handleInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        if type == .began {
            pauseRecording()
        }
    }

    @objc
    private func handleRouteChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable:
            if !audioEngine.isRunning {
                try? resumeRecording()
            }
        default:
            break
        }
    }

    private func makeTemporaryAudioURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("speakup-session-\(UUID().uuidString)")
            .appendingPathExtension("caf")
    }

    private static func normalizedPowerLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<frameLength {
            let sample = channelDataValue[index]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let normalized = min(max(Double(rms) * 8, 0), 1)
        return normalized
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authorization in
                continuation.resume(returning: authorization == .authorized)
            }
        }
    }
}
