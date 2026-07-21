import SwiftUI

struct PushStyleDetailView: View {
    let title: String
    let style: PushStyle
    let color: Color

    var body: some View {
        ZStack {
            LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text("Pushed via navigator.\(style.rawValue)")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
