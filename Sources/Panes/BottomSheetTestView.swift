import SwiftUI

struct PaneDemoView: View {
    @State private var isPanePresented = true
    @State private var selectedDetent: PaneDetent = .medium

    @State private var showDragIndicator = true
    @State private var allowsBackgroundInteraction = true
    @State private var allowsSwipeToDismiss = true
    @State private var tapOutsideToDismiss = true
    @State private var widthFraction: CGFloat = 1
    @State private var anchorPreset: PaneAnchorPreset = .bottom
    @State private var expansionAxis: PaneExpansionAxis = .vertical
    @State private var pinTaggedViewOnCollapse = true
    @State private var trackTaggedViewWhileCollapsed = false
    @State private var snapScrollToViews = false
    @State private var allowsContentInteractionWhenCollapsed = true
    @State private var dragIndicatorTouchExtension: CGFloat = 0
    @State private var deferTopSystemGestures = false
    @State private var deferBottomSystemGestures = false

    private var presentationOptions: PaneConfig {
        PaneConfig(
            detents: [.fraction(0.2), .medium, .large],
            largestUndimmedDetent: .large,
            showsDragIndicator: showDragIndicator,
            allowsBackgroundInteraction: allowsBackgroundInteraction,
            tapOutsideToDismiss: tapOutsideToDismiss,
            allowsSwipeToDismiss: allowsSwipeToDismiss,
            cornerRadius: screenCornerRadius(),
            topInset: 0,
            horizontalPadding: 12,
            dimmingOpacity: 0,
            crossAxisSize: .fraction(widthFraction),
            anchor: anchorPreset.alignment,
            expansionAxis: expansionAxis,
            collapsedScrollAnchorTag: pinTaggedViewOnCollapse ? AnyHashable("collapse-anchor") : nil,
            collapsedScrollAnchor: .top,
            keepsCollapsedScrollAnchorPinned: pinTaggedViewOnCollapse,
            tracksCollapsedScrollAnchor: trackTaggedViewWhileCollapsed,
            scrollSnapBehavior: snapScrollToViews ? .viewAligned : .none,
            dragIndicatorTouchExtension: dragIndicatorTouchExtension,
            allowsContentInteractionWhenNotFullyExpanded: allowsContentInteractionWhenCollapsed,
            systemGestureDeferralEdges: systemGestureDeferralEdges,
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .cyan.opacity(0.25), .mint.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Pane")
                    .font(.title3.weight(.semibold))

                Button(isPanePresented ? "Hide Pane" : "Show Pane") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        isPanePresented.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)

                ScrollView {
                    VStack(spacing: 12) {
                        Picker("Detent", selection: $selectedDetent) {
                            Text("Peek").tag(PaneDetent.fraction(0.2))
                            Text("Medium").tag(PaneDetent.medium)
                            Text("Large").tag(PaneDetent.large)
                        }
                        .pickerStyle(.segmented)

                        Picker("Anchor", selection: $anchorPreset) {
                            ForEach(PaneAnchorPreset.allCases) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Expansion Axis", selection: $expansionAxis) {
                            Text("Vertical").tag(PaneExpansionAxis.vertical)
                            Text("Horizontal").tag(PaneExpansionAxis.horizontal)
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expansion Behavior")
                                .font(.caption.weight(.semibold))
                            Text(expansionBehaviorSummary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cross-Axis Size \(Int(widthFraction * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $widthFraction, in: 0.3...1)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Indicator Touch Extension \(Int(dragIndicatorTouchExtension.rounded()))pt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $dragIndicatorTouchExtension, in: 0...36, step: 1)
                        }

                        Toggle("Show Drag Indicator", isOn: $showDragIndicator)
                        Toggle("Allow Background Interaction", isOn: $allowsBackgroundInteraction)
                        Toggle("Allow Swipe To Dismiss", isOn: $allowsSwipeToDismiss)
                        Toggle("Tap Outside To Dismiss", isOn: $tapOutsideToDismiss)
                        Toggle("Pin Tagged View On Collapse", isOn: $pinTaggedViewOnCollapse)
                        Toggle("Track Tagged View While Partial", isOn: $trackTaggedViewWhileCollapsed)
                        Toggle("Snap Scroll To Views", isOn: $snapScrollToViews)
                        Toggle("Allow Content Interaction When Partial", isOn: $allowsContentInteractionWhenCollapsed)
                        Toggle("Defer Top System Gestures", isOn: $deferTopSystemGestures)
                        Toggle("Defer Bottom System Gestures", isOn: $deferBottomSystemGestures)
                    }
                    .padding(.top, 4)
                }
                .frame(maxHeight: 360)
            }
            .padding(20)
            .glassEffectIfAvailable(cornerRadius: 28)
            .padding()
        }
        .pane(
            isPresented: $isPanePresented,
            selectedDetent: $selectedDetent,
            config: presentationOptions
        ) { context in
            PaneScrollView(
                state: context.scrollState,
                collapsedScrollAnchorTag: context.options.collapsedScrollAnchorTag,
                shouldPinCollapsedScrollAnchor: context.options.keepsCollapsedScrollAnchorPinned && !context.isSelectedDetentFullyExpanded,
                tracksCollapsedScrollAnchor: context.options.tracksCollapsedScrollAnchor,
                scrollSnapBehavior: context.options.scrollSnapBehavior,
                collapsedScrollAnchor: context.options.collapsedScrollAnchor
            ) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("Native sheet-style behavior")
                        .font(.headline)
                        .padding(.top, 6)
                        .paneAnchorTag("collapse-anchor")

                    Text("Detent: \(context.selectedDetentLabel)  |  Progress: \(Int((context.expansionProgress * 100).rounded()))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    #if canImport(UIKit)
                    Text(
                        "Offset \(Int(context.scrollState.scrollOffset.rounded()))  |  Pan \(context.scrollState.panGestureStartContentOffsetY.map { String(Int($0.rounded())) } ?? "-")  |  Lock Δ \(Int(context.scrollState.lastLockedOffsetCorrectionDeltaY.rounded()))  |  Freeze \(context.scrollState.frozenViewportSnapshot == nil ? "off" : "on")  |  Block \(context.scrollState.preHandoffPanShouldBeginBlockCount)  |  Pass \(context.scrollState.preHandoffPanShouldBeginPassCount)  |  Bounce \(context.scrollState.preHandoffBounceSuppressed ? "off" : "on")"
                    )
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    #endif

                    Text("Drag the pane, scroll this content, and swipe down from the top to collapse. Scroll gestures expand/collapse the pane until it reaches min/max detents.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(1..<60, id: \.self) { index in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(.white.opacity(0.22))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Text("\(index)")
                                        .font(.caption.weight(.semibold))
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Item \(index)")
                                    .font(.body.weight(.semibold))
                                Text("Scroll and drag behavior mirrors system sheets.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.12))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
    }

    private var expansionBehaviorSummary: String {
        switch expansionAxis {
        case .vertical:
            switch anchorPreset.alignment {
            case .topLeading, .top, .topTrailing:
                return "Expands downward from top anchor."
            case .bottomLeading, .bottom, .bottomTrailing:
                return "Expands upward from bottom anchor."
            default:
                return "Expands equally up and down from center."
            }
        case .horizontal:
            switch anchorPreset.alignment {
            case .topLeading, .leading, .bottomLeading:
                return "Expands rightward from leading anchor."
            case .topTrailing, .trailing, .bottomTrailing:
                return "Expands leftward from trailing anchor."
            default:
                return "Expands equally left and right from center."
            }
        }
    }

    private var systemGestureDeferralEdges: Edge.Set {
        var edges: Edge.Set = []

        if deferTopSystemGestures {
            edges.formUnion(.top)
        }
        if deferBottomSystemGestures {
            edges.formUnion(.bottom)
        }

        return edges
    }
}

#Preview {
    PaneDemoView()
}
