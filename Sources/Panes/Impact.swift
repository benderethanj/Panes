#if canImport(UIKit)
import UIKit
public typealias ImpactFeedbackStyle = UIImpactFeedbackGenerator.FeedbackStyle
#else
public enum ImpactFeedbackStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
}
#endif

@inline(__always)
func impact(_ style: ImpactFeedbackStyle = .medium) {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: style).impactOccurred()
    #endif
}
