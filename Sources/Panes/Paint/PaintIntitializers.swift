import SwiftUI

public extension Paint {
    // MARK: RGB
    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.R = r
        self.G = g
        self.B = b
        self.C = 1 - r
        self.M = 1 - g
        self.Y = 1 - b
        self.hue = rgbToHue(R: r, G: g, B: b)
        self.saturation = rgbToSaturation(R: r, G: g, B: b)
        self.luminosity = rgbToLuminosity(R: r, G: g, B: b)
        self.hex = rgbToHex(r: r, g: g, b: b)
        self.L = rgbToLightness(R: r, G: g, B: b)
        self.a = rgbToA(R: r, G: g, B: b)
        self.b = rgbToB(R: r, G: g, B: b)
        self.A = a
    }
    // MARK: CMY
    init(c: CGFloat, m: CGFloat, y: CGFloat, a: CGFloat = 1) {
        self.R = 1 - c
        self.G = 1 - m
        self.B = 1 - y
        self.C = c
        self.M = m
        self.Y = y
        self.hue = rgbToHue(R: 1 - c, G: 1 - m, B: 1 - y)
        self.saturation = rgbToSaturation(R: 1 - c, G: 1 - m, B: 1 - y)
        self.luminosity = rgbToLuminosity(R: 1 - c, G: 1 - m, B: 1 - y)
        self.hex = rgbToHex(r: 1 - c, g: 1 - m, b: 1 - y)
        self.L = rgbToLightness(R: 1 - c, G: 1 - m, B: 1 - y)
        self.a = rgbToA(R: 1 - c, G: 1 - m, B: 1 - y)
        self.b = rgbToB(R: 1 - c, G: 1 - m, B: 1 - y)
        self.A = a
    }
    // MARK: HSL
    init(h: CGFloat, s: CGFloat, l: CGFloat, a: CGFloat = 1) {
        self.R = HSLToRGB(H: h, S: s, L: l)[0]
        self.G = HSLToRGB(H: h, S: s, L: l)[1]
        self.B = HSLToRGB(H: h, S: s, L: l)[2]
        self.C = 1 - HSLToRGB(H: h, S: s, L: l)[0]
        self.M = 1 - HSLToRGB(H: h, S: s, L: l)[1]
        self.Y = 1 - HSLToRGB(H: h, S: s, L: l)[2]
        self.hue = h
        self.saturation = s
        self.luminosity = l
        self.hex = rgbToHex(r: HSLToRGB(H: h, S: s, L: l)[0], g: HSLToRGB(H: h, S: s, L: l)[1], b: HSLToRGB(H: h, S: s, L: l)[2])
        self.L = rgbToLightness(R: HSLToRGB(H: h, S: s, L: l)[0], G: HSLToRGB(H: h, S: s, L: l)[1], B: HSLToRGB(H: h, S: s, L: l)[2])
        self.a = rgbToA(R: HSLToRGB(H: h, S: s, L: l)[0], G: HSLToRGB(H: h, S: s, L: l)[1], B: HSLToRGB(H: h, S: s, L: l)[2])
        self.b = rgbToB(R: HSLToRGB(H: h, S: s, L: l)[0], G: HSLToRGB(H: h, S: s, L: l)[1], B: HSLToRGB(H: h, S: s, L: l)[2])
        self.A = a
    }
    // MARK: HEX
    init(hex: String, a: CGFloat = 1) {
        self.R = hexToRGB(hex)[0]
        self.G = hexToRGB(hex)[1]
        self.B = hexToRGB(hex)[2]
        self.C = 1 - hexToRGB(hex)[0]
        self.M = 1 - hexToRGB(hex)[1]
        self.Y = 1 - hexToRGB(hex)[2]
        self.hue = rgbToHue(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.saturation = rgbToSaturation(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.luminosity = rgbToLuminosity(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.hex = hex
        self.L = rgbToLightness(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.a = rgbToA(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.b = rgbToB(R: hexToRGB(hex)[0], G: hexToRGB(hex)[1], B: hexToRGB(hex)[2])
        self.A = a
    }
    // MARK: LAB
}
