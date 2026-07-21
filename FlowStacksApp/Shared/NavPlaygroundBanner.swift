import SwiftUI

struct LockerBanner: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.28, green: 0.18, blue: 0.45), Color(red: 0.12, green: 0.08, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Gold Locker")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Text("₹12,450.00")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("↑ 2.4% this week")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
            }
            .padding(24)
            .padding(.bottom, 32)
        }
        .frame(height: 220)
    }
}

struct SavingsSummarySection: View {
    let items: [(String, String)] = [
        ("Weekly SIP", "₹500"), ("Monthly SIP", "₹2,000"), ("One-time Buy", "₹1,200"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Summary")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            VStack(spacing: 1) {
                ForEach(items, id: \.0) { item, amount in
                    HStack {
                        Circle()
                            .fill(Color(red: 0.47, green: 0.27, blue: 1.0))
                            .frame(width: 8, height: 8)
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(amount)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
        }
    }
}
