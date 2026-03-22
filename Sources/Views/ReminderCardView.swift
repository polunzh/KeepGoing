import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder
    let compact: Bool

    init(reminder: Reminder, compact: Bool = false) {
        self.reminder = reminder
        self.compact = compact
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: compact ? 24 : 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [reminder.palette.startColor, reminder.palette.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: compact ? 12 : 16) {
                HStack(alignment: .top) {
                    Text(reminder.palette.badgeText.uppercased())
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18), in: Capsule())

                    Spacer(minLength: 8)

                    Image(systemName: reminder.isEnabled ? "eye.fill" : "eye.slash.fill")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.92))
                }

                Text(reminder.title)
                    .font(compact ? .title3.weight(.bold) : .largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(compact ? 2 : 3)

                Text(reminder.message)
                    .font(compact ? .body.weight(.medium) : .title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.96))
                    .lineSpacing(compact ? 3 : 4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: compact ? 6 : 10)

                Text("KeepGoing")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(compact ? 20 : 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 220 : 260)
        .shadow(color: .black.opacity(0.12), radius: compact ? 10 : 18, y: 12)
    }
}

#Preview {
    ReminderCardView(
        reminder: Reminder(
            title: "先开始就算赢",
            message: "你不需要一下子追上时代，你只需要今天继续前进。",
            palette: .sky
        )
    )
    .padding()
}
