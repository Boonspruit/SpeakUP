import SwiftUI

struct PracticeTheaterView: View {
    @ObservedObject var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PracticeTheaterUIKitView(
            text: viewModel.selectedScript?.fullText ?? "No script loaded.",
            offset: viewModel.noteOffset,
            scrollSpeed: viewModel.scrollSpeed,
            isPaused: viewModel.isPaused,
            onClose: {
                viewModel.abandonPractice()
                dismiss()
            },
            onTogglePause: {
                viewModel.pausePractice()
            },
            onCycleSpeed: {
                viewModel.cycleSpeed()
            },
            onRestart: {
                viewModel.resetPractice()
            },
            onFinish: {
                viewModel.completePractice()
            }
        )
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if viewModel.practiceState != .practicing {
                viewModel.startPractice()
            }
        }
        .onDisappear {
            if viewModel.practiceState != .complete {
                viewModel.abandonPractice()
            }
        }
        .fullScreenCover(isPresented: showResults, onDismiss: handleCompletionDismissal) {
            PracticeResultView(viewModel: viewModel)
        }
    }

    private var showResults: Binding<Bool> {
        Binding(
            get: { viewModel.practiceState == .complete },
            set: { if !$0 { viewModel.dismissResults() } }
        )
    }

    private func handleCompletionDismissal() {
        guard let destination = viewModel.pendingCompletionDestination else { return }

        switch destination {
        case .practiceAgain:
            viewModel.clearCompletionDestination()
            viewModel.resetPractice()
            viewModel.startPractice()
        case .reviewDrill:
            viewModel.clearCompletionDestination()
            dismiss()
        case .home:
            viewModel.clearCompletionDestination()
            viewModel.selectedTab = 0
            viewModel.shouldDismissPracticeSetup = true
            dismiss()
        case .progress:
            viewModel.clearCompletionDestination()
            viewModel.selectedTab = 2
            viewModel.shouldDismissPracticeSetup = true
            dismiss()
        }
    }
}

enum PracticePalette {
    static let headerBlue = Color(red: 0.09, green: 0.45, blue: 0.93)
    static let megaYellow = Color(red: 1.0, green: 0.73, blue: 0.13)
    static let screenBackground = Color.white
    static let softBlue = Color(red: 0.88, green: 0.94, blue: 1.0)
    static let seatRed = Color(red: 0.94, green: 0.19, blue: 0.16)
    static let seatShadow = Color(red: 0.80, green: 0.12, blue: 0.12)
    static let coral = Color(red: 0.96, green: 0.30, blue: 0.22)
    static let ink = Color(red: 0.17, green: 0.19, blue: 0.24)
    static let paper = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let paperLine = Color(red: 0.83, green: 0.88, blue: 0.96)
    static let theaterCream = Color(red: 1.0, green: 0.97, blue: 0.89)
    static let sleeveBlue = Color(red: 0.18, green: 0.56, blue: 0.97)
}
