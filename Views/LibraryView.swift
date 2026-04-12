import SwiftUI

struct LibraryView: View {
    @ObservedObject var viewModel: PracticeViewModel
    @State private var searchText = ""
    @State private var selectedTrack: FocusTrack? = nil
    @State private var selectedDifficulty: String? = nil

    private var difficulties: [String] {
        Array(Set(viewModel.scripts.map { $0.difficulty })).sorted()
    }

    private var filteredScripts: [Script] {
        var result = viewModel.scripts

        if let selectedTrack {
            result = result.filter { $0.focusTrack == selectedTrack }
        }

        if let selectedDifficulty {
            result = result.filter { $0.difficulty == selectedDifficulty }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.scenario.localizedCaseInsensitiveContains(searchText) ||
                $0.focusTrack.label.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted {
            if $0.focusTrack != $1.focusTrack {
                return $0.focusTrack.rawValue < $1.focusTrack.rawValue
            }
            if $0.source != $1.source {
                return $0.source == .generated
            }
            if $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.title < $1.title
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SUSpacing.lg) {
                generateCard

                HStack(spacing: SUSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(SUColor.inkMuted)
                    TextField("Search drills...", text: $searchText)
                        .font(SUFont.body())
                }
                .padding(SUSpacing.md)
                .background(SUColor.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous))

                filterSection

                if filteredScripts.isEmpty {
                    VStack(spacing: SUSpacing.lg) {
                        Image(systemName: "target")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(SUColor.inkMuted)
                        Text("No drills found")
                            .font(SUFont.cardTitle())
                            .foregroundStyle(SUColor.inkSecondary)
                        Text("Try another track or search term.")
                            .font(SUFont.caption())
                            .foregroundStyle(SUColor.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: SUSpacing.md) {
                        ForEach(filteredScripts) { script in
                            NavigationLink {
                                PracticeSetupView(viewModel: viewModel)
                            } label: {
                                drillCard(script)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                viewModel.prepareDrill(script)
                            })
                            .contextMenu {
                                if script.source == .generated {
                                    Button(role: .destructive) {
                                        viewModel.deleteGeneratedDrill(script)
                                    } label: {
                                        Label("Delete Drill", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, SUSpacing.xl)
            .padding(.top, SUSpacing.md)
        }
        .background(SUColor.background.ignoresSafeArea())
        .navigationTitle("Drill Library")
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
            if selectedTrack == nil {
                selectedTrack = viewModel.primaryFocusTrack
            }
        }
    }

    private var generateCard: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generate A Fresh Drill")
                        .font(SUFont.sectionTitle())
                        .foregroundStyle(SUColor.ink)
                    Text("Create a new drill in your current focus and save it automatically for replay.")
                        .font(SUFont.caption())
                        .foregroundStyle(SUColor.inkSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(SUColor.accent.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .foregroundStyle(SUColor.accent)
                }
            }

            Button {
                Task {
                    _ = await viewModel.generateDrill(
                        focusTrack: selectedTrack ?? viewModel.primaryFocusTrack,
                        difficulty: selectedDifficulty ?? "medium",
                        targetDuration: .sixty
                    )
                }
            } label: {
                HStack(spacing: SUSpacing.sm) {
                    if viewModel.isGeneratingDrill {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(viewModel.isGeneratingDrill ? "Generating..." : "Generate Drill")
                }
            }
            .buttonStyle(SUPrimaryButtonStyle(color: SUColor.accent))
            .disabled(viewModel.isGeneratingDrill)
        }
        .padding(SUSpacing.lg)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Browse By Track")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SUSpacing.sm) {
                    filterPill(label: "All", isSelected: selectedTrack == nil) {
                        selectedTrack = nil
                    }
                    ForEach(FocusTrack.allCases) { track in
                        filterPill(label: track.label, tint: track.color, isSelected: selectedTrack == track) {
                            selectedTrack = track
                        }
                    }
                }
            }

            Text("Difficulty")
                .font(SUFont.captionBold())
                .foregroundStyle(SUColor.inkSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SUSpacing.sm) {
                    filterPill(label: "All", isSelected: selectedDifficulty == nil) {
                        selectedDifficulty = nil
                    }
                    ForEach(difficulties, id: \.self) { difficulty in
                        filterPill(label: difficulty.capitalized, isSelected: selectedDifficulty == difficulty) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }

    private func filterPill(
        label: String,
        tint: Color = SUColor.brand,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(SUFont.captionBold())
                .foregroundStyle(isSelected ? .white : SUColor.ink)
                .padding(.horizontal, SUSpacing.lg)
                .padding(.vertical, SUSpacing.sm)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? tint : SUColor.surfaceAlt)
                )
        }
    }

    private func drillCard(_ script: Script) -> some View {
        HStack(spacing: SUSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous)
                    .fill(script.focusTrack.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: script.focusTrack.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(script.focusTrack.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: SUSpacing.sm) {
                    Text(script.title)
                        .font(SUFont.cardTitle())
                        .foregroundStyle(SUColor.ink)
                        .lineLimit(1)

                    Text(script.source.badgeLabel)
                        .font(SUFont.captionBold())
                        .foregroundStyle(script.source == .generated ? SUColor.accent : SUColor.success)
                        .padding(.horizontal, SUSpacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill((script.source == .generated ? SUColor.accent : SUColor.success).opacity(0.12))
                        )
                }

                Text(script.scenario)
                    .font(SUFont.caption())
                    .foregroundStyle(SUColor.inkSecondary)

                HStack(spacing: SUSpacing.sm) {
                    Text(script.focusTrack.label)
                    Text("•")
                    Text(durationText(for: script.targetDurationSec))
                    Text("•")
                    Text(script.difficulty.capitalized)
                }
                .font(SUFont.caption())
                .foregroundStyle(SUColor.inkSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SUColor.inkMuted)
        }
        .padding(SUSpacing.lg)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func durationText(for seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sec"
        }
        return "\(seconds / 60) min"
    }
}
