import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SUSpacing.xl) {
                header
                    .padding(.horizontal, SUSpacing.xl)

                focusPicker

                if let featuredDrill = viewModel.featuredDrill {
                    todayDrillCard(featuredDrill)
                        .padding(.horizontal, SUSpacing.xl)
                }

                StreakCardView(streak: viewModel.streak)
                    .padding(.horizontal, SUSpacing.xl)

                if !viewModel.recommendedDrills.isEmpty {
                    moreForYou
                }

                if !viewModel.recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: SUSpacing.md) {
                        Text("Recent Drills")
                            .font(SUFont.sectionTitle())
                            .foregroundStyle(SUColor.ink)
                        ForEach(viewModel.recentSessions) { session in
                            SUSessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, SUSpacing.xl)
                }

                weeklyProgress
                    .padding(.horizontal, SUSpacing.xl)

                Spacer(minLength: 40)
            }
            .padding(.top, SUSpacing.sm)
        }
        .background(SUColor.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SpeakUp")
                    .font(SUFont.heroTitle())
                    .foregroundStyle(SUColor.ink)
                Text("Daily speaking drills for real-life confidence")
                    .font(SUFont.caption())
                    .foregroundStyle(SUColor.inkSecondary)
            }
            Spacer()
            Button { } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SUColor.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(SUColor.surfaceAlt)
                    .clipShape(Circle())
            }
        }
    }

    private var focusPicker: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Your Focus")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)
                .padding(.horizontal, SUSpacing.xl)

            SUPillSelector(
                items: viewModel.focusTracks,
                selected: Binding(
                    get: { viewModel.primaryFocusTrack },
                    set: { viewModel.selectPrimaryFocusTrack($0) }
                ),
                label: { $0.label }
            )
        }
    }

    private func todayDrillCard(_ drill: Script) -> some View {
        VStack(alignment: .leading, spacing: SUSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Drill")
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
                        .frame(width: 56, height: 56)
                    Image(systemName: drill.focusTrack.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(drill.focusTrack.color)
                }
            }

            Text(drill.coachingGoal)
                .font(SUFont.bodyBold())
                .foregroundStyle(SUColor.ink)

            HStack(spacing: SUSpacing.sm) {
                featuredPill(text: drill.focusTrack.label, icon: "target", tint: drill.focusTrack.color)
                featuredPill(text: durationText(for: drill.targetDurationSec), icon: "clock.fill", tint: SUColor.accent)
                featuredPill(text: drill.difficulty.capitalized, icon: "bolt.fill", tint: SUColor.success)
                featuredPill(
                    text: drill.source.badgeLabel,
                    icon: drill.source == .generated ? "sparkles" : "checkmark.seal.fill",
                    tint: drill.source == .generated ? SUColor.accent : SUColor.success
                )
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

            NavigationLink {
                PracticeSetupView(viewModel: viewModel)
            } label: {
                Text("See Drill Details")
            }
            .buttonStyle(SUGhostButtonStyle())
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.prepareDrill(drill)
            })
        }
        .padding(SUSpacing.xl)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.lg, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }

    private var moreForYou: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            HStack {
                Text("More For You")
                    .font(SUFont.sectionTitle())
                    .foregroundStyle(SUColor.ink)
                Spacer()
                Button("Browse Library") {
                    viewModel.selectedTab = 1
                }
                .font(SUFont.captionBold())
                .foregroundStyle(SUColor.brand)
            }
            .padding(.horizontal, SUSpacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SUSpacing.md) {
                    ForEach(viewModel.recommendedDrills) { drill in
                        NavigationLink {
                            PracticeSetupView(viewModel: viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: SUSpacing.md) {
                                HStack {
                                    Image(systemName: drill.focusTrack.icon)
                                        .foregroundStyle(drill.focusTrack.color)
                                    Spacer()
                                    Text(durationText(for: drill.targetDurationSec))
                                        .font(SUFont.captionBold())
                                        .foregroundStyle(SUColor.inkSecondary)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(drill.title)
                                        .font(SUFont.cardTitle())
                                        .foregroundStyle(SUColor.ink)
                                        .multilineTextAlignment(.leading)
                                    Text(drill.scenario)
                                        .font(SUFont.caption())
                                        .foregroundStyle(SUColor.inkSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(SUSpacing.lg)
                            .frame(width: 220, alignment: .leading)
                            .background(SUColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            viewModel.prepareDrill(drill)
                        })
                    }
                }
                .padding(.horizontal, SUSpacing.xl)
            }
        }
    }

    private var weeklyProgress: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("This Week")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)
            HStack(spacing: SUSpacing.xs) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(viewModel.streak.weeklyCompletions[index] ? SUColor.brand : SUColor.surfaceAlt)
                        .frame(height: 36)
                }
            }
            let count = viewModel.streak.weeklyCompletions.filter { $0 }.count
            Text("\(count) of 7 days completed")
                .font(SUFont.caption())
                .foregroundStyle(SUColor.inkSecondary)
        }
        .padding(SUSpacing.lg)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func featuredPill(text: String, icon: String, tint: Color) -> some View {
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
}
