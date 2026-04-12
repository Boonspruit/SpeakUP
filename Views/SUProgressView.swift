import SwiftUI

struct SUProgressView: View {
    @ObservedObject var viewModel: PracticeViewModel
    @State private var badges = Badge.allBadges

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SUSpacing.xxl) {
                // Streak hero
                streakHero

                // Weekly stats
                weeklyStats

                // Badges grid
                badgesSection

                // Milestones
                milestonesSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, SUSpacing.xl)
            .padding(.top, SUSpacing.md)
        }
        .background(SUColor.background.ignoresSafeArea())
        .navigationTitle("Progress")
    }

    // MARK: - Streak Hero

    private var streakHero: some View {
        VStack(spacing: SUSpacing.lg) {
            Text("🔥")
                .font(.system(size: 52))

            Text("\(viewModel.streak.currentStreak)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(SUColor.ink)

            Text("Day Streak")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.inkSecondary)

            // Calendar heat map (this week)
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.streak.weeklyCompletions[i]
                                  ? SUColor.success : SUColor.surfaceAlt)
                            .frame(width: 38, height: 38)
                            .overlay {
                                if viewModel.streak.weeklyCompletions[i] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        Text(["M","T","W","T","F","S","S"][i])
                            .font(SUFont.caption())
                            .foregroundStyle(SUColor.inkMuted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SUSpacing.xxl)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.lg, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }

    // MARK: - Weekly Stats

    private var weeklyStats: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("This Week")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            HStack(spacing: SUSpacing.sm) {
                SUStatChip(title: "Drills", value: "\(viewModel.recentSessions.count)", icon: "mic.fill")
                SUStatChip(title: "Total Time", value: totalTime, icon: "clock.fill", color: SUColor.accent)
                SUStatChip(title: "Avg Score", value: avgScore, icon: "star.fill", color: SUColor.success)
            }
        }
    }

    private var totalTime: String {
        let total = viewModel.recentSessions.reduce(0) { $0 + $1.result.durationSeconds }
        return "\(total / 60)m"
    }

    private var avgScore: String {
        let sessions = viewModel.recentSessions
        guard !sessions.isEmpty else { return "—" }
        let avg = sessions.reduce(0) { $0 + $1.result.score } / sessions.count
        return "\(avg)%"
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Badges")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: SUSpacing.md),
                GridItem(.flexible(), spacing: SUSpacing.md),
            ], spacing: SUSpacing.md) {
                ForEach(badges) { badge in
                    VStack(spacing: SUSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(badge.isUnlocked ? SUColor.accent.opacity(0.12) : SUColor.surfaceAlt)
                                .frame(width: 56, height: 56)
                            Image(systemName: badge.iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(badge.isUnlocked ? SUColor.accent : SUColor.inkMuted)
                        }
                        Text(badge.title)
                            .font(SUFont.captionBold())
                            .foregroundStyle(badge.isUnlocked ? SUColor.ink : SUColor.inkMuted)
                        Text(badge.description)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(SUColor.inkSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(SUSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(SUColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
                    .opacity(badge.isUnlocked ? 1 : 0.6)
                }
            }
        }
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: SUSpacing.md) {
            Text("Milestones")
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)

            ForEach(milestones, id: \.title) { ms in
                HStack(spacing: SUSpacing.lg) {
                    Image(systemName: ms.reached ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(ms.reached ? SUColor.success : SUColor.inkMuted)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ms.title)
                            .font(SUFont.cardTitle())
                            .foregroundStyle(ms.reached ? SUColor.ink : SUColor.inkMuted)
                        Text(ms.subtitle)
                            .font(SUFont.caption())
                            .foregroundStyle(SUColor.inkSecondary)
                    }

                    Spacer()
                }
                .padding(SUSpacing.lg)
                .background(SUColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
            }
        }
    }

    private var milestones: [(title: String, subtitle: String, reached: Bool)] {
        let count = StorageService.shared.sessionCount()
        let streak = viewModel.streak.currentStreak
        return [
            ("First Drill", "Complete your first drill", count >= 1),
            ("Getting Warmed Up", "Complete 5 drills", count >= 5),
            ("3-Day Streak", "Practice 3 days in a row", streak >= 3),
            ("Week Warrior", "7-day streak", streak >= 7),
            ("Double Digits", "10 total drills", count >= 10),
            ("Monthly Master", "30-day streak", streak >= 30),
        ]
    }
}
