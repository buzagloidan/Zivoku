import SwiftUI

struct CellView: View {
    let index: Int
    let cellSize: CGFloat
    let viewModel: GameViewModel

    private var given: Int { viewModel.givens[index] }
    private var player: Int { viewModel.playerValues[index] }
    private var value: Int { given != 0 ? given : player }
    private var marks: [Int] { viewModel.pencilMarks[index] }
    private var highlight: CellHighlight { viewModel.highlightState(for: index) }
    private var isMistake: Bool { viewModel.isMistake(at: index) }

    var body: some View {
        ZStack {
            Rectangle().fill(backgroundColor)
            if value != 0 {
                digitView
            } else if !marks.isEmpty {
                pencilView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.selectCell(index) }
    }

    private var digitView: some View {
        Text(String(value))
            .font(Theme.rounded(cellSize * 0.54, weight: given != 0 ? .semibold : .regular))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pencilView: some View {
        let miniCell = cellSize / 3
        return VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let d = row * 3 + col + 1
                        Text(marks.contains(d) ? String(d) : "")
                            .font(Theme.rounded(miniCell * 0.5, weight: .light))
                            .foregroundStyle(Theme.primary)
                            .frame(width: miniCell, height: miniCell)
                    }
                }
            }
        }
    }

    private var backgroundColor: Color {
        switch highlight {
        case .selected:  return Theme.primary.opacity(0.25)
        case .peer:      return Theme.highlightWeak
        case .sameDigit: return Theme.sameDigit
        case .none:      return Theme.surface
        }
    }

    private var textColor: Color {
        if isMistake { return Theme.mistake }
        if given != 0 { return Theme.givenText }
        return Theme.playerText
    }
}
