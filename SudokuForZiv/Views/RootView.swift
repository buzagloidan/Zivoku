import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var activeGames: [ActiveGame]

    @State private var viewModel: GameViewModel? = nil

    var body: some View {
        Group {
            if let vm = viewModel {
                GameView(viewModel: vm, onExit: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel = nil
                    }
                })
                .transition(.opacity)
            } else {
                HomeView(
                    onStartGame: { puzzle, isDaily, date in
                        let vm = GameViewModel()
                        vm.newGame(puzzle: puzzle, isDaily: isDaily, dailyDate: date, context: context)
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel = vm }
                    },
                    onContinue: {
                        guard let saved = activeGames.first else { return }
                        let vm = GameViewModel()
                        vm.load(from: saved, context: context)
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel = vm }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel == nil)
    }
}
