import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public func screenCornerRadius(for width: CGFloat = {
    #if canImport(UIKit)
    UIScreen.main.bounds.width
    #else
    390
    #endif
}()) -> CGFloat {
    switch width {
    case 430: return 53
    case 414: return 50
    case 390: return 47
    case 375: return 42
    default:  return 50
    }
}
