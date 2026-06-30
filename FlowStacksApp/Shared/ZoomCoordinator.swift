import FlowStacks
import SwiftUI

// MARK: - Screen

enum ZoomScreen {
    case cardList
    case cardDetail(Card)
}

struct Card: Identifiable, Hashable {
    let id: Int
    let title: String
    let color: Color
}

// MARK: - Coordinator

struct ZoomCoordinator: View {
    @State var routes: Routes<ZoomScreen> = [.root(.cardList, embedInNavigationView: true)]

    var body: some View {
        Router($routes) { screen, _ in
            switch screen {
            case .cardList:
                CardListView()
            case .cardDetail(let card):
                CardDetailView(card: card)
            }
        }
    }
}

// MARK: - Card List

struct CardListView: View {
    @EnvironmentObject var navigator: FlowNavigator<ZoomScreen>

    private let cards = [
        Card(id: 1, title: "Ocean",   color: .blue),
        Card(id: 2, title: "Sunset",  color: .orange),
        Card(id: 3, title: "Forest",  color: .green),
        Card(id: 4, title: "Cherry",  color: .pink),
        Card(id: 5, title: "Storm",   color: .purple),
        Card(id: 6, title: "Sand",    color: .yellow),
    ]

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards) { card in
                    CardThumbnail(card: card) {
                        navigator.pushZoom(.cardDetail(card))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Cards")
    }
}

struct CardThumbnail: View {
    let card: Card
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: [card.color, card.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 140)
            .overlay(
                Text(card.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            )
            .zoomSource(highlightOnReturn: false) { onTap() }
    }
}

// MARK: - Card Detail

struct CardDetailView: View {
    let card: Card
    @EnvironmentObject var navigator: FlowNavigator<ZoomScreen>

    var body: some View {
        ZStack {
            LinearGradient(colors: [card.color, card.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Text(card.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text("Tap Back to zoom back to the card.")
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button("Go back") {
                    navigator.goBack()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.3))
                .cornerRadius(10)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
