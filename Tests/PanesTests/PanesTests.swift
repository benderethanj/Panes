import Testing
import SwiftUI
@testable import Panes

@Test func paneConfigStoresInteractionOverrides() async throws {
    let config = PaneConfig(
        tracksCollapsedScrollAnchor: true,
        showsCollapsedScrollAnchorIndicator: true,
        scrollSnapBehavior: .viewAligned,
        dragIndicatorTouchExtension: 18,
        allowsContentInteractionWhenNotFullyExpanded: false,
        systemGestureDeferralEdges: [.top, .bottom]
    )

    #expect(config.dragIndicatorTouchExtension == 18)
    #expect(config.tracksCollapsedScrollAnchor)
    #expect(config.showsCollapsedScrollAnchorIndicator)
    #expect(config.scrollSnapBehavior == .viewAligned)
    #expect(config.allowsContentInteractionWhenNotFullyExpanded == false)
    #expect(config.systemGestureDeferralEdges.contains(.top))
    #expect(config.systemGestureDeferralEdges.contains(.bottom))
}

@Test func paneConfigDefaultsLeaveNewBehaviorDisabled() async throws {
    let config = PaneConfig()

    #expect(config.dragIndicatorTouchExtension == 0)
    #expect(config.tracksCollapsedScrollAnchor == false)
    #expect(config.showsCollapsedScrollAnchorIndicator == false)
    #expect(config.scrollSnapBehavior == .none)
    #expect(config.allowsContentInteractionWhenNotFullyExpanded)
    #expect(config.systemGestureDeferralEdges.isEmpty)
}
