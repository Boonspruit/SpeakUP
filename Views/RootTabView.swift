import SwiftUI

struct RootTabView: View {
    @StateObject private var viewModel = PracticeViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack { HomeView(viewModel: viewModel) }
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            NavigationStack { LibraryView(viewModel: viewModel) }
                .tabItem { Label("Drills", systemImage: "book.closed.fill") }.tag(1)
            NavigationStack { SUProgressView(viewModel: viewModel) }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }.tag(2)
            NavigationStack { ProfileView(viewModel: viewModel) }
                .tabItem { Label("Profile", systemImage: "person.fill") }.tag(3)
        }
        .tint(SUColor.brand)
        .sheet(
            item: Binding(
                get: { viewModel.generatedDrillPreview },
                set: { viewModel.generatedDrillPreview = $0 }
            )
        ) { _ in
            NavigationStack {
                PracticeSetupView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadData()
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.05)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
