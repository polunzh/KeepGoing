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
            HStack {
                Text("编辑提醒")
                    .font(.title2.weight(.bold))

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            }

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

                    Picker("配色", selection: $draft.palette) {
                        ForEach(ReminderPalette.allCases) { palette in
                            Text(palette.title).tag(palette)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("预览")
                        .font(.headline)

                    ReminderCardView(reminder: draft, compact: true)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .onChange(of: draft) { _, newValue in
            onSave(newValue)
        }
    }
}
