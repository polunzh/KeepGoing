import SwiftUI

struct ReminderDetailForm: View {
    @State private var draft: Reminder

    private let onSave: (Reminder) -> Void
    private let onDelete: () -> Void

    init(binding: ReminderBinding, onDelete: @escaping () -> Void) {
        _draft = State(initialValue: binding.reminder)
        onSave = binding.onChange
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("标题")
                    .font(.headline)

                TextField("例如：先开始就算赢", text: $draft.title)
                    .textFieldStyle(.roundedBorder)

                Text("内容")
                    .font(.headline)
                    .padding(.top, 4)

                TextField("写一句你希望自己经常看到的话", text: $draft.message, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)

                Toggle("在轮播中启用这条提醒", isOn: $draft.isEnabled)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("配色")
                        .font(.headline)

                    ColorGridPicker(selectedHue: $draft.palette)
                }
            }

            Divider()

            HStack {
                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Label("删除这条提醒", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal)
        .onChange(of: draft) { _, newValue in
            onSave(newValue)
        }
    }
}

// MARK: - 16x16 Color Grid Picker

private struct ColorGridPicker: View {
    @Binding var selectedHue: ReminderPalette

    private static let columns = 16
    private static let rows = 16
    private static let swatchSize: CGFloat = 20
    private static let spacing: CGFloat = 3

    var body: some View {
        VStack(spacing: Self.spacing) {
            ForEach(0..<Self.rows, id: \.self) { row in
                HStack(spacing: Self.spacing) {
                    ForEach(0..<Self.columns, id: \.self) { col in
                        let palette = paletteFor(row: row, col: col)
                        Button {
                            selectedHue = palette
                        } label: {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [palette.startColor, palette.endColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: Self.swatchSize, height: Self.swatchSize)
                                .overlay {
                                    if isSelected(palette) {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .strokeBorder(.white, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func paletteFor(row: Int, col: Int) -> ReminderPalette {
        // col = hue (0-15), row = saturation/brightness variation
        let hue = Double(col) / 16.0
        let shift = Double(row) * 0.003
        return ReminderPalette(hue: (hue + shift).truncatingRemainder(dividingBy: 1.0))
    }

    private func isSelected(_ palette: ReminderPalette) -> Bool {
        abs(palette.hue - selectedHue.hue) < 0.005
    }
}
