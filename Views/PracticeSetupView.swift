import SwiftUI

struct PracticeSetupView: View {
    @ObservedObject var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    private var drill: Script? {
        viewModel.selectedScript ?? viewModel.featuredDrill
    }

    private var relatedDrills: [Script] {
        guard let drill else { return [] }
        return viewModel.scripts(for: drill.focusTrack)
            .filter { $0.id != drill.id }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SUSpacing.xxl) {
                if let drill {
                    hero(drill)
                    durationSection
                    focusSection(drill)
                    scriptPreview(drill)

                    if drill.source == .generated {
                        generatedActions(drill)
                    }

                    if !relatedDrills.isEmpty {
                        moreFromTrack
                    }

                    NavigationLink {
                        PracticeTheaterView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: SUSpacing.md) {
                            Image(systemName: "play.fill")
                            Text("Start Drill")
                        }
                    }
                    .buttonStyle(SUPrimaryButtonStyle(color: drill.focusTrack.color))
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.prepareDrill(drill)
                    })
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, SUSpacing.xl)
            .padding(.top, SUSpacing.lg)
        }
        .background(SUColor.background.ignoresSafeArea())
        .navigationTitle("Drill Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Couldn't Generate Drill",
            isPresented: Binding(
                get: { viewModel.generationErrorMessage != nil },
                set: { if !$0 { viewModel.generationErrorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    viewModel.generationErrorMessage = nil
                }
            },
            message: {
                Text(viewModel.generationErrorMessage ?? "")
            }
        )
        .onAppear {
            if let drill {
                viewModel.prepareDrill(drill)
            }
            handlePendingExit()
        }
        .onChange(of: viewModel.shouldDismissPracticeSetup) { _, _ in
            handlePendingExit()
        }
    }

    private func hero(_ drill: Script) -> some View {
        VStack(alignment: .leading, spacing: SUSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Drill Details")
                        .font(SUFont.captionBold())
                        .foregroundStyle(drill.focusTrack.color)
                    Text(drill.title)
                        .font(SUFont.pageTitle())
                        .foregroundStyle(SUColor.ink)
                    Text(drill.scenario)
                        .font(SUFont.body())
                        .foregroundStyle(SUColor.inkSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(drill.focusTrack.color.opacity(0.14))
                        .frame(width: 54, height: 54)
                    Image(systemName: drill.focusTrack.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(drill.focusTrack.color)
                }
            }

            Text(drill.coachingGoal)
                .font(SUFont.bodyBold())
                .foregroundStyle(SUColor.ink)

            HStack(spacing: SUSpacing.sm) {
                detailPill(icon: "target", text: drill.focusTrack.label, tint: drill.focusTrack.color)
                detailPill(icon: "clock.fill", text: durationText(for: drill.targetDurationSec), tint: SUColor.accent)
                detailPill(icon: "bolt.fill", text: drill.difficulty.capitalized, tint: SUColor.success)
                detailPill(
                    icon: drill.source == .generated ? "sparkles" : "checkmark.seal.fill",
                    text: drill.source.badgeLabel,
                    tint: drill.source == .generated ? SUColor.accent : SUColor.success
                )
            }
        }
        .padding(SUSpacing.xl)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.lg, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Drill Length")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)
            HStack(spacing: SUSpacing.sm) {
                ForEach(DurationOption.allCases) { duration in
                    Button {
                        viewModel.selectedDuration = duration
                    } label: {
                        Text(duration.label)
                            .font(SUFont.captionBold())
                            .foregroundStyle(viewModel.selectedDuration == duration ? .white : SUColor.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SUSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous)
                                    .fill(viewModel.selectedDuration == duration ? SUColor.brand : SUColor.surfaceAlt)
                            )
                    }
                }
            }
        }
    }

    private func focusSection(_ drill: Script) -> some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("What To Focus On")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            VStack(alignment: .leading, spacing: SUSpacing.sm) {
                Text(drill.focusHint ?? "Keep your pace steady and let each point land clearly.")
                    .font(SUFont.body())
                    .foregroundStyle(SUColor.inkSecondary)

                Text("This drill is designed to help you sound more natural through short, repeatable practice.")
                    .font(SUFont.caption())
                    .foregroundStyle(SUColor.inkMuted)
            }
            .suCard()
        }
    }

    private func scriptPreview(_ drill: Script) -> some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            HStack {
                Text("Drill Script")
                    .font(SUFont.sectionTitle())
                    .foregroundStyle(SUColor.ink)
                Spacer()
                Text("\(drill.fullText.split { $0.isWhitespace || $0.isNewline }.count) words")
                    .font(SUFont.caption())
                    .foregroundStyle(SUColor.inkSecondary)
            }

            VStack(alignment: .leading, spacing: SUSpacing.md) {
                previewSection(title: "Opening", text: drill.sections.opening)
                previewSection(title: "Middle", text: [drill.sections.point1, drill.sections.point2, drill.sections.point3].joined(separator: " "))
                previewSection(title: "Closing", text: drill.sections.closing)
            }
            .suCard()
        }
    }

    private var moreFromTrack: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("More In This Track")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            ForEach(relatedDrills) { drill in
                Button {
                    withAnimation(SUAnimation.snappy) {
                        viewModel.prepareDrill(drill)
                    }
                } label: {
                    HStack(spacing: SUSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous)
                                .fill(drill.focusTrack.color.opacity(0.12))
                                .frame(width: 42, height: 42)
                            Image(systemName: drill.focusTrack.icon)
                                .foregroundStyle(drill.focusTrack.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(drill.title)
                                .font(SUFont.cardTitle())
                                .foregroundStyle(SUColor.ink)
                            Text(drill.scenario)
                                .font(SUFont.caption())
                                .foregroundStyle(SUColor.inkSecondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SUColor.inkMuted)
                    }
                    .padding(SUSpacing.lg)
                    .background(SUColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
                }
            }
        }
    }

    private func generatedActions(_ drill: Script) -> some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Generated Drill")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            VStack(alignment: .leading, spacing: SUSpacing.md) {
                Text("This drill was generated for replay and can be removed anytime.")
                    .font(SUFont.caption())
                    .foregroundStyle(SUColor.inkSecondary)

                Button {
                    Task {
                        _ = await viewModel.generateDrill(
                            focusTrack: drill.focusTrack,
                            difficulty: drill.difficulty,
                            targetDuration: durationOption(from: drill.targetDurationSec),
                            seedScenario: drill.scenario,
                            similarTo: drill
                        )
                    }
                } label: {
                    HStack(spacing: SUSpacing.sm) {
                        if viewModel.isGeneratingDrill {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.isGeneratingDrill ? "Generating..." : "Generate Another")
                    }
                }
                .buttonStyle(SUPrimaryButtonStyle(color: SUColor.accent))
                .disabled(viewModel.isGeneratingDrill)

                Button(role: .destructive) {
                    viewModel.deleteGeneratedDrill(drill)
                    dismiss()
                } label: {
                    HStack(spacing: SUSpacing.sm) {
                        Image(systemName: "trash")
                        Text("Delete This Drill")
                    }
                }
                .buttonStyle(SUGhostButtonStyle())
            }
            .suCard()
        }
    }

    private func previewSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SUFont.captionBold())
                .foregroundStyle(SUColor.inkSecondary)
            Text(text)
                .font(SUFont.body())
                .foregroundStyle(SUColor.ink)
        }
    }

    private func detailPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(SUFont.captionBold())
        .foregroundStyle(SUColor.ink)
        .padding(.horizontal, SUSpacing.md)
        .padding(.vertical, SUSpacing.sm)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private func durationText(for seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sec"
        }
        return "\(seconds / 60) min"
    }

    private func durationOption(from seconds: Int) -> DurationOption {
        DurationOption.allCases.min(by: { abs($0.rawValue - seconds) < abs($1.rawValue - seconds) }) ?? .sixty
    }

    private func handlePendingExit() {
        guard viewModel.shouldDismissPracticeSetup else { return }
        viewModel.shouldDismissPracticeSetup = false
        dismiss()
    }
}
