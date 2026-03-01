import SwiftUI

public enum GlassButtonType {
    case clear
    case colored
}

public struct GlassButton<Content: View>: View {
    public var tint: Color
    public var shape: ButtonBorderShape
    public var size: ControlSize
    public var style: GlassButtonType
    public var action: () -> Void
    public var label: () -> Content
    
    public init(tint: Color = .primary, shape: ButtonBorderShape = .capsule, size: ControlSize = .regular, style: GlassButtonType = .clear, action: @escaping () -> Void, label: @escaping () -> Content) {
        self.tint = tint
        self.shape = shape
        self.size = size
        self.style = style
        self.action = action
        self.label = label
    }
    
    public var body: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
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
