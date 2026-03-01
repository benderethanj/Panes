import SwiftUI

extension Paint {
    static func +(lhs: Paint, rhs: Paint) -> Paint {
        Paint(r: (lhs.R + rhs.R) / 2, g: (lhs.G + rhs.G) / 2, b: (lhs.B + rhs.B) / 2, a: max(lhs.A, rhs.A))
    }
    
    static func -(lhs: Paint, rhs: Paint) -> Paint {
        Paint(r: abs(lhs.R * lhs.A - rhs.R * rhs.A), g: abs(lhs.G * lhs.A - rhs.G * rhs.A), b: abs(lhs.B * lhs.A - rhs.B * rhs.A), a: max(lhs.A, rhs.A))
    }
    
    static func *(lhs: Paint, rhs: Paint) -> Paint {
        Paint(r: lhs.R * rhs.R, g: lhs.G * rhs.G, b: lhs.B * rhs.B, a: lhs.A * rhs.A)
    }
    
    static func /(lhs: Paint, rhs: Paint) -> Paint {
        Paint(r: lhs.R / rhs.R, g: lhs.G / rhs.G, b: lhs.B / rhs.B, a: lhs.A / rhs.A)
    }
}



extension Array where Element == Paint {
    func colors() -> [Color] {
        var colors: [Color] = []
        for paint in self {
            colors.append(paint.color())
        }
        return colors
    }
    
    static func +(lhs: Paint, rhs: [Paint]) -> [Paint] {
        var array: [Paint] = []
        for paint in rhs {
            array.append(lhs + paint)
        }
        return array
    }
    
    static func +(lhs: [Paint], rhs: Paint) -> [Paint] {
        var array: [Paint] = []
        for paint in lhs {
            array.append(rhs + paint)
        }
        return array
    }
    
    static func -(lhs: Paint, rhs: [Paint]) -> [Paint] {
        var array: [Paint] = []
        for paint in rhs {
            array.append(lhs - paint)
        }
        return array
    }
    
    static func -(lhs: [Paint], rhs: Paint) -> [Paint] {
        var array: [Paint] = []
        for paint in lhs {
            array.append(rhs - paint)
        }
        return array
    }
    
    static func *(lhs: Paint, rhs: [Paint]) -> [Paint] {
        var array: [Paint] = []
        for paint in rhs {
            array.append(lhs * paint)
        }
        return array
    }
    
    static func *(lhs: [Paint], rhs: Paint) -> [Paint] {
        var array: [Paint] = []
        for paint in lhs {
            array.append(rhs * paint)
        }
        return array
    }
    
    static func /(lhs: Paint, rhs: [Paint]) -> [Paint] {
        var array: [Paint] = []
        for paint in rhs {
            array.append(lhs / paint)
        }
        return array
    }
    
    static func /(lhs: [Paint], rhs: Paint) -> [Paint] {
        var array: [Paint] = []
        for paint in lhs {
            array.append(rhs / paint)
        }
        return array
    }
}
