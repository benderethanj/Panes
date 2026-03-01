import SwiftUI

public struct GlassCard<Content: View>: View {
    public var content: Content
    public var interactive: Bool
    public var glass: Bool
    public var tint: Color
    public var padding: CGFloat
    public var glassType: String
    public var cornerRadius: CGFloat
    
    public init(padding: CGFloat = 16, cornerRadius: CGFloat = 32, glassType: String = "clear", tint: Color = .clear,  interactive: Bool = true, glass: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.interactive = interactive
        self.glass = glass
        self.padding = padding
        self.glassType = glassType
        self.cornerRadius = cornerRadius
        self.tint = tint
    }
    
    @State var pressed: Bool = false
    @State var position: CGPoint = .zero
    
    var id: UUID = .init()
    
    public var body: some View {
        if #available(iOS 26.0, macOS 26.0, *), glass {
            let glass: Glass = switch glassType {
            case "clear": interactive ? .clear.interactive().tint(tint) : .clear.tint(tint)
            case "regular": interactive ? .regular.interactive().tint(tint) : .regular.tint(tint)
            default: .regular
            }
            content
                .padding(padding)
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .padding(padding)
                .background(.ultraThinMaterial)
                .background(tint)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            self.position = drag.location
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.pressed = true
                            }
                        }
                        .onEnded { drag in
                            withAnimation {
                                self.pressed = false
                            }
                        }
                )
                .overlay(alignment: .topLeading) {
                        Circle()
                        .fill(.white.opacity(0.5))
                            .frame(width: 100, height: 100)
                            .blur(radius: pressed ? 100 : 1000)
                            .offset(x: position.x - 50, y: position.y - 50)
                }
                .cornerRadius(cornerRadius)
                .scaleEffect(pressed ? 1.01 : 1.0)
        }
    }
}


public struct GlassGroup<Content: View>: View {
    public var content: Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}
