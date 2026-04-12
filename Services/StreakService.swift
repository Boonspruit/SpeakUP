import Foundation

/// Manages daily streaks using UserDefaults.
/// Tracks current streak, longest streak, and weekly completion calendar.
final class StreakService {
    static let shared = StreakService()

    private let defaults = UserDefaults.standard
    private let streakKey = "su_user_streak"

    private init() {}

    // MARK: - Public

    func load() -> UserStreak {
        guard let data = defaults.data(forKey: streakKey),
              let streak = try? JSONDecoder().decode(UserStreak.self, from: data)
        else { return .initial }
        return streak
    }

    func recordPractice() -> UserStreak {
        var streak = load()
        let today = Calendar.current.startOfDay(for: Date())

        if let last = streak.lastPracticeDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            if lastDay == today {
                // Already practiced today
                return streak
            }
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                streak.currentStreak += 1
            } else {
                streak.currentStreak = 1
            }
        } else {
            streak.currentStreak = 1
        }

        streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
        streak.lastPracticeDate = today

        // Update weekly completions
        let weekday = Calendar.current.component(.weekday, from: today)
        // Convert to Mon=0 … Sun=6
        let idx = (weekday + 5) % 7
        if idx < streak.weeklyCompletions.count {
            streak.weeklyCompletions[idx] = true
        }

        save(streak)
        return streak
    }

    func resetWeekIfNeeded() -> UserStreak {
        var streak = load()
        // Reset weekly completions every Monday
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 2 { // Monday
            if let last = streak.lastPracticeDate,
               !Calendar.current.isDateInToday(last) {
                streak.weeklyCompletions = Array(repeating: false, count: 7)
                save(streak)
            }
        }
        return streak
    }

    // MARK: - Private

    private func save(_ streak: UserStreak) {
        if let data = try? JSONEncoder().encode(streak) {
            defaults.set(data, forKey: streakKey)
        }
    }
}
