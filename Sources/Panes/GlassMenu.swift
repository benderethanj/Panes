import SwiftUI

struct GlassMenu<MenuContent: View, Content: View>: View {
    var tint: Color
    var shape: ButtonBorderShape
    var size: ControlSize
    var style: GlassButtonType
    var menu: () -> MenuContent
    var label: () -> Content
    
    init(tint: Color = .primary, shape: ButtonBorderShape = .capsule, size: ControlSize = .regular, style: GlassButtonType = .clear, menu: @escaping () -> MenuContent, label: @escaping () -> Content) {
        self.tint = tint
        self.shape = shape
        self.size = size
        self.style = style
        self.menu = menu
        self.label = label
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
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
