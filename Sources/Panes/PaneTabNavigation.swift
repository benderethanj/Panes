import SwiftUI

func isQuickUpwardSwipe(
    elapsed: TimeInterval,
    translation: CGSize,
    predictedEndTranslation: CGSize,
    activationDistance: CGFloat,
    minimumDragDistance: CGFloat,
    maximumDuration: TimeInterval,
    predictedDistance: CGFloat
) -> Bool {
    let upwardTravel = max(0, -translation.height)
    let horizontalTravel = abs(translation.width)
    let requiredDragDistance = max(2, activationDistance, minimumDragDistance)
    let projectedUpwardTravel = max(
        upwardTravel,
        max(0, -predictedEndTranslation.height)
    )

    return elapsed <= max(0.1, maximumDuration) &&
        upwardTravel >= requiredDragDistance &&
        upwardTravel > horizontalTravel &&
        projectedUpwardTravel >= max(requiredDragDistance, predictedDistance)
}

private struct PaneTabMenuButtonFrameKey: PreferenceKey {
    static let defaultValue = CGRect.null

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 0.5, next.height > 0.5 {
            value = next
        }
    }
}

public enum PaneTabMenuState: Hashable {
    case closed
    case compact
    case expanded
}

public enum PaneTabBarPlacement: Hashable {
    case automatic
    case bottom
    case leading
    case trailing
}

public enum PaneTabLabelLayer: Hashable {
    case background
    case foreground
}

public struct PaneTabLabelContext<Tab: Hashable> {
    public let tab: Tab
    public let layer: PaneTabLabelLayer
    public let isHighlighted: Bool
    public let isDragging: Bool

    public init(
        tab: Tab,
        layer: PaneTabLabelLayer,
        isHighlighted: Bool,
        isDragging: Bool
    ) {
        self.tab = tab
        self.layer = layer
        self.isHighlighted = isHighlighted
        self.isDragging = isDragging
    }
}

public struct PaneTabIndicatorContext<Tab: Hashable> {
    public let highlightedTab: Tab?
    public let size: CGSize
    public let isDragging: Bool
    public let placement: PaneTabBarPlacement

    public init(
        highlightedTab: Tab?,
        size: CGSize,
        isDragging: Bool,
        placement: PaneTabBarPlacement
    ) {
        self.highlightedTab = highlightedTab
        self.size = size
        self.isDragging = isDragging
        self.placement = placement
    }
}

public struct PaneTabNavigationConfiguration {
    public var placement: PaneTabBarPlacement
    public var margin: CGFloat
    public var barPadding: CGFloat
    public var tabBarContentPadding: CGFloat
    public var barThickness: CGFloat?
    public var scrubMargin: CGFloat?
    public var scrubBarPadding: CGFloat?
    public var menuButtonSpacing: CGFloat
    public var tint: Color
    public var glassStyle: PaneGlassStyle
    public var glassIsInteractive: Bool
    public var tabBarCornerRadius: CGFloat?
    public var selectionAnimation: Animation
    public var chromeAnimation: Animation
    public var hidesTabBarWhenSingleTab: Bool
    public var hidesMenuButtonWhileDragging: Bool
    public var menuButtonAccessibilityLabel: String
    public var hapticsEnabled: Bool
    public var quickActionLongPressDuration: TimeInterval
    public var quickActionActivationDistance: CGFloat
    public var quickSwipeMaximumDuration: TimeInterval
    public var quickSwipePredictedDistance: CGFloat
    public var quickActionSpacing: CGFloat

    public init(
        placement: PaneTabBarPlacement = .automatic,
        margin: CGFloat = 24,
        barPadding: CGFloat = 6,
        tabBarContentPadding: CGFloat = 8,
        barThickness: CGFloat? = nil,
        scrubMargin: CGFloat? = 16,
        scrubBarPadding: CGFloat? = 4,
        menuButtonSpacing: CGFloat = 8,
        tint: Color = .clear,
        glassStyle: PaneGlassStyle = .regular,
        glassIsInteractive: Bool = true,
        tabBarCornerRadius: CGFloat? = nil,
        selectionAnimation: Animation = .interactiveSpring(
            response: 0.32,
            dampingFraction: 0.82,
            blendDuration: 0.1
        ),
        chromeAnimation: Animation = .interactiveSpring(
            response: 0.28,
            dampingFraction: 0.88,
            blendDuration: 0.1
        ),
        hidesTabBarWhenSingleTab: Bool = false,
        hidesMenuButtonWhileDragging: Bool = true,
        menuButtonAccessibilityLabel: String = "Open menu",
        hapticsEnabled: Bool = true,
        quickActionLongPressDuration: TimeInterval = 0.32,
        quickActionActivationDistance: CGFloat = 10,
        quickSwipeMaximumDuration: TimeInterval = 0.26,
        quickSwipePredictedDistance: CGFloat = 44,
        quickActionSpacing: CGFloat = 6
    ) {
        self.placement = placement
        self.margin = margin
        self.barPadding = barPadding
        self.tabBarContentPadding = tabBarContentPadding
        self.barThickness = barThickness
        self.scrubMargin = scrubMargin
        self.scrubBarPadding = scrubBarPadding
        self.menuButtonSpacing = menuButtonSpacing
        self.tint = tint
        self.glassStyle = glassStyle
        self.glassIsInteractive = glassIsInteractive
        self.tabBarCornerRadius = tabBarCornerRadius
        self.selectionAnimation = selectionAnimation
        self.chromeAnimation = chromeAnimation
        self.hidesTabBarWhenSingleTab = hidesTabBarWhenSingleTab
        self.hidesMenuButtonWhileDragging = hidesMenuButtonWhileDragging
        self.menuButtonAccessibilityLabel = menuButtonAccessibilityLabel
        self.hapticsEnabled = hapticsEnabled
        self.quickActionLongPressDuration = quickActionLongPressDuration
        self.quickActionActivationDistance = quickActionActivationDistance
        self.quickSwipeMaximumDuration = quickSwipeMaximumDuration
        self.quickSwipePredictedDistance = quickSwipePredictedDistance
        self.quickActionSpacing = quickActionSpacing
    }
}

public struct PaneTabMenuButtonContext {
    public let showsQuickActions: Bool
    public let quickActionExpansionProgress: CGFloat
}

public struct PaneTabQuickActionContext {
    public let isHovered: Bool
    public let isExpanded: Bool
}

@MainActor
public struct PaneTabQuickAction {
    public let id: AnyHashable
    public let accessibilityLabel: String
    public let activatesOnQuickSwipe: Bool
    fileprivate let action: () -> Void
    fileprivate let label: (PaneTabQuickActionContext) -> AnyView

    public init<ID: Hashable, Label: View>(
        id: ID,
        accessibilityLabel: String,
        activatesOnQuickSwipe: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (PaneTabQuickActionContext) -> Label
    ) {
        self.id = AnyHashable(id)
        self.accessibilityLabel = accessibilityLabel
        self.activatesOnQuickSwipe = activatesOnQuickSwipe
        self.action = action
        self.label = { AnyView(label($0)) }
    }
}

public struct PaneTabMenuConfiguration {
    public var compactMargin: CGFloat
    public var cornerRadius: CGFloat
    public var dimmingOpacity: CGFloat
    public var minimumDimmingOpacity: CGFloat
    public var surfaceStyle: PaneSurfaceStyle?
    public var surfaceSolidColor: Color?
    public var surfaceTintOpacityTransition: PaneSurfaceTintOpacityTransition?
    public var animation: Animation
    public var showsDragIndicator: Bool
    public var dragIndicatorContentInset: CGFloat
    public var dragIndicatorTouchExtension: CGFloat
    public var dragIndicatorFadeLength: CGFloat
    public var dismissThresholdMultiplier: CGFloat
    public var handleDismissDistance: CGFloat?
    public var handleDismissPredictedDistance: CGFloat?
    public var allowsSwipeToDismissFromAnywhere: Bool
    public var minimumDetentDragBehavior: PaneMinimumDetentDragBehavior
    public var allowsScrollCollapseFromAnyPosition: Bool
    public var scrollCollapseActivationDistance: CGFloat
    public var preventsContentActivationDuringDrag: Bool
    public var allowsContentInteractionWhenCompact: Bool
    public var systemGestureDeferralEdges: Edge.Set
    public var hapticsEnabled: Bool

    public init(
        compactMargin: CGFloat = 24,
        cornerRadius: CGFloat = 30,
        dimmingOpacity: CGFloat = 0.30,
        minimumDimmingOpacity: CGFloat = 0,
        surfaceStyle: PaneSurfaceStyle? = nil,
        surfaceSolidColor: Color? = nil,
        surfaceTintOpacityTransition: PaneSurfaceTintOpacityTransition? = .init(),
        animation: Animation = .interactiveSpring(
            response: 0.28,
            dampingFraction: 0.88,
            blendDuration: 0.2
        ),
        showsDragIndicator: Bool = true,
        dragIndicatorContentInset: CGFloat = 20,
        dragIndicatorTouchExtension: CGFloat = 18,
        dragIndicatorFadeLength: CGFloat = 24,
        dismissThresholdMultiplier: CGFloat = 0.7,
        handleDismissDistance: CGFloat? = 72,
        handleDismissPredictedDistance: CGFloat? = 128,
        allowsSwipeToDismissFromAnywhere: Bool = true,
        minimumDetentDragBehavior: PaneMinimumDetentDragBehavior = .continuous,
        allowsScrollCollapseFromAnyPosition: Bool = false,
        scrollCollapseActivationDistance: CGFloat = 8,
        preventsContentActivationDuringDrag: Bool = true,
        allowsContentInteractionWhenCompact: Bool = true,
        systemGestureDeferralEdges: Edge.Set = [.bottom],
        hapticsEnabled: Bool = true
    ) {
        self.compactMargin = compactMargin
        self.cornerRadius = cornerRadius
        self.dimmingOpacity = dimmingOpacity
        self.minimumDimmingOpacity = minimumDimmingOpacity
        self.surfaceStyle = surfaceStyle
        self.surfaceSolidColor = surfaceSolidColor
        self.surfaceTintOpacityTransition = surfaceTintOpacityTransition
        self.animation = animation
        self.showsDragIndicator = showsDragIndicator
        self.dragIndicatorContentInset = dragIndicatorContentInset
        self.dragIndicatorTouchExtension = dragIndicatorTouchExtension
        self.dragIndicatorFadeLength = dragIndicatorFadeLength
        self.dismissThresholdMultiplier = dismissThresholdMultiplier
        self.handleDismissDistance = handleDismissDistance
        self.handleDismissPredictedDistance = handleDismissPredictedDistance
        self.allowsSwipeToDismissFromAnywhere = allowsSwipeToDismissFromAnywhere
        self.minimumDetentDragBehavior = minimumDetentDragBehavior
        self.allowsScrollCollapseFromAnyPosition = allowsScrollCollapseFromAnyPosition
        self.scrollCollapseActivationDistance = scrollCollapseActivationDistance
        self.preventsContentActivationDuringDrag = preventsContentActivationDuringDrag
        self.allowsContentInteractionWhenCompact = allowsContentInteractionWhenCompact
        self.systemGestureDeferralEdges = systemGestureDeferralEdges
        self.hapticsEnabled = hapticsEnabled
    }
}

@MainActor
public struct PaneTabMenuContext {
    public let paneContext: PaneContext
    public let state: Binding<PaneTabMenuState>
    public let scrollAnchorID: AnyHashable
    private let reduceMotion: Bool

    init(
        paneContext: PaneContext,
        state: Binding<PaneTabMenuState>,
        scrollAnchorID: AnyHashable,
        reduceMotion: Bool
    ) {
        self.paneContext = paneContext
        self.state = state
        self.scrollAnchorID = scrollAnchorID
        self.reduceMotion = reduceMotion
    }

    public var expansionProgress: CGFloat { paneContext.expansionProgress }
    public var isExpanded: Bool { state.wrappedValue == .expanded }

    public func expand() {
        guard state.wrappedValue != .expanded else { return }
        var transaction = Transaction(animation: reduceMotion ? nil : paneContext.options.animation)
        transaction.disablesAnimations = reduceMotion
        withTransaction(transaction) {
            state.wrappedValue = .expanded
        }
    }

    public func dismiss() {
        paneContext.dismiss()
    }
}

@MainActor
public struct PaneTabMenu<Header: View, ScrollContent: View, Footer: View>: View {
    private let context: PaneTabMenuContext
    private let header: () -> Header
    private let scrollContent: () -> ScrollContent
    private let footer: () -> Footer

    public init(
        context: PaneTabMenuContext,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> ScrollContent,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.context = context
        self.header = header
        self.scrollContent = content
        self.footer = footer
    }

    public var body: some View {
        VStack(spacing: 0) {
            header()
                .padding(
                    .top,
                    context.paneContext.options.showsDragIndicator
                        ? context.paneContext.options.dragIndicatorContentInset
                        : 0
                )

            PaneScrollView(
                state: context.paneContext.scrollState,
                collapsedScrollAnchorTag: context.scrollAnchorID,
                shouldPinCollapsedScrollAnchor: !context.paneContext.isSelectedDetentFullyExpanded,
                tracksCollapsedScrollAnchor: false,
                showsCollapsedScrollAnchorIndicator: false,
                scrollSnapBehavior: .none,
                collapsedScrollAnchor: .top
            ) {
                scrollContent()
                    .paneAnchorTag(context.scrollAnchorID, topOffset: 1)
            }

            footer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
public struct PaneTabNavigation<
    Tab: Hashable,
    TabContent: View,
    TabLabel: View,
    Indicator: View,
    MenuButton: View,
    MenuContent: View
>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    @Binding private var menuState: PaneTabMenuState
    private let showsChrome: Bool
    private let configuration: PaneTabNavigationConfiguration
    private let menuConfiguration: PaneTabMenuConfiguration
    private let tabAccessibilityLabel: (Tab) -> String
    private let tabContent: (Tab) -> TabContent
    private let tabLabel: (PaneTabLabelContext<Tab>) -> TabLabel
    private let indicator: (PaneTabIndicatorContext<Tab>) -> Indicator
    private let menuButton: (PaneTabMenuButtonContext) -> MenuButton
    private let menuButtonAdornment: (PaneTabMenuButtonContext) -> AnyView
    private let quickActions: [PaneTabQuickAction]
    private let menuContent: (PaneTabMenuContext) -> MenuContent

    @Namespace private var menuPresentationNamespace
    @State private var scrubAxisPosition: CGFloat?
    @State private var scrubStartAxisPosition: CGFloat?
    @State private var isScrubbing = false
    @State private var menuButtonFrame: CGRect = .null
    @State private var isMenuButtonPressing = false
    @State private var quickActionInteractionActive = false
    @State private var quickActionShowsAll = false
    @State private var hoveredQuickActionID: AnyHashable?
    @State private var quickActionVisibleCount = 0
    @State private var menuButtonGestureToken = 0
    @State private var menuButtonMaximumTravel: CGFloat = 0
    @State private var menuButtonPressStartedAt: Date?
    @State private var quickActionsActivatedByLongPress = false
    #if canImport(UIKit)
    @State private var windowMetrics: PaneWindowMetrics?
    #endif
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    private let compactDetent = PaneDetent.crossAxisLength(fraction: 1, offset: 0)
    private let menuSourceID = AnyHashable("panes.tab-navigation.menu-source")
    private let menuGlassID = "panes.tab-navigation.menu-surface"
    private let menuScrollAnchorID = AnyHashable("panes.tab-navigation.menu-scroll-anchor")

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        menuState: Binding<PaneTabMenuState>,
        showsChrome: Bool = true,
        configuration: PaneTabNavigationConfiguration = .init(),
        menuConfiguration: PaneTabMenuConfiguration = .init(),
        tabAccessibilityLabel: @escaping (Tab) -> String = { String(describing: $0) },
        @ViewBuilder content: @escaping (Tab) -> TabContent,
        @ViewBuilder tabLabel: @escaping (PaneTabLabelContext<Tab>) -> TabLabel,
        @ViewBuilder indicator: @escaping (PaneTabIndicatorContext<Tab>) -> Indicator,
        quickActions: [PaneTabQuickAction] = [],
        @ViewBuilder menuButton: @escaping (PaneTabMenuButtonContext) -> MenuButton,
        menuButtonAdornment: @escaping (PaneTabMenuButtonContext) -> AnyView = { _ in
            AnyView(EmptyView())
        },
        @ViewBuilder menu: @escaping (PaneTabMenuContext) -> MenuContent
    ) {
        _selection = selection
        self.tabs = tabs
        _menuState = menuState
        self.showsChrome = showsChrome
        self.configuration = configuration
        self.menuConfiguration = menuConfiguration
        self.tabAccessibilityLabel = tabAccessibilityLabel
        self.tabContent = content
        self.tabLabel = tabLabel
        self.indicator = indicator
        self.menuButton = menuButton
        self.menuButtonAdornment = menuButtonAdornment
        self.quickActions = quickActions
        self.menuContent = menu
    }

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        menuState: Binding<PaneTabMenuState>,
        showsChrome: Bool = true,
        configuration: PaneTabNavigationConfiguration = .init(),
        menuConfiguration: PaneTabMenuConfiguration = .init(),
        tabAccessibilityLabel: @escaping (Tab) -> String = { String(describing: $0) },
        @ViewBuilder content: @escaping (Tab) -> TabContent,
        @ViewBuilder tabLabel: @escaping (PaneTabLabelContext<Tab>) -> TabLabel,
        @ViewBuilder indicator: @escaping (PaneTabIndicatorContext<Tab>) -> Indicator,
        @ViewBuilder menuButton: @escaping () -> MenuButton,
        @ViewBuilder menu: @escaping (PaneTabMenuContext) -> MenuContent
    ) {
        self.init(
            selection: selection,
            tabs: tabs,
            menuState: menuState,
            showsChrome: showsChrome,
            configuration: configuration,
            menuConfiguration: menuConfiguration,
            tabAccessibilityLabel: tabAccessibilityLabel,
            content: content,
            tabLabel: tabLabel,
            indicator: indicator,
            quickActions: [],
            menuButton: { _ in menuButton() },
            menuButtonAdornment: { _ in AnyView(EmptyView()) },
            menu: menu
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let placement = resolvedPlacement(for: proxy.size)
            let sourceAnchor = menuSourceAnchor(for: placement)
            let sourceDimension = resolvedBarThickness(
                in: proxy.size,
                margin: max(0, configuration.margin)
            )
            let hasUsableSourceFrame = menuButtonFrame.width > 0.5 && menuButtonFrame.height > 0.5
            let keepsSourceSurface = showsChrome || menuState != .closed
            let sourceFrame = menuSourceFrame(
                buttonFrame: menuButtonFrame,
                dimension: sourceDimension
            )
            let presentationSource = PanePresentationSource(
                id: menuSourceID,
                glassID: menuGlassID,
                namespace: menuPresentationNamespace,
                properties: .frame,
                anchor: sourceAnchor,
                frame: hasUsableSourceFrame && keepsSourceSurface && (menuState != .closed || !isScrubbing)
                    ? sourceFrame
                    : nil,
                cornerRadius: sourceDimension / 2,
                content: AnyView(menuSourceContent(dimension: sourceDimension))
            )

            navigationLayers(
                in: proxy.size,
                placement: placement,
                presentationSource: presentationSource
            )
            .onPreferenceChange(PaneTabMenuButtonFrameKey.self) { frame in
                guard frame.width > 0.5, frame.height > 0.5, menuButtonFrame != frame else { return }
                menuButtonFrame = frame
            }
        }
        .animation(reduceMotion ? nil : configuration.selectionAnimation, value: selection)
        .onAppear {
            resetChromeInteraction()
            reconcileSelection()
        }
        .onChange(of: tabs) { _, _ in
            resetChromeInteraction()
            reconcileSelection()
        }
        .onChange(of: selection) { _, _ in
            resetChromeInteraction()
            reconcileSelection()
        }
        .onChange(of: menuState) { _, _ in
            if quickActionInteractionActive || isMenuButtonPressing {
                resetQuickActionInteraction(animated: false)
            }
            resetChromeInteraction()
        }
        .onChange(of: showsChrome) { _, isVisible in
            if quickActionInteractionActive || isMenuButtonPressing {
                resetQuickActionInteraction(animated: false)
            }
            resetChromeInteraction()
            if !isVisible, menuState != .closed {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    menuState = .closed
                }
            }
        }
        .accessibilityAction(.escape) {
            guard menuState != .closed else { return }
            performNavigationHaptic(.light, enabled: menuConfiguration.hapticsEnabled)
            performAnimated(menuConfiguration.animation) {
                menuState = .closed
            }
        }
    }

    private func navigationLayers(
        in size: CGSize,
        placement: PaneTabBarPlacement,
        presentationSource: PanePresentationSource
    ) -> some View {
        ZStack {
            pages
                .accessibilityHidden(menuState != .closed)

            paneAndChromeLayer(
                in: size,
                placement: placement,
                presentationSource: presentationSource
            )

            #if canImport(UIKit)
            PaneWindowMetricsReader { metrics in
                if windowMetrics != metrics {
                    windowMetrics = metrics
                }
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            #endif
        }
        .animation(reduceMotion ? nil : configuration.chromeAnimation, value: showsChrome)
    }

    private func paneAndChromeLayer(
        in size: CGSize,
        placement: PaneTabBarPlacement,
        presentationSource: PanePresentationSource
    ) -> some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    paneSurfaceLayer(
                        placement: placement,
                        presentationSource: presentationSource
                    )
                }
            } else {
                paneSurfaceLayer(
                    placement: placement,
                    presentationSource: presentationSource
                )
            }
        }
            .overlay {
                if showsChrome {
                    chrome(
                        in: size,
                        placement: placement
                    )
                    .allowsHitTesting(menuState == .closed)
                    .accessibilityHidden(menuState != .closed)
                }
            }
    }

    private func paneSurfaceLayer(
        placement: PaneTabBarPlacement,
        presentationSource: PanePresentationSource
    ) -> some View {
        Color.clear
            .allowsHitTesting(false)
            .pane(
                isPresented: menuPresentedBinding,
                selectedDetent: menuDetentBinding,
                config: paneConfig(
                    placement: placement,
                    presentationSource: presentationSource
                )
            ) { paneContext in
                menuContent(
                    PaneTabMenuContext(
                        paneContext: paneContext,
                        state: $menuState,
                        scrollAnchorID: menuScrollAnchorID,
                        reduceMotion: reduceMotion
                    )
                )
            }
    }

    @ViewBuilder
    private var pages: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.self) { tab in
                tabContent(tab)
                    .tag(tab)
            }
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    private func chrome(
        in size: CGSize,
        placement: PaneTabBarPlacement
    ) -> some View {
        let idleMargin = max(0, configuration.margin)
        let margin = isScrubbing ? max(0, configuration.scrubMargin ?? idleMargin) : idleMargin
        let showsTabBar = !(configuration.hidesTabBarWhenSingleTab && tabs.count <= 1)
        let showsMenuButton = !showsTabBar || !(configuration.hidesMenuButtonWhileDragging && isScrubbing)
        let spacing = showsMenuButton ? max(0, configuration.menuButtonSpacing) : 0
        let thickness = resolvedBarThickness(in: size, margin: margin)
        let buttonDimension = showsMenuButton ? thickness : 0
        let availableMajorLength = max(
            0,
            (isHorizontal(placement) ? size.width : size.height) - (margin * 2)
        )
        let barMajorLength = max(0, availableMajorLength - buttonDimension)

        return Group {
            if isHorizontal(placement) {
                HStack(spacing: spacing) {
                    if showsTabBar {
                        ZStack {
                            if menuState == .closed {
                                tabBar(placement: placement)
                                    .transition(
                                        .move(edge: .bottom)
                                            .combined(with: .blurReplace)
                                    )
                            }
                        }
                        .frame(width: barMajorLength, height: thickness)
                    }

                    if showsMenuButton {
                        menuButtonSurface(dimension: thickness)
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    if showsTabBar {
                        ZStack {
                            if menuState == .closed {
                                tabBar(placement: placement)
                                    .transition(
                                        .move(edge: .bottom)
                                            .combined(with: .blurReplace)
                                    )
                            }
                        }
                        .frame(width: thickness, height: barMajorLength)
                    }

                    if showsMenuButton {
                        menuButtonSurface(dimension: thickness)
                    }
                }
            }
        }
        .padding(margin)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: chromeAlignment(for: placement, showsTabBar: showsTabBar)
        )
        .animation(reduceMotion ? nil : configuration.chromeAnimation, value: isScrubbing)
        .animation(reduceMotion ? nil : configuration.chromeAnimation, value: showsTabBar)
    }

    private func tabBar(placement: PaneTabBarPlacement) -> some View {
        GeometryReader { proxy in
            let horizontal = isHorizontal(placement)
            let idlePadding = max(0, configuration.barPadding)
            let padding = isScrubbing
                ? max(0, configuration.scrubBarPadding ?? idlePadding)
                : idlePadding
            let contentPadding = max(0, configuration.tabBarContentPadding)
                let majorLength = max(0, (horizontal ? proxy.size.width : proxy.size.height) - (padding * 2))
                let crossLength = max(0, (horizontal ? proxy.size.height : proxy.size.width) - (padding * 2))
                let cellLength = tabs.isEmpty ? 0 : majorLength / CGFloat(tabs.count)
                let highlightedIndex = highlightedTabIndex(
                    majorLength: majorLength,
                    padding: padding,
                    cellLength: cellLength
                )
                let indicatorSize = horizontal
                    ? CGSize(width: cellLength, height: crossLength)
                    : CGSize(width: crossLength, height: cellLength)
                let center = indicatorCenter(
                    highlightedIndex: highlightedIndex,
                    majorLength: majorLength,
                    padding: padding,
                    cellLength: cellLength,
                    crossLength: crossLength,
                    horizontal: horizontal
                )
                let highlightedTab = tabs.indices.contains(highlightedIndex) ? tabs[highlightedIndex] : nil

            ZStack(alignment: .topLeading) {
                isolatedGlassScope {
                    GlassCard(
                        padding: contentPadding,
                        cornerRadius: configuration.tabBarCornerRadius ?? 999,
                        glassType: configuration.glassStyle.rawValue,
                        tint: configuration.tint,
                        interactive: configuration.glassIsInteractive
                    ) {
                        tabStrip(
                            layer: .background,
                            highlightedIndex: highlightedIndex,
                            placement: placement
                        )
                        .padding(padding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                isolatedGlassScope {
                    indicator(
                        PaneTabIndicatorContext(
                            highlightedTab: highlightedTab,
                            size: indicatorSize,
                            isDragging: isScrubbing,
                            placement: placement
                        )
                    )
                    .frame(width: indicatorSize.width, height: indicatorSize.height)
                    .position(center)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }

                tabStrip(
                    layer: .foreground,
                    highlightedIndex: highlightedIndex,
                    placement: placement
                )
                .padding(padding)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .contentShape(Capsule())
            .gesture(scrubGesture(horizontal: horizontal, padding: padding, majorLength: majorLength))
        }
    }

    @ViewBuilder
    private func tabStrip(
        layer: PaneTabLabelLayer,
        highlightedIndex: Int,
        placement: PaneTabBarPlacement
    ) -> some View {
        let horizontal = isHorizontal(placement)

        if horizontal {
            HStack(spacing: 0) {
                tabItems(layer: layer, highlightedIndex: highlightedIndex)
            }
        } else {
            VStack(spacing: 0) {
                tabItems(layer: layer, highlightedIndex: highlightedIndex)
            }
        }
    }

    @ViewBuilder
    private func tabItems(layer: PaneTabLabelLayer, highlightedIndex: Int) -> some View {
        ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
            let highlighted = index == highlightedIndex

            if layer == .background {
                Button {
                    settleSelection(on: tab)
                } label: {
                    tabLabel(
                        PaneTabLabelContext(
                            tab: tab,
                            layer: layer,
                            isHighlighted: highlighted,
                            isDragging: isScrubbing
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabAccessibilityLabel(tab))
                .accessibilityAddTraits(tab == selection ? .isSelected : [])
            } else {
                tabLabel(
                    PaneTabLabelContext(
                        tab: tab,
                        layer: layer,
                        isHighlighted: highlighted,
                        isDragging: isScrubbing
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(highlighted ? 1 : 0)
            }
        }
    }

    private func menuSourceContent(dimension: CGFloat) -> some View {
        let visibleActions = resolvedVisibleQuickActions
        let context = PaneTabMenuButtonContext(
            showsQuickActions: quickActionInteractionActive,
            quickActionExpansionProgress: quickActions.isEmpty
                ? 0
                : CGFloat(visibleActions.count) / CGFloat(quickActions.count)
        )

        return VStack(spacing: 0) {
            if !visibleActions.isEmpty {
                VStack(spacing: resolvedQuickActionSpacing) {
                    ForEach(Array(visibleActions.reversed()), id: \.id) { action in
                        let hovered = hoveredQuickActionID == action.id
                        action.label(
                            PaneTabQuickActionContext(
                                isHovered: hovered,
                                isExpanded: quickActionShowsAll
                            )
                        )
                        .frame(width: resolvedQuickActionItemSize(dimension), height: resolvedQuickActionItemSize(dimension))
                        .background {
                            if hovered {
                                Circle().fill(Color.primary.opacity(0.12))
                            }
                        }
                        .scaleEffect(hovered ? 1.08 : 1)
                        .accessibilityLabel(action.accessibilityLabel)
                    }
                }
                .padding(.vertical, 6)
                .frame(width: dimension)
            }

            menuButton(context)
                .frame(width: dimension, height: dimension)
        }
        .frame(width: dimension, height: menuSourceHeight(dimension: dimension), alignment: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func menuButtonQuickActionGesture(dimension: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard menuState == .closed else { return }

                if !isMenuButtonPressing {
                    beginMenuButtonPress(at: value.time)
                }

                let travel = hypot(value.translation.width, value.translation.height)
                menuButtonMaximumTravel = max(menuButtonMaximumTravel, travel)
                let upwardTravel = max(0, -value.translation.height)
                let activationDistance = max(2, configuration.quickActionActivationDistance)

                if travel >= activationDistance, !quickActionInteractionActive {
                    // Moving before the hold completes turns this into a swipe, not a long press.
                    menuButtonGestureToken += 1
                }

                guard !quickActions.isEmpty else { return }
                guard upwardTravel >= activationDistance || quickActionInteractionActive else { return }

                // Keep the live swipe as the ordinary stacked quick-action menu.
                // A predictive sample can look like a flick long before the user
                // releases; committing Profile here used to hide Settings during
                // normal swipes. The fast shortcut is classified only at touch-up.
                let requestedCount = quickActionCount(
                    for: value.location,
                    dimension: dimension
                )
                let showsAll = quickActionShowsAll || requestedCount > 1
                let visibleCount = showsAll ? quickActions.count : requestedCount
                let visibleActions = displayedQuickActions(
                    previewActionID: nil,
                    visibleCount: visibleCount
                )
                activateQuickActions(
                    showsAll: showsAll,
                    visibleCount: visibleCount,
                    previewActionID: nil,
                    hoveredID: quickActionID(
                        at: value.location,
                        actions: visibleActions,
                        dimension: dimension
                    )
                )
            }
            .onEnded { value in
                finishMenuButtonPress(value, dimension: dimension)
            }
    }

    private var resolvedQuickActionVisibleCount: Int {
        guard quickActionInteractionActive, !quickActions.isEmpty else { return 0 }
        return min(max(1, quickActionVisibleCount), quickActions.count)
    }

    private var quickSwipeAction: PaneTabQuickAction? {
        quickActions.first { $0.activatesOnQuickSwipe }
    }

    private var resolvedVisibleQuickActions: [PaneTabQuickAction] {
        displayedQuickActions(
            previewActionID: nil,
            visibleCount: resolvedQuickActionVisibleCount
        )
    }

    private func displayedQuickActions(
        previewActionID: AnyHashable?,
        visibleCount: Int
    ) -> [PaneTabQuickAction] {
        if let previewActionID,
           let previewAction = quickActions.first(where: { $0.id == previewActionID }) {
            return [previewAction]
        }
        return Array(quickActions.prefix(min(max(0, visibleCount), quickActions.count)))
    }

    private var resolvedQuickActionSpacing: CGFloat {
        max(0, configuration.quickActionSpacing)
    }

    private func resolvedQuickActionItemSize(_ dimension: CGFloat) -> CGFloat {
        min(48, max(36, dimension - 12))
    }

    private func menuSourceHeight(dimension: CGFloat) -> CGFloat {
        let count = resolvedVisibleQuickActions.count
        guard count > 0 else { return dimension }
        let itemsHeight = resolvedQuickActionItemSize(dimension) * CGFloat(count)
        let spacingHeight = resolvedQuickActionSpacing * CGFloat(max(0, count - 1))
        return dimension + itemsHeight + spacingHeight + 12
    }

    private func menuSourceFrame(buttonFrame: CGRect, dimension: CGFloat) -> CGRect {
        let height = menuSourceHeight(dimension: dimension)
        return CGRect(
            x: buttonFrame.midX - (dimension / 2),
            y: buttonFrame.maxY - height,
            width: dimension,
            height: height
        )
    }

    private func quickActionCount(for location: CGPoint, dimension: CGFloat) -> Int {
        guard !quickActions.isEmpty else { return 0 }
        let itemSize = resolvedQuickActionItemSize(dimension)
        let pitch = max(1, itemSize + resolvedQuickActionSpacing)
        let firstCenterDistance = 6 + (itemSize / 2)
        let distanceAboveButton = max(0, menuButtonFrame.minY - location.y)
        let additionalItems = Int(
            max(0, distanceAboveButton - firstCenterDistance + (pitch / 2)) / pitch
        )
        return min(max(1, 1 + additionalItems), quickActions.count)
    }

    private func quickActionID(
        at location: CGPoint,
        actions: [PaneTabQuickAction],
        dimension: CGFloat
    ) -> AnyHashable? {
        let itemSize = resolvedQuickActionItemSize(dimension)
        let radius = itemSize / 2
        let pitch = max(1, itemSize + resolvedQuickActionSpacing)

        for (index, action) in actions.enumerated() {
            let center = CGPoint(
                x: menuButtonFrame.midX,
                y: menuButtonFrame.minY - 6 - radius - (CGFloat(index) * pitch)
            )
            if hypot(location.x - center.x, location.y - center.y) <= radius {
                return action.id
            }
        }

        return nil
    }

    private func qualifiesAsQuickSwipe(
        _ value: DragGesture.Value,
        minimumDragDistance: CGFloat
    ) -> Bool {
        guard quickSwipeAction != nil,
              !quickActionsActivatedByLongPress,
              let startedAt = menuButtonPressStartedAt else {
            return false
        }

        let elapsed = max(0, value.time.timeIntervalSince(startedAt))
        let maximumDuration = max(0.1, configuration.quickSwipeMaximumDuration)
        return isQuickUpwardSwipe(
            elapsed: elapsed,
            translation: value.translation,
            predictedEndTranslation: value.predictedEndTranslation,
            activationDistance: configuration.quickActionActivationDistance,
            minimumDragDistance: minimumDragDistance,
            maximumDuration: maximumDuration,
            predictedDistance: configuration.quickSwipePredictedDistance
        )
    }

    private func beginMenuButtonPress(at time: Date) {
        isMenuButtonPressing = true
        menuButtonMaximumTravel = 0
        menuButtonPressStartedAt = time
        quickActionsActivatedByLongPress = false
        menuButtonGestureToken += 1
        let token = menuButtonGestureToken
        let delay = max(0.1, configuration.quickActionLongPressDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { @MainActor in
            guard token == menuButtonGestureToken,
                  isMenuButtonPressing,
                  !quickActions.isEmpty,
                  menuState == .closed else { return }
            quickActionsActivatedByLongPress = true
            activateQuickActions(
                showsAll: true,
                visibleCount: quickActions.count,
                previewActionID: nil,
                hoveredID: nil
            )
        }
    }

    private func activateQuickActions(
        showsAll: Bool,
        visibleCount: Int,
        previewActionID: AnyHashable?,
        hoveredID: AnyHashable?
    ) {
        let wasActive = quickActionInteractionActive
        let previousHoveredID = hoveredQuickActionID
        let resolvedVisibleCount = min(max(1, visibleCount), quickActions.count)
        let stateChanged = !quickActionInteractionActive ||
            quickActionShowsAll != showsAll ||
            quickActionVisibleCount != resolvedVisibleCount ||
            hoveredQuickActionID != hoveredID

        if stateChanged {
            performAnimated(configuration.chromeAnimation) {
                quickActionInteractionActive = true
                quickActionShowsAll = showsAll
                quickActionVisibleCount = resolvedVisibleCount
                hoveredQuickActionID = hoveredID
            }
        }

        if !wasActive {
            performNavigationHaptic(.medium, enabled: configuration.hapticsEnabled)
        }
        if let hoveredID, hoveredID != previousHoveredID {
            performNavigationHaptic(.light, enabled: configuration.hapticsEnabled)
        }
    }

    private func finishMenuButtonPress(_ value: DragGesture.Value, dimension: CGFloat) {
        menuButtonGestureToken += 1
        isMenuButtonPressing = false

        if qualifiesAsQuickSwipe(value, minimumDragDistance: dimension),
           let quickSwipeAction {
            resetQuickActionInteraction(animated: true)
            performNavigationHaptic(.medium, enabled: configuration.hapticsEnabled)
            DispatchQueue.main.async { @MainActor in quickSwipeAction.action() }
            return
        }

        if quickActionInteractionActive {
            let releasedVisibleCount = quickActionShowsAll
                ? quickActions.count
                : quickActionCount(for: value.location, dimension: dimension)
            let releasedActions = displayedQuickActions(
                previewActionID: nil,
                visibleCount: releasedVisibleCount
            )
            let releasedActionID = quickActionID(
                at: value.location,
                actions: releasedActions,
                dimension: dimension
            )
            let selectedAction = quickActions.first { $0.id == releasedActionID }
            resetQuickActionInteraction(animated: true)
            if let selectedAction {
                performNavigationHaptic(.medium, enabled: configuration.hapticsEnabled)
                DispatchQueue.main.async { @MainActor in selectedAction.action() }
            }
        } else {
            let wasTap = menuButtonMaximumTravel < 4
            resetQuickActionInteraction(animated: false)
            if wasTap {
                presentMenu()
            }
        }
    }

    private func resetQuickActionInteraction(animated: Bool) {
        menuButtonGestureToken += 1
        let changes = {
            isMenuButtonPressing = false
            quickActionInteractionActive = false
            quickActionShowsAll = false
            hoveredQuickActionID = nil
            quickActionVisibleCount = 0
            menuButtonMaximumTravel = 0
            menuButtonPressStartedAt = nil
            quickActionsActivatedByLongPress = false
        }
        if animated {
            performAnimated(configuration.chromeAnimation, changes)
        } else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction, changes)
        }
    }

    private func menuButtonSurface(dimension: CGFloat) -> some View {
        let context = PaneTabMenuButtonContext(
            showsQuickActions: quickActionInteractionActive,
            quickActionExpansionProgress: quickActions.isEmpty
                ? 0
                : CGFloat(resolvedVisibleQuickActions.count) / CGFloat(quickActions.count)
        )

        return Color.clear
            .frame(width: dimension, height: dimension)
            .contentShape(Circle())
            .gesture(menuButtonQuickActionGesture(dimension: dimension), including: .all)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(configuration.menuButtonAccessibilityLabel)
            .accessibilityAction { presentMenu() }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PaneTabMenuButtonFrameKey.self,
                        value: proxy.frame(in: .global)
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                if menuState == .closed {
                    menuButtonAdornment(context)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private func scrubGesture(
        horizontal: Bool,
        padding: CGFloat,
        majorLength: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !tabs.isEmpty, majorLength > 0 else { return }
                let rawPosition = (horizontal ? value.location.x : value.location.y) - padding
                let clampedPosition = rawPosition.clamped(to: 0...majorLength)
                if scrubStartAxisPosition == nil {
                    scrubStartAxisPosition = clampedPosition
                }
                if let scrubStartAxisPosition,
                   abs(clampedPosition - scrubStartAxisPosition) >= 4 {
                    isScrubbing = true
                    scrubAxisPosition = clampedPosition
                } else if isScrubbing {
                    scrubAxisPosition = clampedPosition
                }
            }
            .onEnded { value in
                guard !tabs.isEmpty, majorLength > 0 else {
                    scrubAxisPosition = nil
                    scrubStartAxisPosition = nil
                    isScrubbing = false
                    return
                }

                let position = (horizontal ? value.location.x : value.location.y) - padding
                let predicted = (horizontal ? value.predictedEndLocation.x : value.predictedEndLocation.y) - padding
                let projected = position + ((predicted - position) * 0.35)
                let index = nearestTabIndex(
                    to: projected.clamped(to: 0...majorLength),
                    majorLength: majorLength
                )
                let tab = tabs[index]

                if selection != tab {
                    performNavigationHaptic(.light, enabled: configuration.hapticsEnabled)
                }

                performAnimated(configuration.selectionAnimation) {
                    selection = tab
                    scrubAxisPosition = nil
                    scrubStartAxisPosition = nil
                    isScrubbing = false
                }
            }
    }

    private var menuPresentedBinding: Binding<Bool> {
        Binding(
            get: { menuState != .closed },
            set: { presented in
                if presented {
                    if menuState == .closed {
                        menuState = .compact
                    }
                } else {
                    menuState = .closed
                }
            }
        )
    }

    private var menuDetentBinding: Binding<PaneDetent> {
        Binding(
            get: { menuState == .expanded ? .large : compactDetent },
            set: { detent in
                guard menuState != .closed else { return }
                menuState = detent == .large ? .expanded : .compact
            }
        )
    }

    private func paneConfig(
        placement: PaneTabBarPlacement,
        presentationSource: PanePresentationSource
    ) -> PaneConfig {
        let margin = max(0, menuConfiguration.compactMargin)
        let expansionAxis: PaneExpansionAxis = isHorizontal(placement) ? .vertical : .horizontal
        let anchor: Alignment
        let collapsedInsets: EdgeInsets

        switch placement {
        case .bottom, .automatic:
            anchor = .bottomTrailing
            collapsedInsets = EdgeInsets(top: 0, leading: margin, bottom: 0, trailing: margin)
        case .leading:
            anchor = .bottomLeading
            collapsedInsets = EdgeInsets(top: margin, leading: 0, bottom: margin, trailing: 0)
        case .trailing:
            anchor = .bottomTrailing
            collapsedInsets = EdgeInsets(top: margin, leading: 0, bottom: margin, trailing: 0)
        }

        return PaneConfig(
            detents: [compactDetent, .large],
            showsDragIndicator: menuConfiguration.showsDragIndicator,
            allowsBackgroundInteraction: false,
            tapOutsideToDismiss: true,
            allowsSwipeToDismiss: true,
            cornerRadius: menuConfiguration.cornerRadius,
            topInset: 0,
            horizontalPadding: 0,
            dimmingOpacity: menuConfiguration.dimmingOpacity,
            crossAxisSize: .fill,
            anchor: anchor,
            expansionAxis: expansionAxis,
            targetView: PaneTargetView(
                tag: menuScrollAnchorID,
                alignment: .top,
                alignsWhenNotLarge: true,
                tracksWhileNotLarge: false,
                showsAlignmentIndicator: false
            ),
            scrollSnapBehavior: .none,
            handleInteractionZone: PaneHandleInteractionZone(
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
                systemGestureDeferralEdges: menuConfiguration.systemGestureDeferralEdges,
                systemGestureDeferralActivationDistance: 56
            ),
            dragIndicatorContentInset: menuConfiguration.dragIndicatorContentInset,
            dragIndicatorTouchExtension: menuConfiguration.dragIndicatorTouchExtension,
            dragIndicatorFadeLength: menuConfiguration.dragIndicatorFadeLength,
            allowsContentInteractionWhenNotFullyExpanded: menuConfiguration.allowsContentInteractionWhenCompact,
            systemGestureDeferralEdges: menuConfiguration.systemGestureDeferralEdges,
            dismissThresholdMultiplier: menuConfiguration.dismissThresholdMultiplier,
            handleDismissDistance: menuConfiguration.handleDismissDistance,
            handleDismissPredictedDistance: menuConfiguration.handleDismissPredictedDistance,
            allowsSwipeToDismissFromAnywhere: menuConfiguration.allowsSwipeToDismissFromAnywhere,
            minimumDetentDragBehavior: menuConfiguration.minimumDetentDragBehavior,
            allowsScrollCollapseFromAnyPosition: menuConfiguration.allowsScrollCollapseFromAnyPosition,
            scrollCollapseActivationDistance: menuConfiguration.scrollCollapseActivationDistance,
            preventsContentActivationDuringDrag: menuConfiguration.preventsContentActivationDuringDrag,
            animation: menuConfiguration.animation,
            crossAxisTransition: PaneCrossAxisTransition(
                collapsed: PaneCrossAxisGeometry(size: .fill, insets: collapsedInsets),
                expanded: PaneCrossAxisGeometry(size: .fill)
            ),
            collapsedAnchorInset: margin,
            interactionAxis: .vertical,
            interactionEdge: .bottom,
            minimumDimmingOpacity: menuConfiguration.minimumDimmingOpacity,
            presentationTransition: .sourceMorph(presentationSource),
            surfaceStyle: menuConfiguration.surfaceStyle ?? .glass(
                style: configuration.glassStyle,
                tint: configuration.tint,
                interactive: configuration.glassIsInteractive
            ),
            surfaceSolidColor: menuConfiguration.surfaceSolidColor,
            surfaceTintOpacityTransition: menuConfiguration.surfaceTintOpacityTransition,
            hapticsEnabled: menuConfiguration.hapticsEnabled
        )
    }

    private func highlightedTabIndex(
        majorLength: CGFloat,
        padding: CGFloat,
        cellLength: CGFloat
    ) -> Int {
        guard !tabs.isEmpty else { return 0 }
        if let scrubAxisPosition {
            return nearestTabIndex(to: scrubAxisPosition, majorLength: majorLength)
        }
        return tabs.firstIndex(of: selection) ?? 0
    }

    private func indicatorCenter(
        highlightedIndex: Int,
        majorLength: CGFloat,
        padding: CGFloat,
        cellLength: CGFloat,
        crossLength: CGFloat,
        horizontal: Bool
    ) -> CGPoint {
        let selectedCenter = padding + (cellLength * (CGFloat(highlightedIndex) + 0.5))
        let halfCell = cellLength / 2
        let scrubCenter = scrubAxisPosition.map {
            padding + $0.clamped(to: halfCell...max(halfCell, majorLength - halfCell))
        }
        let majorCenter = scrubCenter ?? selectedCenter
        let crossCenter = padding + (crossLength / 2)
        return horizontal
            ? CGPoint(x: majorCenter, y: crossCenter)
            : CGPoint(x: crossCenter, y: majorCenter)
    }

    private func nearestTabIndex(to position: CGFloat, majorLength: CGFloat) -> Int {
        guard tabs.count > 1, majorLength > 0 else { return 0 }
        let cellLength = majorLength / CGFloat(tabs.count)
        let index = Int((position / cellLength).rounded(.down))
        return min(max(index, 0), tabs.count - 1)
    }

    private func settleSelection(on tab: Tab) {
        if selection != tab {
            performNavigationHaptic(.light, enabled: configuration.hapticsEnabled)
        }
        performAnimated(configuration.selectionAnimation) {
            selection = tab
            scrubAxisPosition = nil
            scrubStartAxisPosition = nil
            isScrubbing = false
        }
    }

    private func presentMenu() {
        performNavigationHaptic(.medium, enabled: menuConfiguration.hapticsEnabled)
        performAnimated(menuConfiguration.animation) {
            menuState = .compact
        }
    }

    private func reconcileSelection() {
        guard !tabs.isEmpty, !tabs.contains(selection), let first = tabs.first else { return }
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selection = first
        }
    }

    private func resetChromeInteraction() {
        guard scrubAxisPosition != nil || scrubStartAxisPosition != nil || isScrubbing else { return }
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrubAxisPosition = nil
            scrubStartAxisPosition = nil
            isScrubbing = false
        }
    }

    private func performAnimated(_ animation: Animation, _ changes: () -> Void) {
        if reduceMotion {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction, changes)
        } else {
            withAnimation(animation, changes)
        }
    }

    private func performNavigationHaptic(_ style: ImpactFeedbackStyle, enabled: Bool) {
        guard enabled else { return }
        impact(style)
    }

    @ViewBuilder
    private func isolatedGlassScope<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer(spacing: 0) {
                content()
            }
        } else {
            content()
        }
    }

    private func resolvedPlacement(for size: CGSize) -> PaneTabBarPlacement {
        if configuration.placement != .automatic {
            return configuration.placement
        }
        guard size.width > size.height else { return .bottom }

        #if canImport(UIKit)
        switch windowMetrics?.interfaceOrientation {
        case .landscapeLeft:
            return .leading
        case .landscapeRight:
            return .trailing
        default:
            break
        }
        #endif

        return layoutDirection == .rightToLeft ? .trailing : .leading
    }

    private func resolvedBarThickness(in size: CGSize, margin: CGFloat) -> CGFloat {
        if let barThickness = configuration.barThickness {
            return max(44, barThickness)
        }
        let shortSide = min(size.width, size.height)
        return max(52, (screenCornerRadius(for: shortSide) * 2) - max(0, margin))
    }

    private func isHorizontal(_ placement: PaneTabBarPlacement) -> Bool {
        placement == .bottom || placement == .automatic
    }

    private func chromeAlignment(
        for placement: PaneTabBarPlacement,
        showsTabBar: Bool
    ) -> Alignment {
        if !showsTabBar {
            switch placement {
            case .bottom, .trailing, .automatic: return .bottomTrailing
            case .leading: return .bottomLeading
            }
        }

        switch placement {
        case .bottom, .automatic: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }

    private func menuSourceAnchor(for placement: PaneTabBarPlacement) -> UnitPoint {
        switch placement {
        case .bottom, .trailing, .automatic: .bottomTrailing
        case .leading: .bottomLeading
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
