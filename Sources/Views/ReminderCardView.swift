import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [reminder.palette.startColor, reminder.palette.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(reminder.palette.badgeText)
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
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(reminder.message)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.96))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 6)
            }
            .padding(20)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(0.1), radius: 12, y: 8)
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
