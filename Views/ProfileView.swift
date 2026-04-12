import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: PracticeViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var remindersEnabled = true
    @State private var soundsEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SUSpacing.xxl) {
                VStack(spacing: SUSpacing.md) {
                    ZStack {
                        Circle().fill(SUColor.brand.opacity(0.1)).frame(width: 88, height: 88)
                        Image(systemName: "person.fill").font(.system(size: 36, weight: .medium)).foregroundStyle(SUColor.brand)
                    }
                    Text("Speaker").font(SUFont.pageTitle()).foregroundStyle(SUColor.ink)
                    Text("Joined \(Date(), style: .date)").font(SUFont.caption()).foregroundStyle(SUColor.inkSecondary)
                }.frame(maxWidth: .infinity).padding(.top, SUSpacing.lg)

                HStack(spacing: SUSpacing.sm) {
                    SUStatChip(title: "Drills", value: "\(StorageService.shared.sessionCount())", icon: "mic.fill")
                    SUStatChip(title: "Streak", value: "\(viewModel.streak.currentStreak)d", icon: "flame.fill", color: SUColor.accent)
                    SUStatChip(title: "Best", value: "\(viewModel.streak.longestStreak)d", icon: "crown.fill", color: SUColor.success)
                }

                VStack(alignment: .leading, spacing: SUSpacing.md) {
                    Text("Speaking Focus")
                        .font(SUFont.sectionTitle())
                        .foregroundStyle(SUColor.ink)

                    Text("Your featured daily drills are personalized around this track.")
                        .font(SUFont.caption())
                        .foregroundStyle(SUColor.inkSecondary)

                    SUPillSelector(
                        items: viewModel.focusTracks,
                        selected: Binding(
                            get: { viewModel.primaryFocusTrack },
                            set: { viewModel.selectPrimaryFocusTrack($0) }
                        ),
                        label: { $0.label }
                    )
                    .padding(.horizontal, -SUSpacing.xl)
                }
                .padding(SUSpacing.lg)
                .background(SUColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings").font(SUFont.sectionTitle()).foregroundStyle(SUColor.ink).padding(.bottom, SUSpacing.md)
                    settingsRow(icon: "bell.fill", title: "Daily Reminders", color: SUColor.brand) { Toggle("", isOn: $remindersEnabled).tint(SUColor.brand) }
                    Divider().padding(.leading, 52)
                    settingsRow(icon: "speaker.wave.2.fill", title: "Practice Sounds", color: SUColor.accent) { Toggle("", isOn: $soundsEnabled).tint(SUColor.brand) }
                    Divider().padding(.leading, 52)
                    settingsRow(icon: "arrow.counterclockwise", title: "Replay Onboarding", color: SUColor.inkSecondary) {
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(SUColor.inkMuted)
                    }.onTapGesture { hasCompletedOnboarding = false }
                }
                .padding(SUSpacing.lg).background(SUColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)

                VStack(spacing: SUSpacing.md) {
                    HStack(spacing: SUSpacing.md) {
                        Image(systemName: "sparkles").font(.system(size: 24, weight: .medium)).foregroundStyle(SUColor.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SpeakUp Pro").font(SUFont.cardTitle()).foregroundStyle(SUColor.ink)
                            Text("Advanced feedback, drill packs, and more").font(SUFont.caption()).foregroundStyle(SUColor.inkSecondary)
                        }; Spacer()
                    }
                    Button { } label: { Text("Coming Soon") }.buttonStyle(SUSecondaryButtonStyle()).disabled(true).opacity(0.7)
                }.suCard()

                Text("SpeakUp v1.0").font(SUFont.caption()).foregroundStyle(SUColor.inkMuted).padding(.top, SUSpacing.sm)
                Spacer(minLength: 40)
            }.padding(.horizontal, SUSpacing.xl)
        }
        .background(SUColor.background.ignoresSafeArea()).navigationTitle("Profile")
    }

    private func settingsRow<Trailing: View>(icon: String, title: String, color: Color, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: SUSpacing.lg) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color).frame(width: 28)
            Text(title).font(SUFont.body()).foregroundStyle(SUColor.ink); Spacer(); trailing()
        }.padding(.vertical, SUSpacing.md)
    }
}
