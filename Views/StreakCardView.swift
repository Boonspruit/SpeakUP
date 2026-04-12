import SwiftUI

struct StreakCardView: View {
    let streak: UserStreak
    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: SUSpacing.lg) {
            HStack(spacing: SUSpacing.md) {
                Text("🔥").font(.system(size: 36)).scaleEffect(flameScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            flameScale = 1.12
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.currentStreak) Day Streak!")
                        .font(SUFont.sectionTitle()).foregroundStyle(.white)
                    Text(streakMessage).font(SUFont.caption()).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(streak.longestStreak)").font(SUFont.cardTitle()).foregroundStyle(.white)
                    Text("Best").font(SUFont.caption()).foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.15)))
            }
            SUWeekCalendar(completions: streak.weeklyCompletions)
        }
        .padding(SUSpacing.xl)
        .background(LinearGradient(colors: [SUColor.streakStart, SUColor.streakEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: SURounding.lg, style: .continuous))
        .shadow(color: SUColor.streakEnd.opacity(0.3), radius: 16, y: 8)
    }

    private var streakMessage: String {
        switch streak.currentStreak {
        case 0: return "Start practicing to build your streak!"
        case 1...2: return "Great start! Keep it going."
        case 3...6: return "You're building momentum!"
        case 7...13: return "Incredible consistency! 🎯"
        default: return "You're unstoppable! 🏆"
        }
    }
}
