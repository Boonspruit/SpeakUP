import SwiftUI
import UIKit

struct PracticeTheaterUIKitView: UIViewRepresentable {
    let text: String
    let offset: Double
    let scrollSpeed: Double
    let isPaused: Bool
    let onClose: () -> Void
    let onTogglePause: () -> Void
    let onCycleSpeed: () -> Void
    let onRestart: () -> Void
    let onFinish: () -> Void

    func makeUIView(context: Context) -> PracticeScreenUIKitView {
        let view = PracticeScreenUIKitView()
        view.onClose = onClose
        view.onTogglePause = onTogglePause
        view.onCycleSpeed = onCycleSpeed
        view.onRestart = onRestart
        view.onFinish = onFinish
        return view
    }

    func updateUIView(_ uiView: PracticeScreenUIKitView, context: Context) {
        uiView.onClose = onClose
        uiView.onTogglePause = onTogglePause
        uiView.onCycleSpeed = onCycleSpeed
        uiView.onRestart = onRestart
        uiView.onFinish = onFinish
        uiView.render(
            text: text,
            offset: offset,
            scrollSpeed: scrollSpeed,
            isPaused: isPaused
        )
    }
}

final class PracticeScreenUIKitView: UIView {
    var onClose: (() -> Void)?
    var onTogglePause: (() -> Void)?
    var onCycleSpeed: (() -> Void)?
    var onRestart: (() -> Void)?
    var onFinish: (() -> Void)?

    private let closeButton = UIButton(type: .system)
    private let finishButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let speedButton = UIButton(type: .system)
    private let restartButton = UIButton(type: .system)

    private let audienceImageView = UIImageView(image: UIImage(named: "PracticeAudienceIllustration"))
    private let noteSectionView = UIView()
    private let noteImageView = UIImageView(image: UIImage(named: "PracticeNotesFrame"))
    private let textClipView = UIView()
    private let textLabel = UILabel()
    private let textMaskLayer = CAShapeLayer()

    private var currentText = ""
    private var currentOffset: Double = 0
    private var currentSpeed: Double = 1
    private var currentPaused = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(text: String, offset: Double, scrollSpeed: Double, isPaused: Bool) {
        currentText = text
        currentOffset = offset
        currentSpeed = scrollSpeed
        currentPaused = isPaused
        textLabel.text = text
        let pauseImageName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: pauseImageName), for: .normal)
        speedButton.setTitle(String(format: "%.1fx", scrollSpeed), for: .normal)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let safeTop = safeAreaInsets.top
        let boundsWidth = bounds.width
        let boundsHeight = bounds.height
        let topBarY = safeTop + 8

        closeButton.frame = CGRect(x: 18, y: topBarY, width: 40, height: 40)
        finishButton.frame = CGRect(x: closeButton.frame.maxX + 12, y: topBarY, width: 86, height: 40)
        restartButton.frame = CGRect(x: boundsWidth - 18 - 40, y: topBarY, width: 40, height: 40)
        speedButton.frame = CGRect(x: restartButton.frame.minX - 12 - 74, y: topBarY, width: 74, height: 40)
        pauseButton.frame = CGRect(x: speedButton.frame.minX - 12 - 40, y: topBarY, width: 40, height: 40)

        let audienceWidth = min(boundsWidth * 0.86, 380)
        let audienceHeight = audienceWidth * 0.72
        let audienceX = (boundsWidth - audienceWidth) / 2
        let audienceY = closeButton.frame.maxY + 28
        audienceImageView.frame = CGRect(x: audienceX, y: audienceY, width: audienceWidth, height: audienceHeight)

        let noteSectionTop = audienceImageView.frame.maxY + 16
        let noteSectionOverflow: CGFloat = 140
        let noteSectionHeight = max(boundsHeight - noteSectionTop + noteSectionOverflow, 0)
        noteSectionView.frame = CGRect(x: 0, y: noteSectionTop, width: boundsWidth, height: noteSectionHeight)

        let noteImageWidth = min(boundsWidth * 1.52, 700)
        let noteImageX = (noteSectionView.bounds.width - noteImageWidth) / 2
        let noteImageY: CGFloat = -84
        noteImageView.frame = CGRect(x: noteImageX, y: noteImageY, width: noteImageWidth, height: noteImageWidth)

        let paperFrame = CGRect(
            x: noteImageView.frame.minX + noteImageView.frame.width * 0.306,
            y: noteImageView.frame.minY + noteImageView.frame.width * 0.224,
            width: noteImageView.frame.width * 0.368,
            height: min(
                noteImageView.frame.width * 0.50,
                noteSectionView.bounds.height - (noteImageView.frame.minY + noteImageView.frame.width * 0.228) - safeAreaInsets.bottom - 18
            )
        )

        textClipView.frame = paperFrame.integral
        textClipView.layer.cornerRadius = 18
        updateTextMask()

        let textInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        let labelWidth = textClipView.bounds.width - textInsets.left - textInsets.right
        let labelSize = textLabel.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude))
        textLabel.frame = CGRect(
            x: textInsets.left,
            y: textInsets.top - currentOffset,
            width: labelWidth,
            height: max(labelSize.height, textClipView.bounds.height)
        ).integral
    }

    private func setup() {
        audienceImageView.contentMode = .scaleAspectFit
        noteSectionView.backgroundColor = .clear
        noteSectionView.clipsToBounds = true
        noteImageView.contentMode = .scaleAspectFit

        textClipView.clipsToBounds = true
        textClipView.backgroundColor = .clear
        textClipView.layer.mask = textMaskLayer

        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.textColor = UIColor(
            red: 0.17,
            green: 0.19,
            blue: 0.28,
            alpha: 0.92
        )
        textLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        addSubview(audienceImageView)
        addSubview(noteSectionView)
        noteSectionView.addSubview(noteImageView)
        noteSectionView.addSubview(textClipView)
        textClipView.addSubview(textLabel)

        configureCircleButton(closeButton, systemName: "xmark", tint: UIColor(PracticePalette.ink))
        configureFinishButton()
        configureCircleButton(pauseButton, systemName: "pause.fill", tint: UIColor(PracticePalette.headerBlue))
        configureCircleButton(restartButton, systemName: "arrow.counterclockwise", tint: UIColor(PracticePalette.headerBlue))
        configureSpeedButton()

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        speedButton.addTarget(self, action: #selector(speedTapped), for: .touchUpInside)
        restartButton.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
    }

    private func configureCircleButton(_ button: UIButton, systemName: String, tint: UIColor) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: systemName)
        config.baseForegroundColor = tint
        button.configuration = config
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        addSubview(button)
    }

    private func configureFinishButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Finish"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor(PracticePalette.megaYellow)
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .bold)
            return outgoing
        }
        finishButton.configuration = config
        finishButton.layer.cornerRadius = 20
        finishButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        finishButton.layer.shadowOpacity = 1
        finishButton.layer.shadowRadius = 10
        finishButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addSubview(finishButton)
    }

    private func configureSpeedButton() {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = UIColor(PracticePalette.headerBlue)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .bold)
            return outgoing
        }
        speedButton.configuration = config
        speedButton.backgroundColor = .white
        speedButton.layer.cornerRadius = 20
        speedButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        speedButton.layer.shadowOpacity = 1
        speedButton.layer.shadowRadius = 10
        speedButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addSubview(speedButton)
    }

    private func updateTextMask() {
        let bounds = textClipView.bounds
        guard !bounds.isEmpty else { return }

        let margin: CGFloat = 0
        let rect = bounds.insetBy(dx: margin, dy: margin)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)

        textMaskLayer.frame = bounds
        textMaskLayer.path = path.cgPath
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func pauseTapped() {
        onTogglePause?()
    }

    @objc private func speedTapped() {
        onCycleSpeed?()
    }

    @objc private func restartTapped() {
        onRestart?()
    }

    @objc private func finishTapped() {
        onFinish?()
    }
}
