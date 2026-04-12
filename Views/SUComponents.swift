import SwiftUI

// MARK: - Week Calendar (streak dots)

struct SUWeekCalendar: View {
    let completions: [Bool]
    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 6) {
                    Circle()
                        .fill(completions[i] ? SUColor.accent : Color.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if completions[i] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(days[i])
                        .font(SUFont.captionBold())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Score Ring

struct SUScoreRing: View {
    let score: Double  // 0–100
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedScore: Double = 0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(SUColor.surfaceAlt, lineWidth: lineWidth)

            // Fill
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    AngularGradient(
                        colors: [SUColor.brand, SUColor.success, SUColor.brand],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Label
            VStack(spacing: 2) {
                Text("\(Int(animatedScore))")
                    .font(SUFont.bigNumber())
                    .foregroundStyle(SUColor.ink)
                Text("SCORE")
                    .font(SUFont.captionBold())
                    .foregroundStyle(SUColor.inkSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedScore = score
            }
        }
    }
}

// MARK: - Pill Selector

struct SUPillSelector<T: Identifiable & Hashable>: View {
    let items: [T]
    @Binding var selected: T
    let label: (T) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SUSpacing.sm) {
                ForEach(items) { item in
                    Button {
                        withAnimation(SUAnimation.snappy) {
                            selected = item
                        }
                    } label: {
                        Text(label(item))
                            .font(SUFont.captionBold())
                            .foregroundStyle(selected.id == item.id ? .white : SUColor.ink)
                            .padding(.horizontal, SUSpacing.lg)
                            .padding(.vertical, SUSpacing.sm)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected.id == item.id ? SUColor.brand : SUColor.surfaceAlt)
                            )
                    }
                }
            }
            .padding(.horizontal, SUSpacing.xl)
        }
    }
}

// MARK: - Mode Card

struct SUModeCard: View {
    let mode: PracticeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: SUSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: SURounding.md, style: .continuous)
                        .fill(mode.color.opacity(isSelected ? 0.15 : 0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(mode.color)
                }

                Text(mode.label)
                    .font(SUFont.caption())
                    .foregroundStyle(isSelected ? SUColor.ink : SUColor.inkSecondary)
                    .lineLimit(1)
            }
            .frame(width: 80)
            .padding(.vertical, SUSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SURounding.card, style: .continuous)
                    .fill(SUColor.surface)
                    .shadow(color: isSelected ? mode.color.opacity(0.2) : .clear, radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SURounding.card, style: .continuous)
                    .stroke(isSelected ? mode.color : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(SUAnimation.snappy, value: isSelected)
        }
    }
}

// MARK: - Session Card

struct SUSessionCard: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: SUSpacing.lg) {
            // Mode icon
            ZStack {
                RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous)
                    .fill(session.focusTrack.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: session.focusTrack.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(session.focusTrack.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.scriptTitle)
                    .font(SUFont.cardTitle())
                    .foregroundStyle(SUColor.ink)
                    .lineLimit(1)
                HStack(spacing: SUSpacing.sm) {
                    Text(session.focusTrack.label)
                    Text("•")
                    Text(session.result.durationSeconds < 60 ? "\(session.result.durationSeconds) sec" : "\(session.result.durationSeconds / 60) min")
                    Text("•")
                    Text(session.result.feedback?.claritySummary ?? "\(session.result.score)%")
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
}

// MARK: - Stat Chip

struct SUStatChip: View {
    let title: String
    let value: String
    let icon: String?
    var color: Color = SUColor.brand

    var body: some View {
        VStack(spacing: SUSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(SUFont.sectionTitle())
                .foregroundStyle(SUColor.ink)
            Text(title)
                .font(SUFont.caption())
                .foregroundStyle(SUColor.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SUSpacing.lg)
        .background(SUColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
    }
}
