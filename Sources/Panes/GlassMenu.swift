import SwiftUI

public struct GlassMenu<MenuContent: View, Content: View>: View {
    public var tint: Color
    public var shape: ButtonBorderShape
    public var size: ControlSize
    public var style: GlassButtonType
    public var menu: () -> MenuContent
    public var label: () -> Content
    
    public init(tint: Color = .primary, shape: ButtonBorderShape = .capsule, size: ControlSize = .regular, style: GlassButtonType = .clear, menu: @escaping () -> MenuContent, label: @escaping () -> Content) {
        self.tint = tint
        self.shape = shape
        self.size = size
        self.style = style
        self.menu = menu
        self.label = label
    }
    
    public var body: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                if style == .clear {
                    Menu {
                        menu()
                    } label: {
                        label()
                    }
                    .buttonStyle(.glass)
                } else {
                    Menu {
                        menu()
                    } label: {
                        label()
                    }
                    .buttonStyle(.glassProminent)
                }
            } else {
                if style == .clear {
                    Menu {
                        menu()
                    } label: {
                        label()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Menu {
                        menu()
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
    GlassMenu {
        Text("Option 1")
    } label: {
        Text("Test")
    }
}
