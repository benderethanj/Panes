import SwiftUI

struct PaintTestView: View {
    @State var colors: [Paint] = [
        .offwhite,
        .offwhite.invert
    ]
    
    var body: some View {
        VStack {
            ForEach(colors) { color in
                Color(color)
                    .overlay {
                        VStack(alignment: .leading) {
                            Text("Alpha: \(color.A * 100)%")
                            Divider()
                            Text("RGB")
                                .font(.title)
                            Text("Red: \(color.R * 100)%")
                            Text("Green: \(color.G * 100)%")
                            Text("Blue: \(color.B * 100)%")
                            Divider()
                            Text("CMYK")
                                .font(.title)
                            Text("Cyan: \(color.C * 100)%")
                            Text("Magenta: \(color.M * 100)%")
                            Text("Yellow: \(color.Y * 100)%")
                            Divider()
                            Text("HSL")
                                .font(.title)
                            Text("Hue: \(color.hue)°")
                            Text("Saturation: \(color.saturation * 100)%")
                            Text("Luminosity: \(color.luminosity * 100)%")
                            Divider()
                            Text("HEX")
                                .font(.title)
                            Text("#\(color.hex)")
                            Divider()
                            Text("LAB")
                                .font(.title)
                            Text("Lightness: \(color.L)%")
                            Text("A: \(color.a)%")
                            Text("B: \(color.b)%")
                        }
                        .bold()
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(20)
                        .padding()
                        .frame(width: 300)
                        .scaleEffect(0.5)
                    }
            }
        }
    }
}

#Preview {
    PaintTestView()
}
