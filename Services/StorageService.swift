import Foundation

/// Local persistence for scripts and sessions.
/// Uses UserDefaults for MVP; interface is designed to swap to SwiftData later.
final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let userScriptsKey = "su_user_scripts"
    private let generatedDrillsKey = "su_generated_drills"
    private let sessionsKey = "su_practice_sessions"
    private let primaryFocusTrackKey = "su_primary_focus_track"

    private init() {}

    // MARK: - Scripts

    func loadUserScripts() -> [Script] {
        guard let data = defaults.data(forKey: userScriptsKey),
              let scripts = try? JSONDecoder().decode([Script].self, from: data)
        else { return [] }
        return scripts
    }

    func saveUserScripts(_ scripts: [Script]) {
        if let data = try? JSONEncoder().encode(scripts) {
            defaults.set(data, forKey: userScriptsKey)
        }
    }

    func addScript(_ script: Script) {
        var scripts = loadUserScripts()
        scripts.insert(script, at: 0)
        saveUserScripts(scripts)
    }

    func deleteScript(id: String) {
        var scripts = loadUserScripts()
        scripts.removeAll { $0.id == id }
        saveUserScripts(scripts)
    }

    func togglePin(id: String) {
        var scripts = loadUserScripts()
        if let idx = scripts.firstIndex(where: { $0.id == id }) {
            scripts[idx].isPinned.toggle()
            saveUserScripts(scripts)
        }
    }

    func loadGeneratedDrills() -> [Script] {
        guard let data = defaults.data(forKey: generatedDrillsKey),
              let scripts = try? JSONDecoder().decode([Script].self, from: data)
        else { return [] }
        return scripts
    }

    func saveGeneratedDrills(_ scripts: [Script]) {
        if let data = try? JSONEncoder().encode(scripts) {
            defaults.set(data, forKey: generatedDrillsKey)
        }
    }

    func upsertGeneratedDrill(_ script: Script) {
        var scripts = loadGeneratedDrills()
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.insert(script, at: 0)
        }
        saveGeneratedDrills(scripts)
    }

    func deleteGeneratedDrill(id: String) {
        var scripts = loadGeneratedDrills()
        scripts.removeAll { $0.id == id }
        saveGeneratedDrills(scripts)
    }

    func loadAllDrills() -> [Script] {
        let curated = loadSeedScripts()
        let generated = loadGeneratedDrills()
        var mergedByID: [String: Script] = [:]

        for script in curated {
            mergedByID[script.id] = script
        }

        for script in generated {
            mergedByID[script.id] = script
        }

        return mergedByID.values.sorted { lhs, rhs in
            if lhs.source != rhs.source {
                return lhs.source == .generated
            }
            if lhs.focusTrack != rhs.focusTrack {
                return lhs.focusTrack.rawValue < rhs.focusTrack.rawValue
            }
            if lhs.difficulty != rhs.difficulty {
                return lhs.difficulty < rhs.difficulty
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.title < rhs.title
        }
    }

    // MARK: - Sessions

    func loadSessions() -> [PracticeSession] {
        guard let data = defaults.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([PracticeSession].self, from: data)
        else { return [] }
        return sessions
    }

    func saveSessions(_ sessions: [PracticeSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: sessionsKey)
        }
    }

    func addSession(_ session: PracticeSession) {
        var sessions = loadSessions()
        sessions.insert(session, at: 0)
        // Keep last 100 sessions
        if sessions.count > 100 { sessions = Array(sessions.prefix(100)) }
        saveSessions(sessions)
    }

    func updateSession(_ session: PracticeSession) {
        var sessions = loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        if sessions.count > 100 { sessions = Array(sessions.prefix(100)) }
        saveSessions(sessions)
    }

    func sessionCount() -> Int {
        loadSessions().count
    }

    func recentSessions(limit: Int = 5) -> [PracticeSession] {
        Array(loadSessions().prefix(limit))
    }

    // MARK: - Preferences

    func loadPrimaryFocusTrack() -> FocusTrack {
        guard
            let rawValue = defaults.string(forKey: primaryFocusTrackKey),
            let track = FocusTrack(rawValue: rawValue)
        else {
            return .work
        }
        return track
    }

    func savePrimaryFocusTrack(_ track: FocusTrack) {
        defaults.set(track.rawValue, forKey: primaryFocusTrackKey)
    }

    // MARK: - Seed Scripts

    func loadSeedScripts() -> [Script] {
        guard let url = Bundle.main.url(forResource: "SeedScripts", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ScriptSeedResponse.self, from: data).scripts
        } catch {
            print("Failed loading seed scripts: \(error)")
            return []
        }
    }
}
