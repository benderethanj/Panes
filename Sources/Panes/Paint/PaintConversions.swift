import SwiftUI

func rgbToHex(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
    let x1 = abs(Int(floor(r * 255 / 16)))
    let x2 = abs(Int(floor(g * 255 / 16)))
    let x3 = abs(Int(floor(b * 255 / 16)))
    
    let y1 = abs(Int(r * 255 - 16 * floor(r * 255 / 16)))
    let y2 = abs(Int(g * 255 - 16 * floor(g * 255 / 16)))
    let y3 = abs(Int(b * 255 - 16 * floor(b * 255 / 16)))
    
    return hexadecimal(x1) + hexadecimal(y1) + hexadecimal(x2) + hexadecimal(y2) + hexadecimal(x3) + hexadecimal(y3)
}

func hexToRGB(_ hex: String) -> [CGFloat] {
    var values: [Int] = []
    for char in hex {
        values.append(decimal(String(char)))
    }
    if values.count == 6 {
        return [
            CGFloat(values[0] * 16 + values[1]) / 255,
            CGFloat(values[2] * 16 + values[3]) / 255,
            CGFloat(values[4] * 16 + values[5]) / 255
        ]
    } else {
        return [0, 0, 0]
    }
}

func hexadecimal(_ decimal: Int) -> String {
    if decimal < 10 {
        return "\(decimal)"
    } else {
        switch decimal {
        case 10:
            return "A"
        case 11:
            return "B"
        case 12:
            return "C"
        case 13:
            return "D"
        case 14:
            return "E"
        case 15:
            return "F"
        default:
            return ""
        }
    }
}

func decimal(_ hexadecimal: String) -> Int {
    switch hexadecimal {
    case "0":
        return 0
    case "1":
        return 1
    case "2":
        return 2
    case "3":
        return 3
    case "4":
        return 4
    case "5":
        return 5
    case "6":
        return 6
    case "7":
        return 7
    case "8":
        return 8
    case "9":
        return 9
    case "A":
        return 10
    case "B":
        return 11
    case "C":
        return 12
    case "D":
        return 13
    case "E":
        return 14
    case "F":
        return 15
    default:
        return 0
    }
}

func rgbToHue(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    let max = max(R, G, B)
    let min = min(R, G, B)
    let c = max - min
    var value: CGFloat = 0
    if (c != 0) {
        switch max {
        case R:
            let segment: CGFloat = (G - B) / c;
            var shift: CGFloat = 0
            if (segment < 0) {
                shift = 6
            }
            value = segment + shift
          case G:
            let segment: CGFloat = (B - R) / c;
            let shift: CGFloat = 2
            value = segment + shift;
            break;
          case B:
            let segment: CGFloat = (R - G) / c;
            let shift: CGFloat = 4;
            value = segment + shift;
            break;
        default:
            value = 0
        }
    }
    return value * 60;
}

func rgbToLuminosity(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    let max = max(R, G, B)
    let min = min(R, G, B)
    return (max + min) / 2
}

func rgbToSaturation(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    let luminosity = rgbToLuminosity(R: R, G: G, B: B)
    if luminosity == 1 {
        return 0
    } else {
        let max = max(R, G, B)
        let min = min(R, G, B)
        return (max - min) / (1 - abs(2 * luminosity - 1))
    }
}


func xyz(r: CGFloat, g: CGFloat, b: CGFloat) -> [CGFloat] {
    let x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    let z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    return [x, y, z]
}

func xyzlabFactor(_ value: CGFloat) -> CGFloat {
    if value > pow(6 / 29, 3) {
        return pow(value, 1 / 3)
    } else {
        return pow(29 / 6, 2) * value / 3 + 4 / 29
    }
}

func rgbToLightness(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    return 116 * xyzlabFactor(xyz(r: R, g: G, b: B)[1] / 1.0000001) - 16
}

func rgbToA(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    return 500 * (xyzlabFactor(xyz(r: R, g: G, b: B)[0] / 0.95047) - xyzlabFactor(xyz(r: R, g: G, b: B)[1] / 1.0000001))
}
func rgbToB(R: CGFloat, G: CGFloat, B: CGFloat) -> CGFloat {
    return 200 * (xyzlabFactor(xyz(r: R, g: G, b: B)[1] / 1.0000001) - xyzlabFactor(xyz(r: R, g: G, b: B)[2] / 1.08883))
}

func HSLToRGB(H: CGFloat, S: CGFloat, L: CGFloat) -> [CGFloat] {
    let C = (1 - abs(2 * L - 1)) * S
    let X = C * (1 - abs((H / 60).truncatingRemainder(dividingBy: 2) - 1))
    let m = L - C / 2
    
    if H <= 60 {
        return [C + m, X + m, m]
    } else if H <= 120 {
        return [X + m, C + m, m]
    } else if H <= 180 {
        return [m, C + m, X + m]
    } else if H <= 240 {
        return [m, X + m, C + m]
    } else if H <= 300 {
        return [X + m, m, C + m]
    } else if H <= 360 {
        return [C + m, m, X + m]
    } else {
        return [0, 0, 0]
    }
}
