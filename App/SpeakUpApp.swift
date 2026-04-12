import SwiftUI

@main
struct SpeakUpApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

/// Separate View so @AppStorage reactivity works properly
struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
