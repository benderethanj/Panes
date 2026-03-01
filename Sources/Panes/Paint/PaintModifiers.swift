import SwiftUI

public extension Paint {
    func color() -> Color {
        return Color(red: R, green: G, blue: B, opacity: A)
    }
    
    func opacity(_ value: CGFloat) -> Paint {
        Paint(r: self.R, g: self.G, b: self.B, a: value)
    }
    
    var invert: Paint {
        return Paint(h: self.hue, s: self.saturation, l: abs(1 - self.luminosity))
    }
    
    func hue(_ value: CGFloat) -> Paint {
        Paint(h: value, s: self.saturation, l: self.luminosity, a: self.A)
    }
    func saturation(_ value: CGFloat) -> Paint {
        Paint(h: self.hue, s: value, l: self.luminosity, a: self.A)
    }
    func luminosity(_ value: CGFloat) -> Paint {
        Paint(h: self.hue, s: self.saturation, l: value, a: self.A)
    }
}
