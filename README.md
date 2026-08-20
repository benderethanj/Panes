# ``Panes``

A SwiftUI pane engine with velocity-aware detents, scroll-to-pane gesture handoff,
adaptive geometry, and reusable tab navigation chrome.

## Overview

Use `View.pane` for custom sheet presentations and `PaneScrollView` when scrolling
content should hand its active pan gesture to the pane at an edge. For an app-level
tab switcher with a source-button menu presentation, use `PaneTabNavigation`.

```swift
@State private var selection = AppTab.home
@State private var menuState = PaneTabMenuState.closed

PaneTabNavigation(
    selection: $selection,
    tabs: AppTab.allCases,
    menuState: $menuState,
    content: { tab in
        tab.content
    },
    tabLabel: { context in
        Image(systemName: context.tab.symbol)
    },
    indicator: { context in
        Capsule().fill(.tint).frame(width: context.size.width, height: context.size.height)
    },
    menuButton: {
        Image(systemName: "square.grid.2x2.fill")
    },
    menu: { context in
        PaneTabMenu(
            context: context,
            header: { Text("Menu") },
            content: { MenuRows() },
            footer: { CloseButton(action: context.dismiss) }
        )
    }
)
```

The compact menu detent is derived from its cross-axis length, so it remains square.
On wide layouts it expands horizontally while retaining vertical scroll gestures.
The menu surface stays mounted inside one `GlassEffectContainer`: while closed it
uses the measured menu-button frame, and while open that same glass view adopts the
live pane frame and corner radius. There is no source/destination surface swap.
`PaneScrollView` keeps content offset, bounce suppression, translation, and velocity
in one continuous gesture. Older systems render the same persistent-frame animation
with material rather than Liquid Glass.

`PaneTabNavigationConfiguration` separately controls the tab surface content inset,
idle/scrubbing margins and padding, menu-button spacing, glass interactivity, and
whether a single available tab hides the tab surface while retaining the menu button.
Its optional `PaneTabQuickAction` items expand the same menu-button glass into a
vertical shortcut capsule. Mark one action with `activatesOnQuickSwipe: true` to
make a fast upward flick perform that shortcut; held and slower drags continue to
use exact icon hit testing.
`PaneTabMenuConfiguration` exposes both distance and predicted-distance dismiss
thresholds. Its tab-menu defaults require a deliberate downward pull at the scroll
edge, follow the finger continuously below the compact detent, and suppress control
activation without applying SwiftUI's disabled appearance. Distance shortcuts close
directly only when the drag starts compact, so an expanded menu can still settle back
to compact. It also enables haptic feedback and ramps the glass tint from translucent
at the compact detent to a solid fill at full expansion. General-purpose `PaneConfig`
keeps those behaviors opt-in through `allowsScrollCollapseFromAnyPosition`,
`minimumDetentDragBehavior`, `allowsSwipeToDismissFromAnywhere`,
`preventsContentActivationDuringDrag`, `hapticsEnabled`, and
`surfaceTintOpacityTransition`.

## Topics

### Tab navigation

- `PaneTabNavigation`
- `PaneTabNavigationConfiguration`
- `PaneTabMenu`
- `PaneTabMenuConfiguration`
- `PaneTabMenuState`

### Pane presentation

- `PaneConfig`
- `PaneDetent`
- `PaneScrollView`
- `PaneCrossAxisTransition`
- `PanePresentationTransition`
