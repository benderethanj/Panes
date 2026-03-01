import SwiftUI

struct Paint: Identifiable, Hashable, Codable, Equatable {
    var id: UUID = UUID()
    
    var key: String {
        return "( red: \(R * 100)%, green: \(G * 100)%, blue: \(B * 100)% )"
    }
    
    var R: CGFloat
    var G: CGFloat
    var B: CGFloat
    
    var C: CGFloat
    var M: CGFloat
    var Y: CGFloat
    
    var hue: CGFloat
    var saturation: CGFloat
    var luminosity: CGFloat
    
    var hex: String
    
    var L: CGFloat
    var a: CGFloat
    var b: CGFloat
    
    var A: CGFloat
}
