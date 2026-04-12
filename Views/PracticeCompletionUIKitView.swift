import SwiftUI
import UIKit
import Lottie

struct PracticeCompletionUIKitView: UIViewControllerRepresentable {
    let summary: SpeechCompletionSummary
    let streak: UserStreak
    let onPracticeAgain: () -> Void
    let onSaveSession: () -> Void
    let onReviewDrill: () -> Void
    let onGenerateSimilar: () -> Void
    let onBackHome: () -> Void
    let onViewProgress: () -> Void

    func makeUIViewController(context: Context) -> PracticeCompletionViewController {
        PracticeCompletionViewController(
            summary: summary,
            streak: streak,
            onPracticeAgain: onPracticeAgain,
            onSaveSession: onSaveSession,
            onReviewDrill: onReviewDrill,
            onGenerateSimilar: onGenerateSimilar,
            onBackHome: onBackHome,
            onViewProgress: onViewProgress
        )
    }

    func updateUIViewController(_ uiViewController: PracticeCompletionViewController, context: Context) {
        uiViewController.update(
            summary: summary,
            streak: streak
        )
    }
}

final class PracticeCompletionViewController: UIViewController {
    private var summary: SpeechCompletionSummary
    private var streak: UserStreak
    private let onPracticeAgain: () -> Void
    private let onSaveSession: () -> Void
    private let onReviewDrill: () -> Void
    private let onGenerateSimilar: () -> Void
    private let onBackHome: () -> Void
    private let onViewProgress: () -> Void

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let toastLabel = PaddingLabel()

    private let heroCard = GradientCardView()
    private let heroEyebrowLabel = UILabel()
    private let heroTitleLabel = UILabel()
    private let heroSubtitleLabel = UILabel()
    private let lottieCelebrationView = SpeakUpLottieView(animationName: "speakup_fireworks")
    private let savedPillLabel = PaddingLabel()

    private let summaryCard = UIView()
    private let summaryRowsStack = UIStackView()
    private let feedbackCard = UIView()
    private let feedbackStack = UIStackView()
    private let streakCard = UIView()
    private let streakDotsStack = UIStackView()
    private let milestoneCard = UIView()
    private let milestoneTitleLabel = UILabel()
    private let milestoneSubtitleLabel = UILabel()
    private let actionsCard = UIView()
    private let durationValueLabel = UILabel()
    private let paceValueLabel = UILabel()
    private let fillerValueLabel = UILabel()
    private let clarityValueLabel = UILabel()
    private let modePillLabel = PaddingLabel()
    private let datePillLabel = PaddingLabel()
    private let strengthBodyLabel = UILabel()
    private let improveTitleLabel = UILabel()
    private let streakTitleLabel = UILabel()
    private let streakSubtitleLabel = UILabel()

    private let practiceAgainButton = UIButton(type: .system)
    private let saveSessionButton = UIButton(type: .system)
    private let reviewDrillButton = UIButton(type: .system)
    private let generateSimilarButton = UIButton(type: .system)
    private let backHomeButton = UIButton(type: .system)
    private let viewProgressButton = UIButton(type: .system)

    private var hasAnimatedIn = false
    private var hasAcknowledgedSave = false
    private var animatedSections: [UIView] = []

    init(
        summary: SpeechCompletionSummary,
        streak: UserStreak,
        onPracticeAgain: @escaping () -> Void,
        onSaveSession: @escaping () -> Void,
        onReviewDrill: @escaping () -> Void,
        onGenerateSimilar: @escaping () -> Void,
        onBackHome: @escaping () -> Void,
        onViewProgress: @escaping () -> Void
    ) {
        self.summary = summary
        self.streak = streak
        self.onPracticeAgain = onPracticeAgain
        self.onSaveSession = onSaveSession
        self.onReviewDrill = onReviewDrill
        self.onGenerateSimilar = onGenerateSimilar
        self.onBackHome = onBackHome
        self.onViewProgress = onViewProgress
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(SUColor.background)
        setupScrollView()
        setupToast()
        buildSections()
        applyContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        lottieCelebrationView.playOnce()

        for (index, section) in animatedSections.enumerated() {
            section.alpha = 0
            section.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(
                withDuration: 0.45,
                delay: 0.05 * Double(index),
                usingSpringWithDamping: 0.92,
                initialSpringVelocity: 0.2
            ) {
                section.alpha = 1
                section.transform = .identity
            }
        }
    }

    func update(summary: SpeechCompletionSummary, streak: UserStreak) {
        self.summary = summary
        self.streak = streak
        applyContent()
    }

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 18
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36),
        ])
    }

    private func setupToast() {
        toastLabel.backgroundColor = UIColor(SUColor.ink).withAlphaComponent(0.92)
        toastLabel.textColor = .white
        toastLabel.font = .suRounded(size: 14, weight: .semibold)
        toastLabel.layer.cornerRadius = 16
        toastLabel.layer.masksToBounds = true
        toastLabel.alpha = 0
        toastLabel.insets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
        ])
    }

    private func buildSections() {
        stackView.addArrangedSubview(makeHeroSection())
        stackView.addArrangedSubview(makeSummaryCard())
        stackView.addArrangedSubview(makeFeedbackCard())
        stackView.addArrangedSubview(makeStreakCard())
        stackView.addArrangedSubview(makeMilestoneCard())
        stackView.addArrangedSubview(makeActionsCard())

        animatedSections = stackView.arrangedSubviews
    }

    private func makeHeroSection() -> UIView {
        styleCard(heroCard, cornerRadius: 30, shadowOpacity: 0.16, shadowRadius: 24, shadowY: 12)
        heroCard.gradientColors = [
            UIColor(SUColor.brand).cgColor,
            UIColor(SUColor.brandDark).cgColor,
        ]

        let savedPill = savedPillLabel
        savedPill.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        savedPill.textColor = .white
        savedPill.font = .suRounded(size: 13, weight: .bold)
        savedPill.layer.cornerRadius = 14
        savedPill.layer.masksToBounds = true
        savedPill.insets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        savedPill.text = "Drill complete"

        heroEyebrowLabel.font = .suRounded(size: 14, weight: .bold)
        heroEyebrowLabel.textColor = UIColor.white.withAlphaComponent(0.88)

        heroTitleLabel.font = .suRounded(size: 30, weight: .bold)
        heroTitleLabel.textColor = .white
        heroTitleLabel.numberOfLines = 0

        heroSubtitleLabel.font = .suRounded(size: 16, weight: .medium)
        heroSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        heroSubtitleLabel.numberOfLines = 0

        lottieCelebrationView.translatesAutoresizingMaskIntoConstraints = false
        heroCard.addSubview(lottieCelebrationView)

        let textStack = UIStackView(arrangedSubviews: [savedPill, heroEyebrowLabel, heroTitleLabel, heroSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 10
        heroCard.addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heroCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 214),

            lottieCelebrationView.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 12),
            lottieCelebrationView.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -12),
            lottieCelebrationView.widthAnchor.constraint(equalToConstant: 128),
            lottieCelebrationView.heightAnchor.constraint(equalToConstant: 128),

            textStack.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 20),
            textStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 20),
            textStack.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -96),
            textStack.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -22),
        ])

        return heroCard
    }

    private func makeSummaryCard() -> UIView {
        styleCard(summaryCard)
        let stack = makeSectionStack(title: "Drill Summary", subtitle: "A quick look at today's drill.")

        let topRow = UIStackView(arrangedSubviews: [
            makeMetricTile(icon: "clock.fill", title: "Duration", valueLabel: durationValueLabel, tint: UIColor(SUColor.brand)),
            makeMetricTile(icon: "speedometer", title: "Pace", valueLabel: paceValueLabel, tint: UIColor(SUColor.accent)),
        ])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [
            makeMetricTile(icon: "quote.bubble.fill", title: "Fillers", valueLabel: fillerValueLabel, tint: UIColor(SUColor.success)),
            makeMetricTile(icon: "sparkles", title: "Clarity", valueLabel: clarityValueLabel, tint: UIColor(SUColor.brandDark)),
        ])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually

        summaryRowsStack.axis = .vertical
        summaryRowsStack.spacing = 12
        summaryRowsStack.addArrangedSubview(topRow)
        summaryRowsStack.addArrangedSubview(bottomRow)

        let metaRow = UIStackView(arrangedSubviews: [
            makeMetaPill(icon: "mic.fill", label: modePillLabel, tint: UIColor(SUColor.brand)),
            makeMetaPill(icon: "calendar", label: datePillLabel, tint: UIColor(SUColor.accent)),
        ])
        metaRow.axis = .horizontal
        metaRow.spacing = 10
        metaRow.distribution = .fillProportionally

        stack.addArrangedSubview(summaryRowsStack)
        stack.addArrangedSubview(metaRow)
        summaryCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -18),
        ])

        return summaryCard
    }

    private func makeFeedbackCard() -> UIView {
        styleCard(feedbackCard)
        let stack = makeSectionStack(title: "What Went Well", subtitle: "Simple feedback to keep you moving.")

        let strengthView = makeSupportRow(
            icon: "hands.clap.fill",
            iconTint: UIColor(SUColor.accent),
            title: "You did this well",
            bodyLabel: strengthBodyLabel,
            background: UIColor(SUColor.accentLight).withAlphaComponent(0.34)
        )
        stack.addArrangedSubview(strengthView)

        improveTitleLabel.font = .suRounded(size: 15, weight: .bold)
        improveTitleLabel.textColor = UIColor(SUColor.ink)
        improveTitleLabel.text = "Try next"
        stack.addArrangedSubview(improveTitleLabel)

        feedbackStack.axis = .vertical
        feedbackStack.spacing = 10
        for suggestion in summary.improvementSuggestions {
            feedbackStack.addArrangedSubview(
                makeBulletRow(
                    text: suggestion,
                    tint: UIColor(SUColor.brand)
                )
            )
        }
        stack.addArrangedSubview(feedbackStack)

        feedbackCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: feedbackCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: feedbackCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: feedbackCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: feedbackCard.bottomAnchor, constant: -18),
        ])

        return feedbackCard
    }

    private func makeStreakCard() -> UIView {
        styleCard(streakCard, cornerRadius: 26, shadowOpacity: 0.12, shadowRadius: 20, shadowY: 10)
        streakCard.backgroundColor = UIColor(SUColor.surface)

        let iconCircle = UIView()
        iconCircle.backgroundColor = UIColor(SUColor.accentLight).withAlphaComponent(0.55)
        iconCircle.layer.cornerRadius = 24
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconCircle.widthAnchor.constraint(equalToConstant: 48),
            iconCircle.heightAnchor.constraint(equalToConstant: 48),
        ])

        let flame = UIImageView(image: UIImage(systemName: "flame.fill"))
        flame.tintColor = UIColor(SUColor.accent)
        flame.contentMode = .scaleAspectFit
        iconCircle.addSubview(flame)
        flame.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flame.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            flame.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            flame.widthAnchor.constraint(equalToConstant: 22),
            flame.heightAnchor.constraint(equalToConstant: 22),
        ])

        streakTitleLabel.font = .suRounded(size: 20, weight: .bold)
        streakTitleLabel.textColor = UIColor(SUColor.ink)
        streakTitleLabel.numberOfLines = 0

        streakSubtitleLabel.font = .suRounded(size: 15, weight: .medium)
        streakSubtitleLabel.textColor = UIColor(SUColor.inkSecondary)
        streakSubtitleLabel.numberOfLines = 0

        let headerText = UIStackView(arrangedSubviews: [streakTitleLabel, streakSubtitleLabel])
        headerText.axis = .vertical
        headerText.spacing = 4

        let headerRow = UIStackView(arrangedSubviews: [iconCircle, headerText])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 14

        streakDotsStack.axis = .horizontal
        streakDotsStack.spacing = 8
        streakDotsStack.distribution = .fillEqually

        let container = UIStackView(arrangedSubviews: [headerRow, streakDotsStack])
        container.axis = .vertical
        container.spacing = 16
        streakCard.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: streakCard.topAnchor, constant: 18),
            container.leadingAnchor.constraint(equalTo: streakCard.leadingAnchor, constant: 18),
            container.trailingAnchor.constraint(equalTo: streakCard.trailingAnchor, constant: -18),
            container.bottomAnchor.constraint(equalTo: streakCard.bottomAnchor, constant: -18),
        ])

        return streakCard
    }

    private func makeMilestoneCard() -> UIView {
        styleCard(milestoneCard)

        let badgeBubble = UIView()
        badgeBubble.backgroundColor = UIColor(SUColor.brandLight)
        badgeBubble.layer.cornerRadius = 22
        badgeBubble.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeBubble.widthAnchor.constraint(equalToConstant: 44),
            badgeBubble.heightAnchor.constraint(equalToConstant: 44),
        ])

        let badgeIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        badgeIcon.tintColor = UIColor(SUColor.brand)
        badgeBubble.addSubview(badgeIcon)
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeIcon.centerXAnchor.constraint(equalTo: badgeBubble.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badgeBubble.centerYAnchor),
        ])

        milestoneTitleLabel.font = .suRounded(size: 18, weight: .bold)
        milestoneTitleLabel.textColor = UIColor(SUColor.ink)
        milestoneTitleLabel.numberOfLines = 0

        milestoneSubtitleLabel.font = .suRounded(size: 15, weight: .medium)
        milestoneSubtitleLabel.textColor = UIColor(SUColor.inkSecondary)
        milestoneSubtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [milestoneTitleLabel, milestoneSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [badgeBubble, textStack])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center

        milestoneCard.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: milestoneCard.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: milestoneCard.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: milestoneCard.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: milestoneCard.bottomAnchor, constant: -18),
        ])

        return milestoneCard
    }

    private func makeActionsCard() -> UIView {
        styleCard(actionsCard)

        let title = UILabel()
        title.font = .suRounded(size: 18, weight: .bold)
        title.textColor = UIColor(SUColor.ink)
        title.text = "What would you like to do next?"

        configurePrimaryButton(practiceAgainButton, title: "Practice Again", systemImage: "arrow.clockwise")
        configureSecondaryButton(saveSessionButton, title: "Save Session", systemImage: "bookmark.fill")
        configureSecondaryButton(reviewDrillButton, title: "Review Drill", systemImage: "doc.text.magnifyingglass")
        configureSecondaryButton(generateSimilarButton, title: "Generate Similar Drill", systemImage: "sparkles")
        configureTertiaryButton(backHomeButton, title: "Back to Home")
        configureTertiaryButton(viewProgressButton, title: "View Progress")

        practiceAgainButton.addAction(UIAction { [weak self] _ in
            self?.onPracticeAgain()
        }, for: .touchUpInside)

        saveSessionButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onSaveSession()
            self.hasAcknowledgedSave = true
            var config = self.saveSessionButton.configuration
            config?.title = "Saved"
            self.saveSessionButton.configuration = config
            self.savedPillLabel.text = "Saved locally"
            self.showToast(text: self.summary.saveConfirmationText)
        }, for: .touchUpInside)

        reviewDrillButton.addAction(UIAction { [weak self] _ in
            self?.onReviewDrill()
        }, for: .touchUpInside)

        generateSimilarButton.addAction(UIAction { [weak self] _ in
            self?.onGenerateSimilar()
        }, for: .touchUpInside)

        backHomeButton.addAction(UIAction { [weak self] _ in
            self?.onBackHome()
        }, for: .touchUpInside)

        viewProgressButton.addAction(UIAction { [weak self] _ in
            self?.onViewProgress()
        }, for: .touchUpInside)

        let secondaryRow = UIStackView(arrangedSubviews: [saveSessionButton, reviewDrillButton])
        secondaryRow.axis = .horizontal
        secondaryRow.spacing = 12
        secondaryRow.distribution = .fillEqually

        let tertiaryRow = UIStackView(arrangedSubviews: [generateSimilarButton, backHomeButton])
        tertiaryRow.axis = .horizontal
        tertiaryRow.spacing = 12
        tertiaryRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [title, practiceAgainButton, secondaryRow, tertiaryRow, viewProgressButton])
        stack.axis = .vertical
        stack.spacing = 12
        actionsCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: actionsCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: actionsCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: actionsCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: actionsCard.bottomAnchor, constant: -18),
        ])

        return actionsCard
    }

    private func applyContent() {
        heroEyebrowLabel.text = summary.heroEyebrow.uppercased()
        heroTitleLabel.text = summary.heroTitle
        heroSubtitleLabel.text = summary.heroSubtitle
        durationValueLabel.text = summary.durationValue
        paceValueLabel.text = summary.paceValue
        fillerValueLabel.text = summary.fillerValue
        clarityValueLabel.text = summary.clarityValue
        modePillLabel.text = "  \(summary.modeValue)"
        datePillLabel.text = "  \(summary.dateValue)"
        strengthBodyLabel.text = summary.strengthText
        streakTitleLabel.text = summary.streakTitle
        streakSubtitleLabel.text = summary.streakSubtitle

        milestoneTitleLabel.text = summary.milestoneTitle
        milestoneSubtitleLabel.text = summary.milestoneSubtitle
        milestoneCard.isHidden = summary.milestoneTitle == nil

        savedPillLabel.text = hasAcknowledgedSave ? "Saved locally" : "Drill complete"
        var saveConfig = saveSessionButton.configuration
        saveConfig?.title = hasAcknowledgedSave ? "Saved" : "Save Session"
        saveSessionButton.configuration = saveConfig

        rebuildSuggestions()
        improveTitleLabel.isHidden = summary.improvementSuggestions.isEmpty
        feedbackStack.isHidden = summary.improvementSuggestions.isEmpty
        rebuildStreakDots()
    }

    private func rebuildSuggestions() {
        feedbackStack.arrangedSubviews.forEach { view in
            feedbackStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for suggestion in summary.improvementSuggestions {
            feedbackStack.addArrangedSubview(
                makeBulletRow(
                    text: suggestion,
                    tint: UIColor(SUColor.brand)
                )
            )
        }
    }

    private func rebuildStreakDots() {
        streakDotsStack.arrangedSubviews.forEach { view in
            streakDotsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let daySymbols = ["M", "T", "W", "T", "F", "S", "S"]
        for (index, didComplete) in streak.weeklyCompletions.enumerated() {
            let dot = UIView()
            dot.backgroundColor = didComplete ? UIColor(SUColor.accent) : UIColor(SUColor.surfaceAlt)
            dot.layer.cornerRadius = 16
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.heightAnchor.constraint(equalToConstant: 52),
            ])

            let label = UILabel()
            label.font = .suRounded(size: 12, weight: .bold)
            label.textColor = didComplete ? .white : UIColor(SUColor.inkMuted)
            label.textAlignment = .center
            label.text = daySymbols[index]
            dot.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
            ])

            streakDotsStack.addArrangedSubview(dot)
        }
    }

    private func makeMetricTile(icon: String, title: String, valueLabel: UILabel, tint: UIColor) -> UIView {
        let tile = UIView()
        tile.backgroundColor = UIColor(SUColor.surfaceAlt)
        tile.layer.cornerRadius = 20

        let iconBubble = UIView()
        iconBubble.backgroundColor = tint.withAlphaComponent(0.12)
        iconBubble.layer.cornerRadius = 16
        iconBubble.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBubble.widthAnchor.constraint(equalToConstant: 32),
            iconBubble.heightAnchor.constraint(equalToConstant: 32),
        ])

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = tint
        imageView.contentMode = .scaleAspectFit
        iconBubble.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: iconBubble.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconBubble.centerYAnchor),
        ])

        let titleLabel = UILabel()
        titleLabel.font = .suRounded(size: 13, weight: .bold)
        titleLabel.textColor = UIColor(SUColor.inkSecondary)
        titleLabel.text = title

        valueLabel.font = .suRounded(size: 21, weight: .bold)
        valueLabel.textColor = UIColor(SUColor.ink)
        valueLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [iconBubble, titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 8
        tile.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: tile.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -14),
        ])

        return tile
    }

    private func makeMetaPill(icon: String, label: PaddingLabel, tint: UIColor) -> UIView {
        label.font = .suRounded(size: 13, weight: .bold)
        label.textColor = UIColor(SUColor.ink)
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 16
        label.layer.masksToBounds = true
        label.insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 12)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = tint
        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),
        ])
        return label
    }

    private func makeSupportRow(icon: String, iconTint: UIColor, title: String, bodyLabel: UILabel, background: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = background
        container.layer.cornerRadius = 18

        let iconBubble = UIView()
        iconBubble.backgroundColor = .white
        iconBubble.layer.cornerRadius = 18
        iconBubble.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBubble.widthAnchor.constraint(equalToConstant: 36),
            iconBubble.heightAnchor.constraint(equalToConstant: 36),
        ])

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = iconTint
        iconBubble.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: iconBubble.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconBubble.centerYAnchor),
        ])

        let titleLabel = UILabel()
        titleLabel.font = .suRounded(size: 15, weight: .bold)
        titleLabel.textColor = UIColor(SUColor.ink)
        titleLabel.text = title

        bodyLabel.font = .suRounded(size: 15, weight: .medium)
        bodyLabel.textColor = UIColor(SUColor.inkSecondary)
        bodyLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [iconBubble, textStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])

        return container
    }

    private func makeBulletRow(text: String, tint: UIColor) -> UIView {
        let dot = UIView()
        dot.backgroundColor = tint
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
        ])

        let label = UILabel()
        label.font = .suRounded(size: 15, weight: .medium)
        label.textColor = UIColor(SUColor.inkSecondary)
        label.numberOfLines = 0
        label.text = text

        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 10
        return row
    }

    private func makeSectionStack(title: String, subtitle: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.font = .suRounded(size: 19, weight: .bold)
        titleLabel.textColor = UIColor(SUColor.ink)
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .suRounded(size: 14, weight: .medium)
        subtitleLabel.textColor = UIColor(SUColor.inkSecondary)
        subtitleLabel.text = subtitle
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func styleCard(
        _ view: UIView,
        cornerRadius: CGFloat = 26,
        shadowOpacity: Float = 0.08,
        shadowRadius: CGFloat = 18,
        shadowY: CGFloat = 8
    ) {
        view.backgroundColor = UIColor(SUColor.surface)
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowRadius = shadowRadius
        view.layer.shadowOffset = CGSize(width: 0, height: shadowY)
    }

    private func configurePrimaryButton(_ button: UIButton, title: String, systemImage: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor(SUColor.brand)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .suRounded(size: 17, weight: .bold)
            return outgoing
        }
        button.configuration = config
    }

    private func configureSecondaryButton(_ button: UIButton, title: String, systemImage: String) {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 8
        config.baseForegroundColor = UIColor(SUColor.brand)
        config.baseBackgroundColor = UIColor(SUColor.brandLight)
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .suRounded(size: 15, weight: .bold)
            return outgoing
        }
        button.configuration = config
    }

    private func configureTertiaryButton(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = UIColor(SUColor.brandDark)
        config.background.backgroundColor = UIColor.white
        config.background.strokeColor = UIColor(SUColor.brandLight)
        config.background.strokeWidth = 1.5
        config.background.cornerRadius = 20
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .suRounded(size: 15, weight: .bold)
            return outgoing
        }
        button.configuration = config
    }

    private func showToast(text: String) {
        toastLabel.text = text
        UIView.animate(withDuration: 0.2) {
            self.toastLabel.alpha = 1
        }
        UIView.animate(
            withDuration: 0.25,
            delay: 1.6,
            options: [.curveEaseOut]
        ) {
            self.toastLabel.alpha = 0
        }
    }
}

private final class GradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    var gradientColors: [CGColor] = [] {
        didSet {
            gradientLayer.colors = gradientColors
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }
}

private final class SpeakUpLottieView: UIView {
    private let animationView = LottieAnimationView()

    init(animationName: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        animationView.animation = LottieAnimation.named(animationName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func playOnce() {
        animationView.currentProgress = 0
        animationView.play()
    }
}

private final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

private extension UIFont {
    static func suRounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}
