import Testing
import SwiftUI
@testable import Panes

@Test func paneConfigStoresInteractionOverrides() async throws {
    let targetView = PaneTargetView(
        tag: AnyHashable("target"),
        alignment: .center,
        alignsWhenNotLarge: true,
        tracksWhileNotLarge: true
    )
    let handleInteractionZone = PaneHandleInteractionZone(
        padding: EdgeInsets(top: 8, leading: 12, bottom: 16, trailing: 12),
        systemGestureDeferralEdges: [.top, .bottom],
        systemGestureDeferralActivationDistance: 72
    )
    let config = PaneConfig(
        detents: [.targetViewHeight(padding: 24), .large],
        targetView: targetView,
        handleInteractionZone: handleInteractionZone,
        tracksCollapsedScrollAnchor: true,
        showsCollapsedScrollAnchorIndicator: true,
        scrollSnapBehavior: .viewAligned,
        dragIndicatorTouchExtension: 18,
        allowsContentInteractionWhenNotFullyExpanded: false,
        systemGestureDeferralEdges: [.top, .bottom]
    )

    #expect(config.targetView?.tag == AnyHashable("target"))
    #expect(config.targetView?.alignsWhenNotLarge == true)
    #expect(config.targetView?.tracksWhileNotLarge == true)
    #expect(config.handleInteractionZone.padding.top == 8)
    #expect(config.handleInteractionZone.padding.bottom == 16)
    #expect(config.handleInteractionZone.systemGestureDeferralEdges.contains(.top))
    #expect(config.handleInteractionZone.systemGestureDeferralEdges.contains(.bottom))
    #expect(config.handleInteractionZone.systemGestureDeferralActivationDistance == 72)
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

    #expect(config.targetView == nil)
    #expect(config.handleInteractionZone.padding.top == 0)
    #expect(config.handleInteractionZone.padding.bottom == 0)
    #expect(config.handleInteractionZone.systemGestureDeferralEdges.isEmpty)
    #expect(config.handleInteractionZone.systemGestureDeferralActivationDistance == 56)
    #expect(config.dragIndicatorTouchExtension == 0)
    #expect(config.tracksCollapsedScrollAnchor == false)
    #expect(config.showsCollapsedScrollAnchorIndicator == false)
    #expect(config.scrollSnapBehavior == .none)
    #expect(config.allowsContentInteractionWhenNotFullyExpanded)
    #expect(config.systemGestureDeferralEdges.isEmpty)
}
