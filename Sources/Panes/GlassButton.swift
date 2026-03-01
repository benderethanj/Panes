import SwiftUI

enum GlassButtonType {
    case clear
    case colored
}

struct GlassButton<Content: View>: View {
    var tint: Color
    var shape: ButtonBorderShape
    var size: ControlSize
    var style: GlassButtonType
    var action: () -> Void
    var label: () -> Content
    
    init(tint: Color = .primary, shape: ButtonBorderShape = .capsule, size: ControlSize = .regular, style: GlassButtonType = .clear, action: @escaping () -> Void, label: @escaping () -> Content) {
        self.tint = tint
        self.shape = shape
        self.size = size
        self.style = style
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                if style == .clear {
                    Button {
                        impact(.soft)
                        action()
                    } label: {
                        label()
                    }
                    .buttonStyle(.glass)
                } else {
                    Button {
                        impact(.soft)
                        action()
                    } label: {
                        label()
                    }
                    .buttonStyle(.glassProminent)
                }
            } else {
                if style == .clear {
                    Button {
                        impact(.soft)
                        action()
                    } label: {
                        label()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        impact(.soft)
                        action()
                    } label: {
                        label()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .buttonBorderShape(shape)
        .controlSize(size)
        .tint(tint)
    }
}

#Preview {
    GlassButton {
        
    } label: {
        Text("Test")
    }
}
