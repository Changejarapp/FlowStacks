import SwiftUI

// MARK: - Models

struct QuickCard: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let style: PushStyle
}

struct FeatureCard: Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let color: Color
    let style: PushStyle
}

// MARK: - Sample data

enum NavPlaygroundData {
    static let quickCards: [QuickCard] = [
        QuickCard(id: 1, title: "Buy Gold", subtitle: "Best price today", icon: "star.fill", color: Color(red: 0.9, green: 0.7, blue: 0.1), style: .plain),
        QuickCard(id: 2, title: "Withdraw", subtitle: "Instant transfer", icon: "arrow.down.circle.fill", color: Color(red: 0.3, green: 0.7, blue: 0.5), style: .leftToRight),
        QuickCard(id: 3, title: "SIP", subtitle: "Weekly savings", icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.4, green: 0.5, blue: 0.9), style: .bottomToTop),
    ]

    static let featureCards: [FeatureCard] = [
        FeatureCard(id: 1, title: "Gold Locker", description: "Your savings at a glance", color: Color(red: 0.25, green: 0.18, blue: 0.38), style: .zoom),
        FeatureCard(id: 2, title: "Rewards", description: "Earn while you save", color: Color(red: 0.18, green: 0.28, blue: 0.42), style: .zoom),
        FeatureCard(id: 3, title: "Offers", description: "Exclusive deals for you", color: Color(red: 0.28, green: 0.18, blue: 0.32), style: .zoom),
    ]
}
