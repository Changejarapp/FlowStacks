import FlowStacks
import SwiftUI

// MARK: - Screen

enum ZoomScreen {
    case home
    case detail(QuickCard)
    case fullDetail(FeatureCard)
}

struct QuickCard: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct FeatureCard: Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let color: Color
}

// MARK: - Coordinator

struct ZoomCoordinator: View {
    @State var routes: Routes<ZoomScreen> = [.root(.home, embedInNavigationView: true)]

    var body: some View {
        Router($routes) { screen, _ in
            switch screen {
            case .home:
                HomeFeedView()
            case .detail(let card):
                QuickCardDetailView(card: card)
            case .fullDetail(let card):
                FeatureCardDetailView(card: card)
            }
        }
        // The home feed draws its own overlaying bottom bar; the app-level TabView
        // bar underneath it would just stack a second bar.
        .hideSystemTabBar()
    }
}

private extension View {
    @ViewBuilder
    func hideSystemTabBar() -> some View {
        if #available(iOS 16.0, *) {
            self.toolbar(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}

// MARK: - Home Feed

enum HomeTab: String, CaseIterable {
    case home = "Home"
    case rewards = "Rewards"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .rewards: return "gift.fill"
        case .profile: return "person.fill"
        }
    }
}

struct HomeFeedView: View {
    @EnvironmentObject var navigator: FlowNavigator<ZoomScreen>
    @State private var selectedTab: HomeTab = .home

    let quickCards: [QuickCard] = [
        QuickCard(id: 1, title: "Buy Gold", subtitle: "Best price today", icon: "star.fill", color: Color(red: 0.9, green: 0.7, blue: 0.1)),
        QuickCard(id: 2, title: "Withdraw", subtitle: "Instant transfer", icon: "arrow.down.circle.fill", color: Color(red: 0.3, green: 0.7, blue: 0.5)),
        QuickCard(id: 3, title: "SIP", subtitle: "Weekly savings", icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.4, green: 0.5, blue: 0.9)),
    ]

    // Second row near the bottom of the feed — easy to park half-under the tab bar
    // to exercise the zoomOccluder clamping.
    let moreCards: [QuickCard] = [
        QuickCard(id: 4, title: "Refer", subtitle: "Invite & earn", icon: "person.2.fill", color: Color(red: 0.9, green: 0.4, blue: 0.5)),
        QuickCard(id: 5, title: "Insure", subtitle: "Protect savings", icon: "shield.fill", color: Color(red: 0.4, green: 0.8, blue: 0.9)),
        QuickCard(id: 6, title: "Loans", subtitle: "Low interest", icon: "banknote.fill", color: Color(red: 0.7, green: 0.6, blue: 0.9)),
    ]

    let featureCards: [FeatureCard] = [
        FeatureCard(id: 1, title: "Gold Locker", description: "Your savings at a glance", color: Color(red: 0.25, green: 0.18, blue: 0.38)),
        FeatureCard(id: 2, title: "Rewards", description: "Earn while you save", color: Color(red: 0.18, green: 0.28, blue: 0.42)),
        FeatureCard(id: 3, title: "Offers", description: "Exclusive deals for you", color: Color(red: 0.28, green: 0.18, blue: 0.32)),
    ]

    var body: some View {
        // Tab bar overlays the scrolling content (like Jar's bottomNavView), so cards
        // can sit half-clipped beneath it — the zoomOccluder test case.
        ZStack(alignment: .bottom) {
            switch selectedTab {
            case .home:
                feedContent
            case .rewards:
                placeholderTab(title: "Rewards", icon: "gift.fill")
            case .profile:
                placeholderTab(title: "Profile", icon: "person.fill")
            }

            bottomBar
        }
        .background(Color(red: 0.1, green: 0.07, blue: 0.18).ignoresSafeArea())
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    var feedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                lockerBanner
                VStack(spacing: 20) {
                    quickActionsSection
                    Divider().background(Color.white.opacity(0.1))
                    featureCardsSection
                    Divider().background(Color.white.opacity(0.1))
                    savingsSummarySection
                    Divider().background(Color.white.opacity(0.1))
                    moreActionsSection
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
                .background(Color(red: 0.13, green: 0.1, blue: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.top, -24)
            }
        }
    }

    // MARK: Bottom Tab Bar

    var bottomBar: some View {
        HStack {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.rawValue)
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { selectedTab = tab }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Color(red: 0.16, green: 0.12, blue: 0.26)
                .ignoresSafeArea(edges: .bottom)
        )
        .zoomOccluder()
    }

    func placeholderTab(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.3))
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Locker Banner

    var lockerBanner: some View {
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

    // MARK: Quick Actions

    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                ForEach(quickCards) { card in
                    QuickActionCardCell(card: card) {
                        navigator.pushZoom(.detail(card))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Feature Cards

    var featureCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("For You")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featureCards) { card in
                        FeatureCardCell(card: card) {
                            navigator.pushZoom(.fullDetail(card))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: More Actions

    var moreActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Actions")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                ForEach(moreCards) { card in
                    QuickActionCardCell(card: card) {
                        navigator.pushZoom(.detail(card))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Savings Summary

    var savingsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Summary")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            VStack(spacing: 1) {
                ForEach([("Weekly SIP", "₹500"), ("Monthly SIP", "₹2,000"), ("One-time Buy", "₹1,200")], id: \.0) { item, amount in
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
        .zoomTapSource(highlightOnReturn: true)
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
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
            Text(card.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .frame(width: 180, height: 120)
        .background(card.color)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .zoomTapSource(highlightOnReturn: true)
        .onTapGesture { onTap() }
    }
}

// MARK: - Quick Card Detail

struct QuickCardDetailView: View {
    let card: QuickCard
    @EnvironmentObject var navigator: FlowNavigator<ZoomScreen>

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.07, blue: 0.18).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: card.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(card.color)
                    .frame(width: 100, height: 100)
                    .background(card.color.opacity(0.15))
                    .clipShape(Circle())

                Text(card.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text(card.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                VStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        HStack {
                            Text("Option \(i + 1)")
                                .foregroundColor(.white)
                            Spacer()
                            Text("₹\((i + 1) * 500)")
                                .foregroundColor(card.color)
                                .fontWeight(.semibold)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button("Go Back") { navigator.goBack() }
                    .foregroundColor(card.color)
                    .padding(.bottom, 40)
            }
            .padding(24)
        }
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Card Detail

struct FeatureCardDetailView: View {
    let card: FeatureCard
    @EnvironmentObject var navigator: FlowNavigator<ZoomScreen>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [card.color, card.color.opacity(0.7), Color(red: 0.1, green: 0.07, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Text(card.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 200)
                    .overlay(Text("Chart / Content Area").foregroundColor(.white.opacity(0.4)))
                    .padding(.horizontal, 24)

                Spacer()

                Button("Go Back") { navigator.goBack() }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
