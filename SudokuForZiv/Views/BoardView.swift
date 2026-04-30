import SwiftUI

struct BoardView: View {
    var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = size / 9

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.boardCornerRadius)
                    .fill(Theme.surface)
                    .shadow(color: Theme.ink.opacity(0.10), radius: 10, y: 3)

                // Cells — no GeometryReader per cell; size flows from parent
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                CellView(
                                    index: row * 9 + col,
                                    cellSize: cell,
                                    viewModel: viewModel
                                )
                                .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.boardCornerRadius))

                // Grid lines — purely decorative, passes all touches through
                Canvas { ctx, cgSize in
                    let c = cgSize.width / 9
                    for i in 1..<9 where i % 3 != 0 {
                        let x = c * CGFloat(i), y = c * CGFloat(i)
                        var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: cgSize.height))
                        ctx.stroke(p, with: .color(Theme.ink.opacity(0.12)), lineWidth: 0.5)
                        p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: cgSize.width, y: y))
                        ctx.stroke(p, with: .color(Theme.ink.opacity(0.12)), lineWidth: 0.5)
                    }
                    for i in [3, 6] {
                        let x = c * CGFloat(i), y = c * CGFloat(i)
                        var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: cgSize.height))
                        ctx.stroke(p, with: .color(Theme.ink.opacity(0.35)), lineWidth: 2)
                        p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: cgSize.width, y: y))
                        ctx.stroke(p, with: .color(Theme.ink.opacity(0.35)), lineWidth: 2)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: Theme.boardCornerRadius))
                .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
