import SwiftUI

struct ToolbarView: View {
    var viewModel: GameViewModel

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 8) { toolbarButtons }
        } else {
            toolbarButtons
        }
    }

    private var toolbarButtons: some View {
        HStack(spacing: 8) {
            toolButton(icon: "arrow.uturn.backward", label: "Undo", enabled: viewModel.canUndo) {
                viewModel.undo()
            }
            toolButton(icon: "xmark", label: "Erase", enabled: true) {
                viewModel.erase()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            toolButton(
                icon: "pencil",
                label: "Notes",
                enabled: true,
                isOn: viewModel.isNotesMode
            ) {
                viewModel.isNotesMode.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            hintButton
        }
        .padding(.horizontal, 4)
    }

    private var hintButton: some View {
        Button {
            viewModel.useHint()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(viewModel.hintsRemaining > 0 ? Theme.primary : Theme.inkFaint)
                    if viewModel.hintsRemaining > 0 {
                        Text(String(viewModel.hintsRemaining))
                            .font(Theme.rounded(9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(2)
                            .background(Theme.primary, in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                Text("Hint")
                    .font(Theme.rounded(11))
                    .foregroundStyle(viewModel.hintsRemaining > 0 ? Theme.ink : Theme.inkFaint)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .themedControlSurface(
                in: RoundedRectangle(cornerRadius: 10),
                fallbackFill: Theme.surface.opacity(0.72)
            )
        }
        .disabled(viewModel.hintsRemaining == 0)
    }

    private func toolButton(
        icon: String,
        label: String,
        enabled: Bool,
        isOn: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isOn ? Theme.primary : (enabled ? Theme.ink : Theme.inkFaint))
                Text(label)
                    .font(Theme.rounded(11))
                    .foregroundStyle(isOn ? Theme.primary : (enabled ? Theme.ink : Theme.inkFaint))
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .themedControlSurface(
                in: RoundedRectangle(cornerRadius: 10),
                isActive: isOn,
                fallbackFill: Theme.surface.opacity(0.72)
            )
        }
        .disabled(!enabled)
    }
}
