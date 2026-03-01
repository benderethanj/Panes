import SwiftUI

public extension Paint {
    @MainActor static let clear = Paint(r: 1, g: 1, b: 1, a: 0)
    @MainActor static let offwhite = Paint(r: 0.85, g: 0.88, b: 0.92)
    @MainActor static let offblack = Paint(r: 0.08, g: 0.08, b: 0.12)
    @MainActor static let black = Paint(r: 0, g: 0, b: 0)
    @MainActor static let white = Paint(r: 1, g: 1, b: 1)
    @MainActor static let gray = Paint(r: 0.5, g: 0.5, b: 0.5)
    @MainActor static let red = Paint(r: 0.92, g: 0.2, b: 0.15)
    @MainActor static let green = Paint(r: 0.011, g: 0.309, b: 0.125)
    @MainActor static let blue = Paint(r: 0.13, g: 0.26, b: 0.57)
    @MainActor static let purple = Paint(r: 0.16, g: 0, b: 0.22)
}
