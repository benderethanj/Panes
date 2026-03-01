import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public func screenCornerRadius(for width: CGFloat? = nil) -> CGFloat {
    let resolvedWidth: CGFloat
    #if canImport(UIKit)
    resolvedWidth = width ?? UIScreen.main.bounds.width
    #else
    resolvedWidth = width ?? 390
    #endif

    switch resolvedWidth {
    case 430: return 53
    case 414: return 50
    case 390: return 47
    case 375: return 42
    default:  return 50
    }
}
