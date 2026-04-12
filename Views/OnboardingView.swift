import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    @AppStorage("su_primary_focus_track") private var storedFocusTrack = FocusTrack.work.rawValue
    @State private var currentPage = 0
    @State private var selectedTrack: FocusTrack = .work

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            "person.and.background.dotted",
            "Daily Speaking Drills",
            "Build confidence with short guided drills you can finish in under two minutes.",
            SUColor.brand
        ),
        (
            "target",
            "Practice Real-Life Moments",
            "Rehearse everyday scenarios like updates, interviews, intros, class talks, and short stories.",
            SUColor.accent
        ),
        (
            "flame.fill",
            "Keep Your Streak Alive",
            "Show up for one drill a day and build speaking confidence through consistency.",
            SUColor.success
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
                focusSelectionPage
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: SUSpacing.xl) {
                HStack(spacing: 8) {
                    ForEach(0...pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? SUColor.brand : SUColor.inkMuted.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(SUAnimation.snappy, value: currentPage)
                    }
                }

                Button {
                    if currentPage < pages.count {
                        withAnimation(SUAnimation.snappy) {
                            currentPage += 1
                        }
                    } else {
                        storedFocusTrack = selectedTrack.rawValue
                        withAnimation {
                            hasCompleted = true
                        }
                    }
                } label: {
                    Text(currentPage == pages.count ? "Start My Drills" : "Continue")
                }
                .buttonStyle(SUPrimaryButtonStyle(color: currentPage == pages.count ? selectedTrack.color : pages[currentPage].color))
                .padding(.horizontal, SUSpacing.xxl)

                if currentPage < pages.count {
                    Button("Skip") {
                        storedFocusTrack = selectedTrack.rawValue
                        withAnimation { hasCompleted = true }
                    }
                    .font(SUFont.bodyBold())
                    .foregroundStyle(SUColor.inkSecondary)
                }
            }
            .padding(.bottom, 40)
        }
        .background(SUColor.background.ignoresSafeArea())
    }

    private func onboardingPage(_ page: (icon: String, title: String, subtitle: String, color: Color)) -> some View {
        VStack(spacing: SUSpacing.xxxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.10))
                    .frame(width: 200, height: 200)
                Circle()
                    .fill(page.color.opacity(0.06))
                    .frame(width: 260, height: 260)
                Image(systemName: page.icon)
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(page.color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: SUSpacing.md) {
                Text(page.title)
                    .font(SUFont.heroTitle())
                    .foregroundStyle(SUColor.ink)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(SUFont.body())
                    .foregroundStyle(SUColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SUSpacing.xxl)
            }

            Spacer()
            Spacer()
        }
    }

    private var focusSelectionPage: some View {
        VStack(spacing: SUSpacing.xl) {
            Spacer()

            VStack(spacing: SUSpacing.sm) {
                Text("Choose Your Focus")
                    .font(SUFont.heroTitle())
                    .foregroundStyle(SUColor.ink)
                    .multilineTextAlignment(.center)
                Text("We'll feature daily drills based on what you want to get better at speaking for.")
                    .font(SUFont.body())
                    .foregroundStyle(SUColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SUSpacing.xxl)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SUSpacing.md) {
                ForEach(FocusTrack.allCases) { track in
                    Button {
                        selectedTrack = track
                    } label: {
                        VStack(alignment: .leading, spacing: SUSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(track.color.opacity(0.14))
                                    .frame(width: 48, height: 48)
                                Image(systemName: track.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(track.color)
                            }

                            Text(track.label)
                                .font(SUFont.cardTitle())
                                .foregroundStyle(SUColor.ink)
                            Text(track.subtitle)
                                .font(SUFont.caption())
                                .foregroundStyle(SUColor.inkSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(SUSpacing.lg)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                        .background(SUColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: SURounding.card, style: .continuous)
                                .stroke(selectedTrack == track ? track.color : .clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, SUSpacing.xl)

            Spacer()
        }
        .onAppear {
            selectedTrack = FocusTrack(rawValue: storedFocusTrack) ?? .work
        }
    }
}
