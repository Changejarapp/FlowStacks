import FlowStacks
import SwiftUI

// MARK: - Quick Action Card Cell

struct QuickActionCardCell: View {
    let card: QuickCard
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: card.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(card.color)
                .frame(width: 44, height: 44)
                .background(card.color.opacity(0.15))
                .clipShape(Circle())

            Text(card.title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
            Text(card.subtitle)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .zoomTapSource()
        .onTapGesture { onTap() }
    }
}

// MARK: - Feature Card Cell

struct FeatureCardCell: View {
    let card: FeatureCard
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            Text(card.title)
                .font(.headline)
                .foregroundColor(.white)
            Text(card.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .frame(width: 160, height: 120, alignment: .leading)
        .background(card.color)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .zoomTapSource()
        .onTapGesture { onTap() }
    }
}
