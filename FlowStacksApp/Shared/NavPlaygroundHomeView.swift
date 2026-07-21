import FlowStacks
import SwiftUI

struct NavPlaygroundHomeView: View {
    @EnvironmentObject var navigator: FlowNavigator<NavPlaygroundScreen>

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LockerBanner()
                VStack(spacing: 20) {
                    quickActionsSection
                    Divider().background(Color.white.opacity(0.1))
                    featureCardsSection
                    Divider().background(Color.white.opacity(0.1))
                    SavingsSummarySection()
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
                .background(Color(red: 0.13, green: 0.1, blue: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.top, -24)
            }
        }
        .background(Color(red: 0.1, green: 0.07, blue: 0.18).ignoresSafeArea())
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions — one style each")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                ForEach(NavPlaygroundData.quickCards) { card in
                    QuickActionCardCell(card: card) {
                        push(card.title, style: card.style, color: card.color)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var featureCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Cards — zoom")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NavPlaygroundData.featureCards) { card in
                        FeatureCardCell(card: card) {
                            push(card.title, style: card.style, color: card.color)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func push(_ title: String, style: PushStyle, color: Color) {
        switch style {
        case .plain:
            navigator.push(.detail(title, style, color))
        case .leftToRight:
            navigator.pushLeftToRight(.detail(title, style, color))
        case .bottomToTop:
            navigator.pushBottomToTop(.detail(title, style, color))
        case .zoom:
            navigator.pushZoom(.detail(title, style, color))
        }
    }
}
