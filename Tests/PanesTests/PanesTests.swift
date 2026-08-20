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
        tracksCollapsedScrollAnchor: true,
        showsCollapsedScrollAnchorIndicator: true,
        scrollSnapBehavior: .viewAligned,
        handleInteractionZone: handleInteractionZone,
        dragIndicatorTouchExtension: 18,
        allowsContentInteractionWhenNotFullyExpanded: false,
        systemGestureDeferralEdges: [.top, .bottom],
        handleDismissDistance: 72,
        handleDismissPredictedDistance: 128,
        allowsSwipeToDismissFromAnywhere: true,
        minimumDetentDragBehavior: .continuous,
        allowsScrollCollapseFromAnyPosition: true,
        scrollCollapseActivationDistance: 12,
        preventsContentActivationDuringDrag: true,
        surfaceTintOpacityTransition: .init(collapsed: 0.12, expanded: 1),
        hapticsEnabled: true
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
    #expect(config.handleDismissDistance == 72)
    #expect(config.handleDismissPredictedDistance == 128)
    #expect(config.allowsSwipeToDismissFromAnywhere)
    #expect(config.minimumDetentDragBehavior == .continuous)
    #expect(config.allowsScrollCollapseFromAnyPosition)
    #expect(config.scrollCollapseActivationDistance == 12)
    #expect(config.preventsContentActivationDuringDrag)
    #expect(config.surfaceTintOpacityTransition == .init(collapsed: 0.12, expanded: 1))
    #expect(config.hapticsEnabled)
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
    #expect(config.handleDismissDistance == nil)
    #expect(config.handleDismissPredictedDistance == nil)
    #expect(!config.allowsSwipeToDismissFromAnywhere)
    #expect(config.minimumDetentDragBehavior == .rubberBand)
    #expect(!config.allowsScrollCollapseFromAnyPosition)
    #expect(config.scrollCollapseActivationDistance == 8)
    #expect(!config.preventsContentActivationDuringDrag)
    #expect(config.surfaceTintOpacityTransition == nil)
    #expect(!config.hapticsEnabled)
}

@Test func paneConfigStoresAdaptivePresentationOptions() {
    let collapsed = PaneCrossAxisGeometry(
        size: .fixed(280),
        insets: EdgeInsets(top: 6, leading: 8, bottom: 10, trailing: 12)
    )
    let expanded = PaneCrossAxisGeometry(
        size: .fill,
        insets: EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
    )
    let transition = PaneCrossAxisTransition(
        collapsed: collapsed,
        expanded: expanded
    )
    let config = PaneConfig(
        crossAxisTransition: transition,
        collapsedAnchorInset: 14,
        interactionAxis: .vertical,
        interactionEdge: .bottom,
        minimumDimmingOpacity: 0.08,
        presentationTransition: .scale(activeScale: 0.72, anchor: .bottomTrailing),
        surfaceStyle: .glass(tint: nil, interactive: true)
    )

    #expect(config.crossAxisTransition == transition)
    #expect(config.crossAxisTransition?.collapsed == collapsed)
    #expect(config.crossAxisTransition?.expanded == expanded)
    #expect(config.collapsedAnchorInset == 14)
    #expect(config.interactionAxis == .vertical)
    #expect(config.interactionEdge == .bottom)
    #expect(config.minimumDimmingOpacity == 0.08)

    switch config.presentationTransition {
    case let .scale(activeScale, anchor):
        #expect(activeScale == 0.72)
        #expect(anchor == .bottomTrailing)
    default:
        Issue.record("Expected scale presentation transition")
    }

    switch config.surfaceStyle {
    case let .glass(style, tint, interactive):
        #expect(style == .regular)
        #expect(tint == nil)
        #expect(interactive)
    default:
        Issue.record("Expected glass surface style")
    }
}

@Test func paneConfigAdaptivePresentationDefaultsAreBackwardCompatible() {
    let config = PaneConfig()

    #expect(config.crossAxisTransition == nil)
    #expect(config.collapsedAnchorInset == 0)
    #expect(config.interactionAxis == nil)
    #expect(config.interactionEdge == nil)
    #expect(config.minimumDimmingOpacity == 0)

    switch config.presentationTransition {
    case .edge:
        break
    default:
        Issue.record("Expected edge presentation transition by default")
    }

    switch config.surfaceStyle {
    case .material:
        break
    default:
        Issue.record("Expected material surface style by default")
    }
}

@Test func paneCrossAxisLengthDetentPreservesConfiguration() {
    let detent = PaneDetent.crossAxisLength(fraction: 1, offset: -12)

    switch detent {
    case let .crossAxisLength(fraction, offset):
        #expect(fraction == 1)
        #expect(offset == -12)
    default:
        Issue.record("Expected cross-axis-length detent")
    }
}

@Test func paneTabDefaultsPreservePowerUpChromeAndHandleBehavior() {
    let chrome = PaneTabNavigationConfiguration()
    let menu = PaneTabMenuConfiguration()

    #expect(chrome.margin == 24)
    #expect(chrome.barPadding == 6)
    #expect(chrome.tabBarContentPadding == 8)
    #expect(chrome.scrubMargin == 16)
    #expect(chrome.scrubBarPadding == 4)
    #expect(chrome.menuButtonSpacing == 8)
    #expect(chrome.glassIsInteractive)
    #expect(!chrome.hidesTabBarWhenSingleTab)
    #expect(chrome.hapticsEnabled)
    #expect(chrome.quickSwipeMaximumDuration == 0.26)
    #expect(chrome.quickSwipePredictedDistance == 44)
    #expect(menu.handleDismissDistance == 72)
    #expect(menu.handleDismissPredictedDistance == 128)
    #expect(menu.allowsSwipeToDismissFromAnywhere)
    #expect(menu.minimumDetentDragBehavior == .continuous)
    #expect(!menu.allowsScrollCollapseFromAnyPosition)
    #expect(menu.scrollCollapseActivationDistance == 8)
    #expect(menu.preventsContentActivationDuringDrag)
    #expect(menu.surfaceTintOpacityTransition == .init())
    #expect(menu.hapticsEnabled)
}

@Test func paneTabQuickSwipeRequiresFastIntentionalUpwardMotion() {
    #expect(isQuickUpwardSwipe(
        elapsed: 0.18,
        translation: CGSize(width: 3, height: -52),
        predictedEndTranslation: CGSize(width: 4, height: -82),
        activationDistance: 10,
        minimumDragDistance: 52,
        maximumDuration: 0.26,
        predictedDistance: 44
    ))
    #expect(!isQuickUpwardSwipe(
        elapsed: 0.18,
        translation: CGSize(width: 3, height: -51),
        predictedEndTranslation: CGSize(width: 4, height: -100),
        activationDistance: 10,
        minimumDragDistance: 52,
        maximumDuration: 0.26,
        predictedDistance: 44
    ))
    #expect(!isQuickUpwardSwipe(
        elapsed: 0.4,
        translation: CGSize(width: 3, height: -60),
        predictedEndTranslation: CGSize(width: 4, height: -100),
        activationDistance: 10,
        minimumDragDistance: 52,
        maximumDuration: 0.26,
        predictedDistance: 44
    ))
    #expect(!isQuickUpwardSwipe(
        elapsed: 0.18,
        translation: CGSize(width: 60, height: -52),
        predictedEndTranslation: CGSize(width: 70, height: -82),
        activationDistance: 10,
        minimumDragDistance: 52,
        maximumDuration: 0.26,
        predictedDistance: 44
    ))
    #expect(!isQuickUpwardSwipe(
        elapsed: 0.18,
        translation: CGSize(width: 1, height: -6),
        predictedEndTranslation: CGSize(width: 2, height: -80),
        activationDistance: 10,
        minimumDragDistance: 52,
        maximumDuration: 0.26,
        predictedDistance: 44
    ))
}

@Test func paneDismissDistancesApplyOnlyFromTheMinimumDetent() {
    let options = PaneConfig(
        handleDismissDistance: 72,
        handleDismissPredictedDistance: 128
    )

    #expect(shouldDismissPaneDrag(
        options: options,
        rawCurrentHeight: 307,
        startingHeight: 380,
        minHeight: 380,
        handleTranslation: 73,
        predictedHandleTranslation: 73,
        startedOnIndicator: true
    ))
    #expect(shouldDismissPaneDrag(
        options: options,
        rawCurrentHeight: 360,
        startingHeight: 380,
        minHeight: 380,
        handleTranslation: 20,
        predictedHandleTranslation: 129,
        startedOnIndicator: true
    ))
    #expect(!shouldDismissPaneDrag(
        options: options,
        rawCurrentHeight: 280,
        startingHeight: 380,
        minHeight: 380,
        handleTranslation: 100,
        predictedHandleTranslation: 160,
        startedOnIndicator: false
    ))

    let anywhereOptions = PaneConfig(
        handleDismissDistance: 72,
        handleDismissPredictedDistance: 128,
        allowsSwipeToDismissFromAnywhere: true
    )
    #expect(shouldDismissPaneDrag(
        options: anywhereOptions,
        rawCurrentHeight: 307,
        startingHeight: 380,
        minHeight: 380,
        handleTranslation: 73,
        predictedHandleTranslation: 73,
        startedOnIndicator: false
    ))
    #expect(shouldDismissPaneDrag(
        options: anywhereOptions,
        rawCurrentHeight: 360,
        startingHeight: 380,
        minHeight: 380,
        handleTranslation: 20,
        predictedHandleTranslation: 129,
        startedOnIndicator: false
    ))

    #expect(!shouldDismissPaneDrag(
        options: anywhereOptions,
        rawCurrentHeight: 380,
        startingHeight: 900,
        minHeight: 380,
        handleTranslation: 520,
        predictedHandleTranslation: 700,
        startedOnIndicator: true
    ))
    #expect(shouldDismissPaneDrag(
        options: anywhereOptions,
        rawCurrentHeight: 200,
        startingHeight: 900,
        minHeight: 380,
        handleTranslation: 700,
        predictedHandleTranslation: 760,
        startedOnIndicator: true
    ))
}

@Test func paneMinimumDetentDragCanTrackContinuouslyToZero() {
    #expect(resolvedPaneDragHeight(
        selectedHeight: 380,
        dragTranslation: 180,
        minHeight: 380,
        maxHeight: 900,
        minimumDetentDragBehavior: .continuous
    ) == 200)
    #expect(resolvedPaneDragHeight(
        selectedHeight: 380,
        dragTranslation: 500,
        minHeight: 380,
        maxHeight: 900,
        minimumDetentDragBehavior: .continuous
    ) == 0)

    let rubberBandedHeight = resolvedPaneDragHeight(
        selectedHeight: 380,
        dragTranslation: 180,
        minHeight: 380,
        maxHeight: 900,
        minimumDetentDragBehavior: .rubberBand
    )
    #expect(rubberBandedHeight > 200)
    #expect(rubberBandedHeight < 380)
}

@Test func paneScrollCollapseRespectsEdgeAndIntent() {
    let gestureStartOffset: CGFloat = 420
    let liveOffsetAfterScrollingToTop: CGFloat = 0.5

    #expect(canBeginScrollDrivenPaneCollapse(
        allowsCollapseFromAnyScrollPosition: true,
        collapseDirection: 1,
        normalizedOffsetY: 420,
        bottomEdgeDistance: 310,
        edgeTolerance: 1.5
    ))
    #expect(!canBeginScrollDrivenPaneCollapse(
        allowsCollapseFromAnyScrollPosition: false,
        collapseDirection: 1,
        normalizedOffsetY: 420,
        bottomEdgeDistance: 310,
        edgeTolerance: 1.5
    ))
    #expect(canBeginScrollDrivenPaneCollapse(
        allowsCollapseFromAnyScrollPosition: false,
        collapseDirection: 1,
        normalizedOffsetY: liveOffsetAfterScrollingToTop,
        bottomEdgeDistance: 730,
        edgeTolerance: 1.5
    ))
    #expect(gestureStartOffset > 1.5)

    #expect(!hasScrollDrivenPaneCollapseIntent(
        normalizedTranslation: -30,
        normalizedVelocity: -240,
        activationDistance: 8
    ))
    #expect(!hasScrollDrivenPaneCollapseIntent(
        normalizedTranslation: 5,
        normalizedVelocity: 240,
        activationDistance: 8
    ))
    #expect(!hasScrollDrivenPaneCollapseIntent(
        normalizedTranslation: 12,
        normalizedVelocity: -80,
        activationDistance: 8
    ))
    #expect(hasScrollDrivenPaneCollapseIntent(
        normalizedTranslation: 12,
        normalizedVelocity: 240,
        activationDistance: 8
    ))
}

@Test @MainActor func paneScrollViewStoresLazyAnchorFallbackTarget() {
    let view = PaneScrollView(
        state: PaneScrollState(),
        collapsedScrollAnchorTag: AnyHashable("geometry-anchor"),
        collapsedScrollTargetTag: AnyHashable("current-row")
    ) {
        EmptyView()
    }

    #expect(view.collapsedScrollAnchorTag == AnyHashable("geometry-anchor"))
    #expect(view.collapsedScrollTargetTag == AnyHashable("current-row"))
}
