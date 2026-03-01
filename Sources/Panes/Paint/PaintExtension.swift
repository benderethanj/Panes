import SwiftUI

extension Color {
    init(_ paint: Paint) {
        self.init(red: paint.R, green: paint.G, blue: paint.B, opacity: paint.A)
    }
}

struct BackgroundModifier: ViewModifier {
    let paint: Paint

    func body(content: Content) -> some View {
        content
            .background(paint.color())
    }
}

extension View {
    func background(_ paint: Paint) -> some View {
        modifier(BackgroundModifier(paint: paint))
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
