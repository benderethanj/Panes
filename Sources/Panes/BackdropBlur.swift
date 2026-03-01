import SwiftUI

#if canImport(UIKit)
import UIKit

/// A View in which content reflects all behind it
private struct BackdropView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        let blur = UIBlurEffect()
        let animator = UIViewPropertyAnimator()
        animator.addAnimations { view.effect = blur }
        animator.fractionComplete = 0
        animator.stopAnimation(false)
        animator.finishAnimation(at: .current)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
    
}
#endif

/// A transparent View that blurs its background
public struct BackdropBlurView: View {
    
    public let radius: CGFloat

    public init(radius: CGFloat) {
        self.radius = radius
    }
    
    @ViewBuilder
    public var body: some View {
        #if canImport(UIKit)
        BackdropView().blur(radius: radius)
        #else
        Rectangle()
            .fill(.clear)
            .background(.ultraThinMaterial)
            .blur(radius: radius)
        #endif
    }
    
}
