import SwiftUI

public struct Paint: Identifiable, Hashable, Codable, Equatable {
    public var id: UUID = UUID()
    
    public var key: String {
        return "( red: \(R * 100)%, green: \(G * 100)%, blue: \(B * 100)% )"
    }
    
    public var R: CGFloat
    public var G: CGFloat
    public var B: CGFloat
    
    public var C: CGFloat
    public var M: CGFloat
    public var Y: CGFloat
    
    public var hue: CGFloat
    public var saturation: CGFloat
    public var luminosity: CGFloat
    
    public var hex: String
    
    public var L: CGFloat
    public var a: CGFloat
    public var b: CGFloat
    
    public var A: CGFloat
}
