import SwiftUI

struct NumberPadView: View {
    var viewModel: GameViewModel

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 8) { padButtons }
        } else {
            padButtons
        }
    }

    private var padButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { d in
                let remaining = viewModel.remainingCounts[d] ?? 0
                Button {
                    viewModel.place(d)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Text(String(d))
                            .font(Theme.rounded(26, weight: .semibold))
                            .foregroundStyle(remaining == 0 ? Theme.inkFaint : Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .themedControlSurface(in: RoundedRectangle(cornerRadius: 10))

                        if remaining > 0 && remaining < 9 {
                            Text(String(remaining))
                                .font(Theme.rounded(9, weight: .medium))
                                .foregroundStyle(Theme.primarySoft)
                                .padding(3)
                        }
                    }
                }
                .disabled(remaining == 0)
            }
        }
        .padding(.horizontal, 4)
    }
}
