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

                    HStack(spacing: 10) {
                        ForEach(ReminderPalette.allCases) { palette in
                            Button {
                                draft.palette = palette
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [palette.startColor, palette.endColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)

                                    if draft.palette == palette {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2.5)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
