import Testing
@testable import Panes

@Test func paneConfigStoresInteractionOverrides() async throws {
    let config = PaneConfig(
        dragIndicatorTouchExtension: 18,
        allowsContentInteractionWhenNotFullyExpanded: false,
        systemGestureDeferralEdges: [.top, .bottom]
    )

    #expect(config.dragIndicatorTouchExtension == 18)
    #expect(config.allowsContentInteractionWhenNotFullyExpanded == false)
    #expect(config.systemGestureDeferralEdges.contains(.top))
    #expect(config.systemGestureDeferralEdges.contains(.bottom))
}

@Test func paneConfigDefaultsLeaveNewBehaviorDisabled() async throws {
    let config = PaneConfig()

    #expect(config.dragIndicatorTouchExtension == 0)
    #expect(config.allowsContentInteractionWhenNotFullyExpanded)
    #expect(config.systemGestureDeferralEdges.isEmpty)
}
