import SwiftUI

struct PracticeResultView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        PracticeCompletionUIKitView(
            summary: viewModel.completionSummary,
            streak: viewModel.streak,
            onPracticeAgain: {
                viewModel.queueCompletionDestination(.practiceAgain)
                viewModel.dismissResults()
            },
            onSaveSession: { },
            onReviewDrill: {
                viewModel.queueCompletionDestination(.reviewDrill)
                viewModel.dismissResults()
            },
            onGenerateSimilar: {
                Task {
                    if await viewModel.generateDrill(similarTo: viewModel.selectedScript) != nil {
                        viewModel.queueCompletionDestination(.reviewDrill)
                        viewModel.dismissResults()
                    }
                }
            },
            onBackHome: {
                viewModel.queueCompletionDestination(.home)
                viewModel.dismissResults()
            },
            onViewProgress: {
                viewModel.queueCompletionDestination(.progress)
                viewModel.dismissResults()
            }
        )
        .background(SUColor.background.ignoresSafeArea())
        .ignoresSafeArea()
        .interactiveDismissDisabled()
    }
}
