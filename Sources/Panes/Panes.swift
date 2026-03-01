import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Pane

public enum PaneDetent: Hashable {
    case fraction(CGFloat)
    case height(CGFloat)
    case medium
    case large

    fileprivate func resolvedHeight(maxHeight: CGFloat, safeAreaBottom: CGFloat) -> CGFloat {
        let resolved: CGFloat

        switch self {
        case let .fraction(fraction):
            resolved = maxHeight * fraction.clamped(to: 0.1...1.0)
        case let .height(height):
            resolved = height + safeAreaBottom
        case .medium:
            resolved = maxHeight * 0.5
        case .large:
            resolved = maxHeight
        }

        return resolved.clamped(to: 96...maxHeight)
    }
}

public enum PaneCrossAxisSize: Hashable {
    case fill
    case fraction(CGFloat)
    case fixed(CGFloat)
}

public typealias PaneWidth = PaneCrossAxisSize

public enum PaneExpansionAxis: String, Hashable {
    case vertical
    case horizontal
}

public struct PaneConfig {
    public var detents: [PaneDetent] = [.large]
    public var largestUndimmedDetent: PaneDetent? = nil
    public var showsDragIndicator: Bool

    public var allowsBackgroundInteraction: Bool
    public var tapOutsideToDismiss: Bool
    public var allowsSwipeToDismiss: Bool

    public var cornerRadius: CGFloat
    public var topInset: CGFloat
    public var horizontalPadding: CGFloat
    public var dimmingOpacity: CGFloat
    public var crossAxisSize: PaneCrossAxisSize
    public var anchor: Alignment
    public var expansionAxis: PaneExpansionAxis
    public var collapsedScrollAnchorTag: AnyHashable?
    public var collapsedScrollAnchor: UnitPoint
    public var keepsCollapsedScrollAnchorPinned: Bool
    public var dragIndicatorContentInset: CGFloat
    public var dragIndicatorFadeLength: CGFloat

    public var dismissThresholdMultiplier: CGFloat
    public var animation: Animation
    
    public init(
        detents: [PaneDetent] = [.large],
        largestUndimmedDetent: PaneDetent? = nil,
        showsDragIndicator: Bool = true,
        allowsBackgroundInteraction: Bool = false,
        tapOutsideToDismiss: Bool = true,
        allowsSwipeToDismiss: Bool = true,
        cornerRadius: CGFloat = 30,
        topInset: CGFloat = 12,
        horizontalPadding: CGFloat = 0,
        dimmingOpacity: CGFloat = 0.24,
        crossAxisSize: PaneCrossAxisSize = .fill,
        anchor: Alignment = .bottom,
        expansionAxis: PaneExpansionAxis = .vertical,
        collapsedScrollAnchorTag: AnyHashable? = nil,
        collapsedScrollAnchor: UnitPoint = .top,
        keepsCollapsedScrollAnchorPinned: Bool = false,
        dragIndicatorContentInset: CGFloat = 12,
        dragIndicatorFadeLength: CGFloat = 24,
        dismissThresholdMultiplier: CGFloat = 0.7,
        animation: Animation = .interactiveSpring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.2)
    ) {
        self.detents = detents
        self.largestUndimmedDetent = largestUndimmedDetent
        self.showsDragIndicator = showsDragIndicator
        self.allowsBackgroundInteraction = allowsBackgroundInteraction
        self.tapOutsideToDismiss = tapOutsideToDismiss
        self.allowsSwipeToDismiss = allowsSwipeToDismiss
        self.cornerRadius = cornerRadius
        self.topInset = topInset
        self.horizontalPadding = horizontalPadding
        self.dimmingOpacity = dimmingOpacity
        self.crossAxisSize = crossAxisSize
        self.anchor = anchor
        self.expansionAxis = expansionAxis
        self.collapsedScrollAnchorTag = collapsedScrollAnchorTag
        self.collapsedScrollAnchor = collapsedScrollAnchor
        self.keepsCollapsedScrollAnchorPinned = keepsCollapsedScrollAnchorPinned
        self.dragIndicatorContentInset = dragIndicatorContentInset
        self.dragIndicatorFadeLength = dragIndicatorFadeLength
        self.dismissThresholdMultiplier = dismissThresholdMultiplier
        self.animation = animation
    }
}

public final class PaneScrollState: ObservableObject {
    @Published public internal(set) var scrollOffset: CGFloat = 0
    @Published public internal(set) var maxScrollOffset: CGFloat = 0
    @Published public internal(set) var bottomEdgeDistance: CGFloat = .greatestFiniteMagnitude
    @Published public internal(set) var contentLength: CGFloat = 0
    @Published public internal(set) var viewportLength: CGFloat = 0
    @Published public internal(set) var scrollDisabled: Bool = true

    public init() {}
}

public struct PaneDetentSnapshot: Hashable {
    public let detent: PaneDetent
    public let height: CGFloat

    public init(detent: PaneDetent, height: CGFloat) {
        self.detent = detent
        self.height = height
    }
}

public struct PaneContext {
    public let scrollState: PaneScrollState
    public let isPresented: Binding<Bool>
    public let selectedDetent: Binding<PaneDetent>

    public let options: PaneConfig
    public let expansionAxis: PaneExpansionAxis
    public let anchor: Alignment

    public let detents: [PaneDetentSnapshot]
    public let minDetentHeight: CGFloat
    public let maxDetentHeight: CGFloat
    public let selectedDetentHeight: CGFloat
    public let interactiveHeight: CGFloat
    public let clampedInteractiveHeight: CGFloat
    public let expansionProgress: CGFloat

    public let dragTranslation: CGFloat
    public let isDraggingPane: Bool

    public let safeAreaInsets: EdgeInsets
    public let layoutBounds: CGRect
    public let frame: CGRect
    public let crossAxisLength: CGFloat

    public let backdropOpacity: CGFloat
    public let isDimmed: Bool
    public let blocksBackgroundInteraction: Bool
    public let isSelectedDetentFullyExpanded: Bool

    fileprivate let dismissAction: () -> Void

    public var scrollOffset: CGFloat { scrollState.scrollOffset }
    public var isScrollDisabled: Bool { scrollState.scrollDisabled }
    public var isAtMinDetent: Bool { abs(clampedInteractiveHeight - minDetentHeight) < 1 }
    public var isAtMaxDetent: Bool { abs(clampedInteractiveHeight - maxDetentHeight) < 1 }
    public var selectedDetentIndex: Int? {
        detents.firstIndex(where: { $0.detent == selectedDetent.wrappedValue })
    }

    public var selectedDetentLabel: String {
        Self.label(for: selectedDetent.wrappedValue)
    }

    public func dismiss() {
        dismissAction()
    }

    private static func label(for detent: PaneDetent) -> String {
        switch detent {
        case .medium:
            return "medium"
        case .large:
            return "large"
        case let .fraction(value):
            return "\(Int((value * 100).rounded()))%"
        case let .height(value):
            return "\(Int(value.rounded()))pt"
        }
    }
}

private struct PaneScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollContentLengthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollViewportLengthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollViewportMinYKey: PreferenceKey {
    static let defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollViewportMaxYKey: PreferenceKey {
    static let defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollBottomMarkerMaxYKey: PreferenceKey {
    static let defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PaneScrollChrome: Equatable {
    var indicatorInsets: EdgeInsets = .init()
    var fadeLength: CGFloat = 0
}

private struct PaneScrollChromeKey: EnvironmentKey {
    static let defaultValue = PaneScrollChrome()
}

private extension EnvironmentValues {
    var paneScrollChrome: PaneScrollChrome {
        get { self[PaneScrollChromeKey.self] }
        set { self[PaneScrollChromeKey.self] = newValue }
    }
}

private struct PaneInteractiveAnchorProgressKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
    var paneInteractiveAnchorProgress: CGFloat {
        get { self[PaneInteractiveAnchorProgressKey.self] }
        set { self[PaneInteractiveAnchorProgressKey.self] = newValue }
    }
}

#if canImport(UIKit)
private struct PaneUIKitScrollMetricsBridge: UIViewRepresentable {
    @ObservedObject var state: PaneScrollState

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PaneIntrospectionView {
        let view = PaneIntrospectionView()
        view.onLayoutOrAttach = { hostView in
            Task { @MainActor in
                context.coordinator.attachIfPossible(from: hostView, state: state)
            }
        }
        return view
    }

    func updateUIView(_ uiView: PaneIntrospectionView, context: Context) {
        uiView.onLayoutOrAttach = { hostView in
            Task { @MainActor in
                context.coordinator.attachIfPossible(from: hostView, state: state)
            }
        }
        Task { @MainActor in
            context.coordinator.attachIfPossible(from: uiView, state: state)
        }
    }

    static func dismantleUIView(_ uiView: PaneIntrospectionView, coordinator: Coordinator) {
        Task { @MainActor in
            coordinator.detach()
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        private weak var scrollView: UIScrollView?
        private weak var state: PaneScrollState?
        private var contentOffsetObserver: NSKeyValueObservation?
        private var contentSizeObserver: NSKeyValueObservation?
        private var boundsObserver: NSKeyValueObservation?
        private var contentInsetObserver: NSKeyValueObservation?

        func attachIfPossible(from view: UIView, state: PaneScrollState) {
            guard let resolvedScrollView = enclosingScrollView(from: view) else { return }
            attach(to: resolvedScrollView, state: state)
        }

        func detach() {
            invalidateObservers()
            scrollView = nil
            state = nil
        }

        private func attach(to resolvedScrollView: UIScrollView, state: PaneScrollState) {
            if scrollView !== resolvedScrollView {
                invalidateObservers()
                scrollView = resolvedScrollView
                contentOffsetObserver = resolvedScrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] _, _ in
                    Task { @MainActor in
                        self?.publishMetrics()
                    }
                }
                contentSizeObserver = resolvedScrollView.observe(\.contentSize, options: [.initial, .new]) { [weak self] _, _ in
                    Task { @MainActor in
                        self?.publishMetrics()
                    }
                }
                boundsObserver = resolvedScrollView.observe(\.bounds, options: [.initial, .new]) { [weak self] _, _ in
                    Task { @MainActor in
                        self?.publishMetrics()
                    }
                }
                contentInsetObserver = resolvedScrollView.observe(\.contentInset, options: [.initial, .new]) { [weak self] _, _ in
                    Task { @MainActor in
                        self?.publishMetrics()
                    }
                }
            }

            self.state = state
            publishMetrics()
        }

        private func publishMetrics() {
            guard let scrollView, let state else { return }

            let inset = scrollView.adjustedContentInset
            let offset = max(0, scrollView.contentOffset.y + inset.top)
            let contentLength = max(0, scrollView.contentSize.height + inset.top + inset.bottom)
            let viewportLength = max(0, scrollView.bounds.height)
            let maxOffset = max(0, contentLength - viewportLength)
            let bottomEdgeDistance = max(0, maxOffset - offset)

            if abs(state.scrollOffset - offset) > 0.5 {
                state.scrollOffset = offset
            }
            if abs(state.contentLength - contentLength) > 0.5 {
                state.contentLength = contentLength
            }
            if abs(state.viewportLength - viewportLength) > 0.5 {
                state.viewportLength = viewportLength
            }
            if abs(state.maxScrollOffset - maxOffset) > 0.5 {
                state.maxScrollOffset = maxOffset
            }
            if abs(state.bottomEdgeDistance - bottomEdgeDistance) > 0.5 {
                state.bottomEdgeDistance = bottomEdgeDistance
            }
        }

        private func invalidateObservers() {
            contentOffsetObserver?.invalidate()
            contentSizeObserver?.invalidate()
            boundsObserver?.invalidate()
            contentInsetObserver?.invalidate()
            contentOffsetObserver = nil
            contentSizeObserver = nil
            boundsObserver = nil
            contentInsetObserver = nil
        }

        private func enclosingScrollView(from view: UIView) -> UIScrollView? {
            var node: UIView? = view
            while let current = node {
                if let scrollView = current as? UIScrollView {
                    return scrollView
                }
                node = current.superview
            }
            return nil
        }
    }

    final class PaneIntrospectionView: UIView {
        var onLayoutOrAttach: ((UIView) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                onLayoutOrAttach?(self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            onLayoutOrAttach?(self)
        }
    }
}
#endif

public struct PaneScrollView<Content: View>: View {
    @ObservedObject var state: PaneScrollState
    @Environment(\.paneScrollChrome) private var paneScrollChrome
    @Environment(\.paneInteractiveAnchorProgress) private var paneInteractiveAnchorProgress
    let collapsedScrollAnchorTag: AnyHashable?
    let shouldPinCollapsedScrollAnchor: Bool
    let collapsedScrollAnchor: UnitPoint
    let content: () -> Content
    @State private var scrollSpaceID = UUID()
    @State private var latestTopMarkerGlobalY: CGFloat = .greatestFiniteMagnitude
    @State private var latestViewportGlobalMinY: CGFloat = .greatestFiniteMagnitude
    @State private var latestBottomMarkerGlobalMaxY: CGFloat = .greatestFiniteMagnitude
    @State private var latestViewportGlobalMaxY: CGFloat = .greatestFiniteMagnitude
    @State private var lastAppliedInteractiveAnchorProgress: CGFloat = 0

    public init(
        state: PaneScrollState,
        collapsedScrollAnchorTag: AnyHashable? = nil,
        shouldPinCollapsedScrollAnchor: Bool = false,
        collapsedScrollAnchor: UnitPoint = .top,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.collapsedScrollAnchorTag = collapsedScrollAnchorTag
        self.shouldPinCollapsedScrollAnchor = shouldPinCollapsedScrollAnchor
        self.collapsedScrollAnchor = collapsedScrollAnchor
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    #if canImport(UIKit)
                    PaneUIKitScrollMetricsBridge(state: state)
                        .frame(width: 0, height: 0)
                        .allowsHitTesting(false)
                    #endif

                    GeometryReader { proxy in
                        Color.clear
                            .frame(height: 0)
                            .preference(
                                key: PaneScrollOffsetKey.self,
                                value: proxy.frame(in: .global).minY
                            )
                    }
                    .frame(height: 0)

                    content()
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, paneScrollChrome.indicatorInsets.top)
                        .padding(.leading, paneScrollChrome.indicatorInsets.leading)
                        .padding(.bottom, paneScrollChrome.indicatorInsets.bottom)
                        .padding(.trailing, paneScrollChrome.indicatorInsets.trailing)

                    GeometryReader { proxy in
                        Color.clear
                            .frame(height: 0)
                            .preference(
                                key: PaneScrollBottomMarkerMaxYKey.self,
                                value: proxy.frame(in: .global).maxY
                            )
                    }
                    .frame(height: 0)
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: PaneScrollContentLengthKey.self,
                            value: proxy.size.height
                        )
                    }
                }
            }
            .coordinateSpace(name: scrollSpaceID)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PaneScrollViewportLengthKey.self,
                        value: proxy.size.height
                    )
                    .preference(
                        key: PaneScrollViewportMinYKey.self,
                        value: proxy.frame(in: .global).minY
                    )
                    .preference(
                        key: PaneScrollViewportMaxYKey.self,
                        value: proxy.frame(in: .global).maxY
                    )
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .paneEdgeFadeMask(
                edge: .top,
                isEnabled: paneScrollChrome.indicatorInsets.top > 0.5,
                length: paneScrollChrome.fadeLength
            )
            .paneEdgeFadeMask(
                edge: .bottom,
                isEnabled: paneScrollChrome.indicatorInsets.bottom > 0.5,
                length: paneScrollChrome.fadeLength
            )
            .paneEdgeFadeMask(
                edge: .leading,
                isEnabled: paneScrollChrome.indicatorInsets.leading > 0.5,
                length: paneScrollChrome.fadeLength
            )
            .paneEdgeFadeMask(
                edge: .trailing,
                isEnabled: paneScrollChrome.indicatorInsets.trailing > 0.5,
                length: paneScrollChrome.fadeLength
            )
            .scrollDisabled(state.scrollDisabled)
            #if !canImport(UIKit)
            .onPreferenceChange(PaneScrollOffsetKey.self) { topMarkerGlobalY in
                updateScrollOffset(topMarkerGlobalY: topMarkerGlobalY, viewportGlobalMinY: nil)
            }
            .onPreferenceChange(PaneScrollContentLengthKey.self) { contentLength in
                updateScrollMetrics(contentLength: contentLength, viewportLength: nil)
            }
            .onPreferenceChange(PaneScrollViewportLengthKey.self) { viewportLength in
                updateScrollMetrics(contentLength: nil, viewportLength: viewportLength)
            }
            .onPreferenceChange(PaneScrollViewportMinYKey.self) { viewportGlobalMinY in
                updateScrollOffset(topMarkerGlobalY: nil, viewportGlobalMinY: viewportGlobalMinY)
            }
            .onPreferenceChange(PaneScrollBottomMarkerMaxYKey.self) { bottomMarkerGlobalMaxY in
                updateBottomEdgeDistance(bottomMarkerGlobalMaxY: bottomMarkerGlobalMaxY, viewportGlobalMaxY: nil)
            }
            .onPreferenceChange(PaneScrollViewportMaxYKey.self) { viewportGlobalMaxY in
                updateBottomEdgeDistance(bottomMarkerGlobalMaxY: nil, viewportGlobalMaxY: viewportGlobalMaxY)
            }
            #endif
            .onChange(of: state.scrollDisabled, initial: true) { _, disabled in
                if disabled {
                    pinCollapsedAnchorIfNeeded(using: proxy)
                }
            }
            .onChange(of: paneInteractiveAnchorProgress, initial: true) { oldProgress, newProgress in
                pinCollapsedAnchorInteractivelyIfNeeded(
                    from: oldProgress,
                    to: newProgress,
                    using: proxy
                )
            }
            .onChange(of: shouldPinCollapsedScrollAnchor, initial: true) { _, shouldPin in
                guard shouldPin else { return }
                pinCollapsedAnchorIfNeeded(using: proxy)
            }
            .onChange(of: collapsedScrollAnchorTag, initial: false) { _, _ in
                pinCollapsedAnchorIfNeeded(using: proxy)
            }
        }
    }

    private func pinCollapsedAnchorIfNeeded(using proxy: ScrollViewProxy) {
        guard shouldPinCollapsedScrollAnchor else { return }
        guard let collapsedScrollAnchorTag else { return }

        lastAppliedInteractiveAnchorProgress = 1
        DispatchQueue.main.async {
            proxy.scrollTo(collapsedScrollAnchorTag, anchor: collapsedScrollAnchor)
        }
    }

    private func pinCollapsedAnchorInteractivelyIfNeeded(
        from oldProgress: CGFloat,
        to newProgress: CGFloat,
        using proxy: ScrollViewProxy
    ) {
        guard !shouldPinCollapsedScrollAnchor else { return }
        guard let collapsedScrollAnchorTag else { return }

        let clampedOld = oldProgress.clamped(to: 0...1)
        let clampedNew = newProgress.clamped(to: 0...1)

        if clampedNew <= 0.001 {
            lastAppliedInteractiveAnchorProgress = 0
            return
        }

        if clampedNew + 0.001 < clampedOld {
            return
        }

        if clampedNew <= lastAppliedInteractiveAnchorProgress + 0.015 {
            return
        }

        lastAppliedInteractiveAnchorProgress = clampedNew
        let duration = 0.07 + (0.17 * Double(clampedNew))
        DispatchQueue.main.async {
            withAnimation(.linear(duration: duration)) {
                proxy.scrollTo(collapsedScrollAnchorTag, anchor: collapsedScrollAnchor)
            }
        }
    }

    private func updateScrollMetrics(contentLength: CGFloat?, viewportLength: CGFloat?) {
        let resolvedContentLength = max(0, contentLength ?? state.contentLength)
        let resolvedViewportLength = max(0, viewportLength ?? state.viewportLength)

        if abs(state.contentLength - resolvedContentLength) > 0.5 {
            state.contentLength = resolvedContentLength
        }
        if abs(state.viewportLength - resolvedViewportLength) > 0.5 {
            state.viewportLength = resolvedViewportLength
        }

        let maxOffset = max(0, resolvedContentLength - resolvedViewportLength)
        if abs(state.maxScrollOffset - maxOffset) > 0.5 {
            state.maxScrollOffset = maxOffset
        }
    }

    private func updateScrollOffset(topMarkerGlobalY: CGFloat?, viewportGlobalMinY: CGFloat?) {
        let resolvedTopMarkerGlobalY: CGFloat
        if let topMarkerGlobalY {
            latestTopMarkerGlobalY = topMarkerGlobalY
            resolvedTopMarkerGlobalY = topMarkerGlobalY
        } else {
            resolvedTopMarkerGlobalY = latestTopMarkerGlobalY
        }

        let resolvedViewportGlobalMinY: CGFloat
        if let viewportGlobalMinY {
            latestViewportGlobalMinY = viewportGlobalMinY
            resolvedViewportGlobalMinY = viewportGlobalMinY
        } else {
            resolvedViewportGlobalMinY = latestViewportGlobalMinY
        }

        guard resolvedTopMarkerGlobalY.isFinite, resolvedViewportGlobalMinY.isFinite else {
            return
        }

        let offset = max(0, resolvedViewportGlobalMinY - resolvedTopMarkerGlobalY)
        if abs(state.scrollOffset - offset) > 0.5 {
            state.scrollOffset = offset
        }
    }

    private func updateBottomEdgeDistance(bottomMarkerGlobalMaxY: CGFloat?, viewportGlobalMaxY: CGFloat?) {
        let resolvedBottomMarkerGlobalMaxY: CGFloat
        if let bottomMarkerGlobalMaxY {
            latestBottomMarkerGlobalMaxY = bottomMarkerGlobalMaxY
            resolvedBottomMarkerGlobalMaxY = bottomMarkerGlobalMaxY
        } else {
            resolvedBottomMarkerGlobalMaxY = latestBottomMarkerGlobalMaxY
        }

        let resolvedViewportGlobalMaxY: CGFloat
        if let viewportGlobalMaxY {
            latestViewportGlobalMaxY = viewportGlobalMaxY
            resolvedViewportGlobalMaxY = viewportGlobalMaxY
        } else {
            resolvedViewportGlobalMaxY = latestViewportGlobalMaxY
        }

        guard resolvedBottomMarkerGlobalMaxY.isFinite, resolvedViewportGlobalMaxY.isFinite else {
            return
        }

        let distance = max(0, resolvedBottomMarkerGlobalMaxY - resolvedViewportGlobalMaxY)
        if abs(state.bottomEdgeDistance - distance) > 0.5 {
            state.bottomEdgeDistance = distance
        }
    }
}

private enum PaneFadeEdge {
    case top
    case bottom
    case leading
    case trailing
}

private struct PaneEdgeFadeMaskModifier: ViewModifier {
    let edge: PaneFadeEdge
    let isEnabled: Bool
    let length: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled, length > 0.5 {
            content.mask {
                GeometryReader { proxy in
                    let majorLength = max(
                        1,
                        edge == .leading || edge == .trailing ? proxy.size.width : proxy.size.height
                    )
                    let fade = min(max(0, length), majorLength * 0.45)
                    let location = min(1, fade / majorLength)

                    switch edge {
                    case .top:
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: location),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    case .bottom:
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: max(0, 1 - location)),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    case .leading:
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: location),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    case .trailing:
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: max(0, 1 - location)),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            }
        } else {
            content
        }
    }
}

private struct PaneBlurReplaceFallbackModifier: ViewModifier {
    let blurRadius: CGFloat
    let opacity: CGFloat
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
            .opacity(opacity)
            .scaleEffect(scale)
    }
}

private struct PaneSlideTransitionModifier: ViewModifier {
    let xOffset: CGFloat
    let yOffset: CGFloat

    func body(content: Content) -> some View {
        content.offset(x: xOffset, y: yOffset)
    }
}

private extension View {
    func paneEdgeFadeMask(edge: PaneFadeEdge, isEnabled: Bool, length: CGFloat) -> some View {
        modifier(PaneEdgeFadeMaskModifier(edge: edge, isEnabled: isEnabled, length: length))
    }
}

public extension View {
    func paneAnchorTag<ID: Hashable>(_ id: ID, topOffset: CGFloat = 16) -> some View {
        modifier(PaneAnchorTagModifier(id: AnyHashable(id), topOffset: topOffset))
    }

    func pane<SheetContent: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<PaneDetent>,
        config: PaneConfig = .init(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (PaneContext) -> SheetContent
    ) -> some View {
        modifier(
            PaneModifier(
                isPresented: isPresented,
                selectedDetent: selectedDetent,
                options: config,
                onDismiss: onDismiss,
                paneContent: content
            )
        )
    }

    func pane<SheetContent: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<PaneDetent>,
        config: PaneConfig = .init(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (PaneScrollState) -> SheetContent
    ) -> some View {
        pane(
            isPresented: isPresented,
            selectedDetent: selectedDetent,
            config: config,
            onDismiss: onDismiss
        ) { context in
            content(context.scrollState)
        }
    }
}

private struct PaneAnchorTagModifier: ViewModifier {
    let id: AnyHashable
    let topOffset: CGFloat

    func body(content: Content) -> some View {
        // Keep normal layout unchanged, but create a real in-flow anchor region above this
        // view so ScrollViewReader can reliably align with extra headroom.
        let markerHeight = max(1, topOffset + 16)
        return VStack(spacing: 0) {
            Color.clear
                .frame(height: markerHeight)
                .allowsHitTesting(false)
                .id(id)
            content
        }
        .padding(.top, -markerHeight)
    }
}

private struct ResolvedPaneDetent {
    let detent: PaneDetent
    let height: CGFloat
}

public struct PaneModifier<SheetContent: View>: ViewModifier {
    private enum DragMode {
        case pane
        case content
    }

    @Binding var isPresented: Bool
    @Binding var selectedDetent: PaneDetent
    let options: PaneConfig
    let onDismiss: (() -> Void)?
    public let paneContent: (PaneContext) -> SheetContent

    @StateObject private var scrollState = PaneScrollState()
    @State private var dragTranslation: CGFloat = 0
    @State private var dismissSlideOffset: CGFloat = 0
    @State private var isDragDismissAnimating = false
    @State private var isDraggingPane = false
    @State private var dragMode: DragMode? = nil
    @State private var paneCaptureStartTranslation: CGFloat = 0
    @State private var activeExpansionSign: CGFloat = 1
    @State private var didCaptureDragStart = false
    @State private var dragStartedOnIndicator = false
    @State private var dragStartedAtCollapseEdge = false
    @State private var scrollUnlockToken = 0
    private let nonMaxDetentLockThreshold: CGFloat = 2
    private let maxDetentDownwardLockThreshold: CGFloat = 12
    private let maxDetentUpwardLockThreshold: CGFloat = 4
    private let topHandoffTolerance: CGFloat = 1.5
    private let snapBoundaryHysteresis: CGFloat = 12
    private let snapHoldThreshold: CGFloat = 18
    private let enableScrollDelayAfterSnap: TimeInterval = 0.16
    private let releaseVelocityProjectionSeconds: CGFloat = 0.22
    private let velocityHeightInfluenceSeconds: CGFloat = 0.12
    private let flingVelocityThreshold: CGFloat = 1100
    private let strongFlingVelocityThreshold: CGFloat = 2100
    private let maxBottomOvershoot: CGFloat = 96
    private let bottomOvershootResistance: CGFloat = 0.85
    private let dragDismissCompletionDelay: TimeInterval = 0.42
    private let dragDismissAnimationSpeed: Double = 0.8

    public func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let safeAreaInsets = resolvedSafeAreaInsets(from: proxy)
                    let layoutBounds = paneLayoutBounds(in: proxy, safeAreaInsets: safeAreaInsets)
                    let maxExpansionLength = options.expansionAxis == .vertical ? layoutBounds.height : layoutBounds.width
                    let detents = resolvedDetents(
                        maxHeight: maxExpansionLength,
                        safeAreaBottom: options.expansionAxis == .vertical ? safeAreaInsets.bottom : 0
                    )
                    let minHeight = detents.first?.height ?? 0
                    let maxHeight = detents.last?.height ?? 0
                    let selectedHeight = height(
                        for: selectedDetent,
                        in: detents,
                        maxHeight: maxHeight,
                        safeAreaBottom: safeAreaInsets.bottom
                    )
                    let interactiveHeight = paneHeight(
                        forSelectedHeight: selectedHeight,
                        dragTranslation: dragTranslation,
                        minHeight: minHeight,
                        maxHeight: maxHeight
                    )
                    let crossAxisLength = resolvedCrossAxisLength(
                        in: layoutBounds
                    )
                    let paneFrame = paneFrame(
                        in: layoutBounds,
                        expansionLength: interactiveHeight,
                        crossAxisLength: crossAxisLength
                    )
                    let paneGlobalFrame = paneFrame.offsetBy(
                        dx: proxy.frame(in: .global).minX,
                        dy: proxy.frame(in: .global).minY
                    )
                    let effectiveInteractiveHeight = interactiveHeight.clamped(to: minHeight...maxHeight)
                    let expansionProgress = progress(
                        height: effectiveInteractiveHeight,
                        minHeight: minHeight,
                        maxHeight: maxHeight
                    )
                    let isSelectedDetentFullyExpanded = isAtMax(
                        currentHeight: selectedHeight,
                        maxHeight: maxHeight
                    )
                    let dimmed = shouldDimBackground(
                        interactiveHeight: effectiveInteractiveHeight,
                        detents: detents,
                        maxHeight: maxHeight,
                        safeAreaBottom: safeAreaInsets.bottom
                    )
                    let backdropOpacity = dimmed
                    ? options.dimmingOpacity * progress(height: effectiveInteractiveHeight, minHeight: minHeight, maxHeight: maxHeight)
                    : 0
                    let blockBackgroundTouches = shouldBlockBackground(
                        interactiveHeight: effectiveInteractiveHeight,
                        detents: detents,
                        maxHeight: maxHeight,
                        safeAreaBottom: safeAreaInsets.bottom
                    )
                    let needsBackdropLayer =
                        backdropOpacity > 0.0001 ||
                        blockBackgroundTouches ||
                        (options.tapOutsideToDismiss && !options.allowsBackgroundInteraction)
                    let indicatorContentInsets = paneIndicatorContentInsets
                    let scrollChrome = PaneScrollChrome(
                        indicatorInsets: indicatorContentInsets,
                        fadeLength: max(0, options.dragIndicatorFadeLength)
                    )
                    let interactiveAnchorProgress = collapsedAnchorInteractiveProgress(
                        interactiveHeight: effectiveInteractiveHeight,
                        minHeight: minHeight,
                        maxHeight: maxHeight,
                        isDraggingPane: isDraggingPane,
                        dragTranslation: dragTranslation
                    )
                    let paneContext = PaneContext(
                        scrollState: scrollState,
                        isPresented: $isPresented,
                        selectedDetent: $selectedDetent,
                        options: options,
                        expansionAxis: options.expansionAxis,
                        anchor: options.anchor,
                        detents: detents.map {
                            PaneDetentSnapshot(detent: $0.detent, height: $0.height)
                        },
                        minDetentHeight: minHeight,
                        maxDetentHeight: maxHeight,
                        selectedDetentHeight: selectedHeight,
                        interactiveHeight: interactiveHeight,
                        clampedInteractiveHeight: effectiveInteractiveHeight,
                        expansionProgress: expansionProgress,
                        dragTranslation: dragTranslation,
                        isDraggingPane: isDraggingPane,
                        safeAreaInsets: safeAreaInsets,
                        layoutBounds: layoutBounds,
                        frame: paneFrame,
                        crossAxisLength: crossAxisLength,
                        backdropOpacity: backdropOpacity,
                        isDimmed: dimmed,
                        blocksBackgroundInteraction: blockBackgroundTouches,
                        isSelectedDetentFullyExpanded: isSelectedDetentFullyExpanded,
                        dismissAction: {
                            dismiss()
                        }
                    )

                    ZStack(alignment: .bottom) {
                        if isPresented || isDragDismissAnimating {
                            if needsBackdropLayer {
                                Color.black.opacity(backdropOpacity)
                                    .contentShape(Rectangle())
                                    .ignoresSafeArea()
                                    .allowsHitTesting(blockBackgroundTouches)
                                    .onTapGesture {
                                        guard blockBackgroundTouches, options.tapOutsideToDismiss else { return }
                                        dismiss()
                                    }
                            }

                            VStack(spacing: 0) {
                                paneContent(paneContext)
                                    .environment(\.paneScrollChrome, scrollChrome)
                                    .environment(\.paneInteractiveAnchorProgress, interactiveAnchorProgress)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            }
                            .frame(width: paneFrame.width, height: paneFrame.height, alignment: .top)
                            .background {
                                RoundedRectangle(cornerRadius: options.cornerRadius, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: options.cornerRadius, style: .continuous)
                                    .strokeBorder(.white.opacity(0.07), lineWidth: 0.8)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: options.cornerRadius, style: .continuous))
                            .shadow(color: .black.opacity(0.16), radius: 30, y: -3)
                            .overlay {
                                if options.showsDragIndicator {
                                    ZStack {
                                        ForEach(Array(dragIndicatorAlignments.enumerated()), id: \.offset) { _, alignment in
                                            dragIndicatorView
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                                        }
                                    }
                                }
                            }
                            .position(x: paneFrame.midX, y: paneFrame.midY)
                            .offset(
                                x: options.expansionAxis == .horizontal ? dismissSlideOffset : 0,
                                y: options.expansionAxis == .vertical ? dismissSlideOffset : 0
                            )
                            .transition(panePresentationTransition)
                            .simultaneousGesture(
                                dragGesture(
                                    detents: detents,
                                    selectedHeight: selectedHeight,
                                    minHeight: minHeight,
                                    maxHeight: maxHeight,
                                    paneGlobalFrame: paneGlobalFrame
                                ),
                                including: .all
                            )
                            .onAppear {
                                alignSelection(to: detents, maxHeight: maxHeight, safeAreaBottom: safeAreaInsets.bottom)
                                updateScrollInteractivity(
                                    forTargetHeight: selectedHeight,
                                    fromCurrentHeight: selectedHeight,
                                    maxHeight: maxHeight
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .animation(options.animation, value: isPresented)
                    .onChange(of: selectedDetent, initial: false) { oldDetent, newDetent in
                        let oldHeight = height(
                            for: oldDetent,
                            in: detents,
                            maxHeight: maxHeight,
                            safeAreaBottom: safeAreaInsets.bottom
                        )
                        let newHeight = height(
                            for: newDetent,
                            in: detents,
                            maxHeight: maxHeight,
                            safeAreaBottom: safeAreaInsets.bottom
                        )
                        updateScrollInteractivity(
                            forTargetHeight: newHeight,
                            fromCurrentHeight: oldHeight,
                            maxHeight: maxHeight
                        )
                    }
                    .onChange(of: isPresented, initial: false) { _, presented in
                        if presented {
                            dragTranslation = 0
                            dismissSlideOffset = 0
                            isDragDismissAnimating = false
                            isDraggingPane = false
                            dragMode = nil
                            paneCaptureStartTranslation = 0
                            activeExpansionSign = 1
                            didCaptureDragStart = false
                            dragStartedOnIndicator = false
                            dragStartedAtCollapseEdge = false
                            alignSelection(to: detents, maxHeight: maxHeight, safeAreaBottom: safeAreaInsets.bottom)
                        } else {
                            // Keep interactive state stable during dismissal so transition can animate out.
                            scrollUnlockToken += 1
                        }
                    }
                }
                
                .ignoresSafeArea(edges: .bottom)
            }
    }

    private func dragGesture(
        detents: [ResolvedPaneDetent],
        selectedHeight: CGFloat,
        minHeight: CGFloat,
        maxHeight: CGFloat,
        paneGlobalFrame: CGRect
    ) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let axisTranslation = primaryAxisTranslation(from: value.translation)

                if dragMode == nil {
                    if !didCaptureDragStart {
                        dragStartedOnIndicator = isPointInIndicatorActivationZone(
                            startLocation: value.startLocation,
                            paneFrame: paneGlobalFrame
                        )
                        activeExpansionSign = inferredExpansionSign(
                            startLocation: value.startLocation,
                            paneFrame: paneGlobalFrame
                        )
                        dragStartedAtCollapseEdge = isAtCollapseEdge(
                            expansionSign: activeExpansionSign,
                            scrollOffset: scrollState.scrollOffset,
                            bottomEdgeDistance: scrollState.bottomEdgeDistance
                        )
                        didCaptureDragStart = true
                    }

                    let normalizedTranslation = normalizedPaneTranslation(
                        axisTranslation: axisTranslation,
                        expansionSign: activeExpansionSign
                    )

                    if !isAtMax(currentHeight: selectedHeight, maxHeight: maxHeight) {
                        guard abs(normalizedTranslation) > nonMaxDetentLockThreshold else { return }
                        dragMode = .pane
                        isDraggingPane = true
                        paneCaptureStartTranslation = normalizedTranslation
                        setScrollDisabled(true)
                    } else {
                        if normalizedTranslation >= maxDetentDownwardLockThreshold {
                            let drivesSheet = shouldDrivePane(
                                translation: normalizedTranslation,
                                expansionSign: activeExpansionSign,
                                selectedHeight: selectedHeight,
                                maxHeight: maxHeight,
                                scrollOffset: scrollState.scrollOffset,
                                bottomEdgeDistance: scrollState.bottomEdgeDistance,
                                dragStartedOnIndicator: dragStartedOnIndicator,
                                dragStartedAtCollapseEdge: dragStartedAtCollapseEdge
                            )
                            dragMode = drivesSheet ? .pane : .content
                            isDraggingPane = drivesSheet
                            paneCaptureStartTranslation = drivesSheet ? normalizedTranslation : 0
                            setScrollDisabled(drivesSheet)
                        } else if normalizedTranslation <= -maxDetentUpwardLockThreshold {
                            dragMode = .content
                            isDraggingPane = false
                            paneCaptureStartTranslation = 0
                            setScrollDisabled(false)
                        } else {
                            return
                        }
                    }
                }

                guard dragMode == .pane else {
                    dragTranslation = 0
                    return
                }

                let normalizedTranslation = normalizedPaneTranslation(
                    axisTranslation: axisTranslation,
                    expansionSign: activeExpansionSign
                )
                dragTranslation = normalizedTranslation - paneCaptureStartTranslation
                setScrollDisabled(true)
            }
            .onEnded { value in
                let captureStartTranslation = paneCaptureStartTranslation
                let endingMode = dragMode
                isDraggingPane = false
                dragMode = nil
                paneCaptureStartTranslation = 0
                let expansionSign = activeExpansionSign
                activeExpansionSign = 1
                didCaptureDragStart = false
                dragStartedOnIndicator = false
                dragStartedAtCollapseEdge = false

                guard endingMode == .pane else {
                    withAnimation(options.animation) {
                        dragTranslation = 0
                    }
                    updateScrollInteractivity(
                        forTargetHeight: selectedHeight,
                        fromCurrentHeight: selectedHeight,
                        maxHeight: maxHeight
                    )
                    return
                }

                let translation = normalizedPaneTranslation(
                    axisTranslation: primaryAxisTranslation(from: value.translation),
                    expansionSign: expansionSign
                ) - captureStartTranslation
                let predictedTranslation = normalizedPaneTranslation(
                    axisTranslation: primaryAxisTranslation(from: value.predictedEndTranslation),
                    expansionSign: expansionSign
                ) - captureStartTranslation
                let releaseVelocity = estimatedReleaseVelocity(
                    translation: translation,
                    predictedTranslation: predictedTranslation
                )
                let rawCurrentHeight = selectedHeight - translation
                let currentHeight = paneHeight(
                    forSelectedHeight: selectedHeight,
                    dragTranslation: translation,
                    minHeight: minHeight,
                    maxHeight: maxHeight
                )

                if options.allowsSwipeToDismiss, rawCurrentHeight < (minHeight * options.dismissThresholdMultiplier) {
                    beginDragDismiss(
                        translation: translation,
                        expansionSign: expansionSign
                    )
                    return
                }

                let velocityAdjustedHeight = (currentHeight - (releaseVelocity * velocityHeightInfluenceSeconds))
                    .clamped(to: minHeight...maxHeight)

                let target = snapTarget(
                    projectedHeight: velocityAdjustedHeight,
                    startingHeight: selectedHeight,
                    releaseVelocity: releaseVelocity,
                    in: detents
                )
                withAnimation(options.animation) {
                    dragTranslation = 0
                    selectedDetent = target.detent
                }
                updateScrollInteractivity(
                    forTargetHeight: target.height,
                    fromCurrentHeight: currentHeight,
                    maxHeight: maxHeight
                )
            }
    }

    private func shouldDrivePane(
        translation: CGFloat,
        expansionSign: CGFloat,
        selectedHeight: CGFloat,
        maxHeight: CGFloat,
        scrollOffset: CGFloat,
        bottomEdgeDistance: CGFloat,
        dragStartedOnIndicator: Bool,
        dragStartedAtCollapseEdge: Bool
    ) -> Bool {
        if dragStartedOnIndicator {
            return true
        }

        if !isAtMax(currentHeight: selectedHeight, maxHeight: maxHeight) {
            return true
        }

        guard translation > 0 else {
            return false
        }

        guard dragStartedAtCollapseEdge else {
            return false
        }

        switch options.expansionAxis {
        case .vertical:
            return isAtCollapseEdge(
                expansionSign: expansionSign,
                scrollOffset: scrollOffset,
                bottomEdgeDistance: bottomEdgeDistance
            )
        case .horizontal:
            // Scroll content is vertical; horizontal pane resizing at max should only begin from the indicator.
            return false
        }
    }

    private func isAtCollapseEdge(
        expansionSign: CGFloat,
        scrollOffset: CGFloat,
        bottomEdgeDistance: CGFloat
    ) -> Bool {
        switch options.expansionAxis {
        case .vertical:
            let collapseAxisDirection = -expansionSign
            if collapseAxisDirection > 0 {
                // Pulling toward the top edge of content (e.g. drag down in a bottom-anchored pane).
                return scrollOffset <= topHandoffTolerance
            } else {
                // Pulling toward the bottom edge of content (e.g. drag up in a top-anchored pane).
                return bottomEdgeDistance <= topHandoffTolerance
            }
        case .horizontal:
            return false
        }
    }

    private func isPointInIndicatorActivationZone(startLocation: CGPoint, paneFrame: CGRect) -> Bool {
        guard options.showsDragIndicator else { return false }

        // A forgiving hit region around the visible handle allows intentional pane drags
        // without stealing regular content scrolling.
        let visualLength: CGFloat = 36
        let visualThickness: CGFloat = 5
        let indicatorPadding: CGFloat = 10
        let handleLength = visualLength + 14
        let handleThickness = visualThickness + (indicatorPadding * 2) + 8
        let hitSlop: CGFloat = 4

        for alignment in dragIndicatorAlignments {
            let baseRect: CGRect
            switch alignment {
            case .top:
                baseRect = CGRect(
                    x: paneFrame.midX - (handleLength / 2),
                    y: paneFrame.minY,
                    width: handleLength,
                    height: handleThickness
                )
            case .bottom:
                baseRect = CGRect(
                    x: paneFrame.midX - (handleLength / 2),
                    y: paneFrame.maxY - handleThickness,
                    width: handleLength,
                    height: handleThickness
                )
            case .leading:
                baseRect = CGRect(
                    x: paneFrame.minX,
                    y: paneFrame.midY - (handleLength / 2),
                    width: handleThickness,
                    height: handleLength
                )
            case .trailing:
                baseRect = CGRect(
                    x: paneFrame.maxX - handleThickness,
                    y: paneFrame.midY - (handleLength / 2),
                    width: handleThickness,
                    height: handleLength
                )
            default:
                continue
            }

            if baseRect.insetBy(dx: -hitSlop, dy: -hitSlop).contains(startLocation) {
                return true
            }
        }

        return false
    }

    private func paneLayoutBounds(in proxy: GeometryProxy, safeAreaInsets: EdgeInsets) -> CGRect {
        let globalFrame = proxy.frame(in: .global)
        #if canImport(UIKit)
        let windowBounds = currentWindowBounds() ?? CGRect(origin: .zero, size: proxy.size)
        #else
        let windowBounds = CGRect(origin: .zero, size: proxy.size)
        #endif

        let topGap = max(0, globalFrame.minY - windowBounds.minY)
        let leadingGap = max(0, globalFrame.minX - windowBounds.minX)
        let trailingGap = max(0, windowBounds.maxX - globalFrame.maxX)

        let effectiveTopInset = max(0, safeAreaInsets.top - topGap)
        let effectiveLeadingInset = max(0, safeAreaInsets.leading - leadingGap)
        let effectiveTrailingInset = max(0, safeAreaInsets.trailing - trailingGap)

        let minX = effectiveLeadingInset + options.horizontalPadding
        let maxX = proxy.size.width - effectiveTrailingInset - options.horizontalPadding
        let minY = effectiveTopInset + options.topInset
        let maxY = proxy.size.height - options.horizontalPadding

        return CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX),
            height: max(1, maxY - minY)
        )
    }

    private func resolvedCrossAxisLength(in layoutBounds: CGRect) -> CGFloat {
        let maxLength = options.expansionAxis == .vertical ? layoutBounds.width : layoutBounds.height
        let clampedMax = max(1, maxLength)

        switch options.crossAxisSize {
        case .fill:
            return clampedMax
        case let .fraction(fraction):
            return (clampedMax * fraction.clamped(to: 0.1...1.0)).clamped(to: 1...clampedMax)
        case let .fixed(value):
            return value.clamped(to: 1...clampedMax)
        }
    }

    private func paneFrame(
        in layoutBounds: CGRect,
        expansionLength: CGFloat,
        crossAxisLength: CGFloat
    ) -> CGRect {
        let maxExpansion = options.expansionAxis == .vertical ? layoutBounds.height : layoutBounds.width
        let clampedExpansion = min(max(1, expansionLength), maxExpansion)
        let clampedCross = min(
            max(1, crossAxisLength),
            options.expansionAxis == .vertical ? layoutBounds.width : layoutBounds.height
        )

        let horizontalSide = horizontalAnchorSide(for: options.anchor)
        let verticalSide = verticalAnchorSide(for: options.anchor)
        let anchorPoint = point(for: options.anchor, in: layoutBounds)

        let paneWidth: CGFloat = options.expansionAxis == .vertical ? clampedCross : clampedExpansion
        let paneHeight: CGFloat = options.expansionAxis == .vertical ? clampedExpansion : clampedCross

        let originX: CGFloat
        switch options.expansionAxis {
        case .vertical:
            originX = origin(for: horizontalSide, anchor: anchorPoint.x, size: paneWidth)
        case .horizontal:
            originX = expansionOrigin(for: horizontalSide, anchor: anchorPoint.x, size: paneWidth)
        }

        let originY: CGFloat
        switch options.expansionAxis {
        case .vertical:
            originY = expansionOrigin(for: verticalSide, anchor: anchorPoint.y, size: paneHeight)
        case .horizontal:
            originY = origin(for: verticalSide, anchor: anchorPoint.y, size: paneHeight)
        }

        let clampedX = originX.clamped(to: layoutBounds.minX...(layoutBounds.maxX - paneWidth))
        let clampedY = originY.clamped(to: layoutBounds.minY...(layoutBounds.maxY - paneHeight))

        return CGRect(x: clampedX, y: clampedY, width: paneWidth, height: paneHeight)
    }

    private func point(for alignment: Alignment, in rect: CGRect) -> CGPoint {
        let x: CGFloat
        switch alignment {
        case .topLeading, .leading, .bottomLeading:
            x = rect.minX
        case .topTrailing, .trailing, .bottomTrailing:
            x = rect.maxX
        default:
            x = rect.midX
        }

        let y: CGFloat
        switch alignment {
        case .topLeading, .top, .topTrailing:
            y = rect.minY
        case .bottomLeading, .bottom, .bottomTrailing:
            y = rect.maxY
        default:
            y = rect.midY
        }

        return CGPoint(x: x, y: y)
    }

    private enum HorizontalAnchorSide {
        case leading
        case center
        case trailing
    }

    private enum VerticalAnchorSide {
        case top
        case center
        case bottom
    }

    private func horizontalAnchorSide(for alignment: Alignment) -> HorizontalAnchorSide {
        switch alignment {
        case .topLeading, .leading, .bottomLeading:
            return .leading
        case .topTrailing, .trailing, .bottomTrailing:
            return .trailing
        default:
            return .center
        }
    }

    private func verticalAnchorSide(for alignment: Alignment) -> VerticalAnchorSide {
        switch alignment {
        case .topLeading, .top, .topTrailing:
            return .top
        case .bottomLeading, .bottom, .bottomTrailing:
            return .bottom
        default:
            return .center
        }
    }

    private func origin(for side: HorizontalAnchorSide, anchor: CGFloat, size: CGFloat) -> CGFloat {
        switch side {
        case .leading:
            return anchor
        case .center:
            return anchor - (size / 2)
        case .trailing:
            return anchor - size
        }
    }

    private func origin(for side: VerticalAnchorSide, anchor: CGFloat, size: CGFloat) -> CGFloat {
        switch side {
        case .top:
            return anchor
        case .center:
            return anchor - (size / 2)
        case .bottom:
            return anchor - size
        }
    }

    private func expansionOrigin(for side: HorizontalAnchorSide, anchor: CGFloat, size: CGFloat) -> CGFloat {
        // Expansion side is inferred from anchor: leading expands right, trailing expands left, center expands both.
        switch side {
        case .leading:
            return anchor
        case .center:
            return anchor - (size / 2)
        case .trailing:
            return anchor - size
        }
    }

    private func expansionOrigin(for side: VerticalAnchorSide, anchor: CGFloat, size: CGFloat) -> CGFloat {
        // Expansion side is inferred from anchor: top expands down, bottom expands up, center expands both.
        switch side {
        case .top:
            return anchor
        case .center:
            return anchor - (size / 2)
        case .bottom:
            return anchor - size
        }
    }

    private var dragIndicatorAlignments: [Alignment] {
        switch options.expansionAxis {
        case .vertical:
            switch verticalAnchorSide(for: options.anchor) {
            case .top: return [.bottom]
            case .center: return [.top, .bottom]
            case .bottom: return [.top]
            }
        case .horizontal:
            switch horizontalAnchorSide(for: options.anchor) {
            case .leading: return [.trailing]
            case .center: return [.leading, .trailing]
            case .trailing: return [.leading]
            }
        }
    }

    private var paneIndicatorContentInsets: EdgeInsets {
        guard options.showsDragIndicator else { return .init() }
        let inset = max(0, options.dragIndicatorContentInset)
        var top: CGFloat = 0
        var leading: CGFloat = 0
        var bottom: CGFloat = 0
        var trailing: CGFloat = 0

        for alignment in dragIndicatorAlignments {
            switch alignment {
            case .top:
                top = max(top, inset)
            case .leading:
                leading = max(leading, inset)
            case .bottom:
                bottom = max(bottom, inset)
            case .trailing:
                trailing = max(trailing, inset)
            default:
                break
            }
        }

        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }

    private var panePresentationTransition: AnyTransition {
        paneAnchorTransition.combined(with: paneBlurReplaceTransition)
    }

    private var paneAnchorTransition: AnyTransition {
        let distance = paneTransitionTravelDistance
        switch options.expansionAxis {
        case .vertical:
            switch verticalAnchorSide(for: options.anchor) {
            case .top:
                return .modifier(
                    active: PaneSlideTransitionModifier(xOffset: 0, yOffset: -distance),
                    identity: PaneSlideTransitionModifier(xOffset: 0, yOffset: 0)
                )
            case .bottom:
                return .modifier(
                    active: PaneSlideTransitionModifier(xOffset: 0, yOffset: distance),
                    identity: PaneSlideTransitionModifier(xOffset: 0, yOffset: 0)
                )
            case .center:
                return .scale(scale: 0.94, anchor: .center)
            }
        case .horizontal:
            switch horizontalAnchorSide(for: options.anchor) {
            case .leading:
                return .modifier(
                    active: PaneSlideTransitionModifier(xOffset: -distance, yOffset: 0),
                    identity: PaneSlideTransitionModifier(xOffset: 0, yOffset: 0)
                )
            case .trailing:
                return .modifier(
                    active: PaneSlideTransitionModifier(xOffset: distance, yOffset: 0),
                    identity: PaneSlideTransitionModifier(xOffset: 0, yOffset: 0)
                )
            case .center:
                return .scale(scale: 0.94, anchor: .center)
            }
        }
    }

    private var paneTransitionTravelDistance: CGFloat {
        #if canImport(UIKit)
        if let bounds = currentWindowBounds() {
            return max(bounds.width, bounds.height) + 240
        }
        #endif
        return 1400
    }

    private var paneBlurReplaceTransition: AnyTransition {
        .modifier(
            active: PaneBlurReplaceFallbackModifier(blurRadius: 10, opacity: 0.02, scale: 0.985),
            identity: PaneBlurReplaceFallbackModifier(blurRadius: 0, opacity: 1, scale: 1)
        )
    }

    @ViewBuilder
    private var dragIndicatorView: some View {
        switch options.expansionAxis {
        case .vertical:
            Capsule()
                .fill(.secondary.opacity(0.45))
                .frame(width: 36, height: 5)
                .padding(.vertical, 10)
        case .horizontal:
            Capsule()
                .fill(.secondary.opacity(0.45))
                .frame(width: 5, height: 36)
                .padding(.horizontal, 10)
        }
    }

    private func primaryAxisTranslation(from size: CGSize) -> CGFloat {
        options.expansionAxis == .vertical ? size.height : size.width
    }

    private func normalizedPaneTranslation(axisTranslation: CGFloat, expansionSign: CGFloat) -> CGFloat {
        // Negative values expand the pane along its configured axis and anchor-derived direction.
        -(axisTranslation * expansionSign)
    }

    private func inferredExpansionSign(startLocation: CGPoint, paneFrame: CGRect) -> CGFloat {
        switch options.expansionAxis {
        case .vertical:
            switch verticalAnchorSide(for: options.anchor) {
            case .top:
                return 1
            case .bottom:
                return -1
            case .center:
                return startLocation.y <= paneFrame.midY ? -1 : 1
            }
        case .horizontal:
            switch horizontalAnchorSide(for: options.anchor) {
            case .leading:
                return 1
            case .trailing:
                return -1
            case .center:
                return startLocation.x <= paneFrame.midX ? -1 : 1
            }
        }
    }

    private func paneHeight(
        forSelectedHeight selectedHeight: CGFloat,
        dragTranslation: CGFloat,
        minHeight: CGFloat,
        maxHeight: CGFloat
    ) -> CGFloat {
        let rawHeight = selectedHeight - dragTranslation

        if rawHeight < minHeight {
            let overshoot = minHeight - rawHeight
            return minHeight - bottomRubberBandOffset(for: overshoot)
        }

        return rawHeight.clamped(to: minHeight...maxHeight)
    }

    private func bottomRubberBandOffset(for overshoot: CGFloat) -> CGFloat {
        let scaled = (overshoot * bottomOvershootResistance) / maxBottomOvershoot
        let normalized = 1 - (1 / (scaled + 1))
        return normalized * maxBottomOvershoot
    }

    private func estimatedReleaseVelocity(translation: CGFloat, predictedTranslation: CGFloat) -> CGFloat {
        (predictedTranslation - translation) / releaseVelocityProjectionSeconds
    }

    private func progress(height: CGFloat, minHeight: CGFloat, maxHeight: CGFloat) -> CGFloat {
        guard maxHeight > minHeight else { return 1 }
        return ((height - minHeight) / (maxHeight - minHeight)).clamped(to: 0...1)
    }

    private func collapsedAnchorInteractiveProgress(
        interactiveHeight: CGFloat,
        minHeight: CGFloat,
        maxHeight: CGFloat,
        isDraggingPane: Bool,
        dragTranslation: CGFloat
    ) -> CGFloat {
        guard options.keepsCollapsedScrollAnchorPinned else { return 0 }
        guard options.collapsedScrollAnchorTag != nil else { return 0 }
        guard isDraggingPane else { return 0 }
        guard dragTranslation > 0 else { return 0 }
        return (1 - progress(height: interactiveHeight, minHeight: minHeight, maxHeight: maxHeight))
            .clamped(to: 0...1)
    }

    private func resolvedDetents(maxHeight: CGFloat, safeAreaBottom: CGFloat) -> [ResolvedPaneDetent] {
        let detents = options.detents.isEmpty ? [PaneDetent.medium, .large] : options.detents

        let resolved = detents
            .map { detent in
                ResolvedPaneDetent(
                    detent: detent,
                    height: detent.resolvedHeight(
                        maxHeight: maxHeight,
                        safeAreaBottom: safeAreaBottom
                    )
                )
            }
            .sorted { $0.height < $1.height }

        var uniqueResolved: [ResolvedPaneDetent] = []
        for entry in resolved {
            if let last = uniqueResolved.last, abs(last.height - entry.height) < 1 {
                continue
            }
            uniqueResolved.append(entry)
        }

        return uniqueResolved.isEmpty
        ? [
            ResolvedPaneDetent(detent: .medium, height: maxHeight * 0.5),
            ResolvedPaneDetent(detent: .large, height: maxHeight)
        ]
        : uniqueResolved
    }

    private func height(
        for detent: PaneDetent,
        in detents: [ResolvedPaneDetent],
        maxHeight: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGFloat {
        if let exact = detents.first(where: { $0.detent == detent }) {
            return exact.height
        }

        let expected = detent.resolvedHeight(maxHeight: maxHeight, safeAreaBottom: safeAreaBottom)
        return nearestDetent(to: expected, in: detents).height
    }

    private func nearestDetent(to height: CGFloat, in detents: [ResolvedPaneDetent]) -> ResolvedPaneDetent {
        detents.min { abs($0.height - height) < abs($1.height - height) }
        ?? ResolvedPaneDetent(detent: .large, height: height)
    }

    private func nearestDetentIndex(to height: CGFloat, in detents: [ResolvedPaneDetent]) -> Int {
        var bestIndex = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for (index, detent) in detents.enumerated() {
            let distance = abs(detent.height - height)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return bestIndex
    }

    private func snapTarget(
        projectedHeight: CGFloat,
        startingHeight: CGFloat,
        releaseVelocity: CGFloat,
        in detents: [ResolvedPaneDetent]
    ) -> ResolvedPaneDetent {
        guard !detents.isEmpty else {
            return ResolvedPaneDetent(detent: .large, height: projectedHeight)
        }

        let startIndex = nearestDetentIndex(to: startingHeight, in: detents)
        let positionTarget = positionalSnapTarget(
            projectedHeight: projectedHeight,
            startingHeight: startingHeight,
            in: detents
        )
        let positionIndex = nearestDetentIndex(to: positionTarget.height, in: detents)

        guard abs(releaseVelocity) >= flingVelocityThreshold else {
            return positionTarget
        }

        let direction = releaseVelocity < 0 ? 1 : -1
        let step = abs(releaseVelocity) >= strongFlingVelocityThreshold ? 2 : 1
        var velocityIndex = (startIndex + (direction * step)).clamped(to: 0...(detents.count - 1))

        if direction > 0 {
            velocityIndex = Swift.max(velocityIndex, positionIndex)
        } else {
            velocityIndex = Swift.min(velocityIndex, positionIndex)
        }

        return detents[velocityIndex]
    }

    private func positionalSnapTarget(
        projectedHeight: CGFloat,
        startingHeight: CGFloat,
        in detents: [ResolvedPaneDetent]
    ) -> ResolvedPaneDetent {
        let startIndex = nearestDetentIndex(to: startingHeight, in: detents)
        let startDetent = detents[startIndex]

        if abs(projectedHeight - startDetent.height) <= snapHoldThreshold {
            return startDetent
        }

        if projectedHeight > startDetent.height {
            var index = startIndex
            while index + 1 < detents.count {
                let boundary = ((detents[index].height + detents[index + 1].height) / 2) + snapBoundaryHysteresis
                if projectedHeight >= boundary {
                    index += 1
                } else {
                    break
                }
            }
            return detents[index]
        }

        var index = startIndex
        while index > 0 {
            let boundary = ((detents[index - 1].height + detents[index].height) / 2) - snapBoundaryHysteresis
            if projectedHeight <= boundary {
                index -= 1
            } else {
                break
            }
        }
        return detents[index]
    }

    private func alignSelection(to detents: [ResolvedPaneDetent], maxHeight: CGFloat, safeAreaBottom: CGFloat) {
        let expected = selectedDetent.resolvedHeight(maxHeight: maxHeight, safeAreaBottom: safeAreaBottom)
        let nearest = nearestDetent(to: expected, in: detents)

        if nearest.detent != selectedDetent {
            selectedDetent = nearest.detent
        }

        updateScrollInteractivity(
            forTargetHeight: nearest.height,
            fromCurrentHeight: nearest.height,
            maxHeight: maxHeight
        )
    }

    private func undimmedHeight(
        detents: [ResolvedPaneDetent],
        maxHeight: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGFloat? {
        guard let threshold = options.largestUndimmedDetent else { return nil }
        return height(
            for: threshold,
            in: detents,
            maxHeight: maxHeight,
            safeAreaBottom: safeAreaBottom
        )
    }

    private func shouldDimBackground(
        interactiveHeight: CGFloat,
        detents: [ResolvedPaneDetent],
        maxHeight: CGFloat,
        safeAreaBottom: CGFloat
    ) -> Bool {
        guard let threshold = undimmedHeight(
            detents: detents,
            maxHeight: maxHeight,
            safeAreaBottom: safeAreaBottom
        ) else {
            return true
        }

        return interactiveHeight > threshold + 1
    }

    private func shouldBlockBackground(
        interactiveHeight: CGFloat,
        detents: [ResolvedPaneDetent],
        maxHeight: CGFloat,
        safeAreaBottom: CGFloat
    ) -> Bool {
        guard !options.allowsBackgroundInteraction else {
            guard let threshold = undimmedHeight(
                detents: detents,
                maxHeight: maxHeight,
                safeAreaBottom: safeAreaBottom
            ) else {
                return false
            }
            return interactiveHeight > threshold + 1
        }

        return true
    }

    private func isAtMax(currentHeight: CGFloat, maxHeight: CGFloat) -> Bool {
        abs(currentHeight - maxHeight) < 1
    }

    private func beginDragDismiss(translation: CGFloat, expansionSign: CGFloat) {
        guard !isDragDismissAnimating else { return }

        isDraggingPane = false
        dragMode = nil
        paneCaptureStartTranslation = 0
        activeExpansionSign = 1
        setScrollDisabled(true)
        isDragDismissAnimating = true

        let collapseAxisDirection = -expansionSign
        let travel = paneTransitionTravelDistance + 120
        withAnimation(options.animation.speed(dragDismissAnimationSpeed)) {
            dragTranslation = translation
            dismissSlideOffset = collapseAxisDirection * travel
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dragDismissCompletionDelay) {
            guard isDragDismissAnimating else { return }

            var transaction = Transaction(animation: .none)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isPresented = false
                isDragDismissAnimating = false
                dismissSlideOffset = 0
                dragTranslation = 0
            }

            onDismiss?()
        }
    }

    private func dismiss() {
        if isDragDismissAnimating {
            isDragDismissAnimating = false
            dismissSlideOffset = 0
        }
        var transaction = Transaction(animation: options.animation)
        transaction.disablesAnimations = false
        withTransaction(transaction) {
            isPresented = false
        }
        onDismiss?()
    }

    private func setScrollDisabled(_ disabled: Bool) {
        if scrollState.scrollDisabled != disabled {
            scrollState.scrollDisabled = disabled
        }
    }

    private func resolvedSafeAreaInsets(from proxy: GeometryProxy) -> EdgeInsets {
        let localInsets = proxy.safeAreaInsets
        if localInsets.top > 0 || localInsets.leading > 0 || localInsets.trailing > 0 || localInsets.bottom > 0 {
            return localInsets
        }

        #if canImport(UIKit)
        if let windowInsets = currentWindowSafeAreaInsets() {
            return EdgeInsets(
                top: windowInsets.top,
                leading: windowInsets.left,
                bottom: windowInsets.bottom,
                trailing: windowInsets.right
            )
        }
        #endif

        return localInsets
    }

    #if canImport(UIKit)
    private func currentWindowBounds() -> CGRect? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        for scene in scenes where scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive {
            if let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first {
                return window.bounds
            }
        }

        return scenes.first?.windows.first?.bounds
    }

    private func currentWindowSafeAreaInsets() -> UIEdgeInsets? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        for scene in scenes where scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive {
            if let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first {
                return window.safeAreaInsets
            }
        }

        return scenes.first?.windows.first?.safeAreaInsets
    }
    #endif

    private func updateScrollInteractivity(
        forTargetHeight targetHeight: CGFloat,
        fromCurrentHeight currentHeight: CGFloat,
        maxHeight: CGFloat
    ) {
        let shouldEnableScroll = isAtMax(currentHeight: targetHeight, maxHeight: maxHeight)
        let expandingIntoMax = shouldEnableScroll && !isAtMax(currentHeight: currentHeight, maxHeight: maxHeight)

        scrollUnlockToken += 1
        let token = scrollUnlockToken

        if expandingIntoMax {
            setScrollDisabled(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + enableScrollDelayAfterSnap) {
                guard token == scrollUnlockToken else { return }
                guard dragMode == nil, !isDraggingPane else { return }
                setScrollDisabled(false)
            }
            return
        }

        setScrollDisabled(!shouldEnableScroll)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

public enum PaneAnchorPreset: String, CaseIterable, Identifiable {
    case topLeading
    case top
    case topTrailing
    case leading
    case center
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .topLeading: "Top Leading"
        case .top: "Top"
        case .topTrailing: "Top Trailing"
        case .leading: "Leading"
        case .center: "Center"
        case .trailing: "Trailing"
        case .bottomLeading: "Bottom Leading"
        case .bottom: "Bottom"
        case .bottomTrailing: "Bottom Trailing"
        }
    }

    public var alignment: Alignment {
        switch self {
        case .topLeading: .topLeading
        case .top: .top
        case .topTrailing: .topTrailing
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        case .bottomLeading: .bottomLeading
        case .bottom: .bottom
        case .bottomTrailing: .bottomTrailing
        }
    }
}

public extension View {
    func glassEffectIfAvailable(cornerRadius: CGFloat) -> some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                self
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
    }
}
