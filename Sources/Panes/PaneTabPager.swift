#if os(iOS)
import SwiftUI
import UIKit

/// Own programmatic page transitions so a tab jump presents only its destination.
/// UIKit also reports the actual end of the slide, independently of SwiftUI transactions.
struct PaneTabPager<Tab: Hashable, Content: View>: UIViewControllerRepresentable {
    @Binding var selection: Tab
    let tabs: [Tab]
    let content: (Tab) -> Content
    let onSelectionSettled: ((Tab) -> Void)?
    @Environment(\.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    init(selection: Binding<Tab>, tabs: [Tab], content: @escaping (Tab) -> Content,
         onSelectionSettled: ((Tab) -> Void)?) {
        _selection = selection
        self.tabs = tabs
        self.content = content
        self.onSelectionSettled = onSelectionSettled
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        controller.view.backgroundColor = .clear
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        context.coordinator.update(controller, parent: self)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.update(controller, parent: self)
    }

    static func dismantleUIViewController(_ controller: UIPageViewController, coordinator: Coordinator) {
        controller.delegate = nil
        controller.dataSource = nil
        coordinator.detach(from: controller)
    }

    @MainActor
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        private var parent: PaneTabPager
        private var hosts: [Tab: UIHostingController<PaneTabPagerPage<Content>>] = [:]
        private var isTransitioning = false
        private var activeTransitionID: UUID?
        private var needsNormalization = false
        private var swipeStartSelection: Tab?
        private var lastSettledSelection: Tab?
        private var selectionUpdateScheduled = false
        fileprivate var isAttached = true

        init(_ parent: PaneTabPager) { self.parent = parent }

        func update(_ controller: UIPageViewController, parent: PaneTabPager) {
            self.parent = parent
            if !isTransitioning {
                hosts = hosts.filter { parent.tabs.contains($0.key) || $0.value === controller.viewControllers?.first }
            }
            for (tab, host) in hosts {
                host.rootView = page(for: tab)
            }
            scheduleSelectionUpdate(in: controller)
        }

        private func scheduleSelectionUpdate(in controller: UIPageViewController) {
            guard isAttached, !selectionUpdateScheduled else { return }
            selectionUpdateScheduled = true
            // Start UIKit's animation after SwiftUI's update transaction has ended.
            DispatchQueue.main.async { [weak self, weak controller] in
                guard let self, let controller, self.isAttached else { return }
                self.selectionUpdateScheduled = false
                self.showRequestedPage(in: controller)
            }
        }

        fileprivate func detach(from controller: UIPageViewController) {
            isAttached = false
            activeTransitionID = nil
            isTransitioning = false
            needsNormalization = false
            swipeStartSelection = nil
            selectionUpdateScheduled = false
            controller.view.isUserInteractionEnabled = true
        }

        private func page(for tab: Tab) -> PaneTabPagerPage<Content> {
            let content = parent.content
            return PaneTabPagerPage(content: { content(tab) }, environment: parent.environment)
        }

        private func host(for tab: Tab) -> UIHostingController<PaneTabPagerPage<Content>> {
            if let host = hosts[tab] { return host }
            let host = UIHostingController(rootView: page(for: tab))
            host.view.backgroundColor = .clear
            hosts[tab] = host
            return host
        }

        private func tab(for controller: UIViewController?) -> Tab? {
            hosts.first { $0.value === controller }?.key
        }

        private func showRequestedPage(in controller: UIPageViewController) {
            // During either a swipe or an animated tab selection, retain the latest
            // requested selection and apply it when UIKit finishes the current slide.
            guard isAttached, !isTransitioning else { return }
            guard let target = parent.tabs.first(where: { $0 == parent.selection }) ?? parent.tabs.first else {
                controller.view.isUserInteractionEnabled = true
                return
            }
            let visible = controller.viewControllers?.first
            let current = tab(for: visible)
            guard current != target || needsNormalization else {
                controller.view.isUserInteractionEnabled = true
                reportSettled(target)
                return
            }

            let oldIndex = current.flatMap { parent.tabs.firstIndex(of: $0) }
            let newIndex = parent.tabs.firstIndex(of: target) ?? 0
            let advances = newIndex > (oldIndex ?? newIndex)
            let movesForward = parent.layoutDirection == .rightToLeft ? !advances : advances
            let animated = !needsNormalization && visible != nil && controller.view.window != nil && !parent.reduceMotion
            let transitionID = UUID()
            activeTransitionID = transitionID
            isTransitioning = true
            needsNormalization = false
            lastSettledSelection = nil
            controller.view.isUserInteractionEnabled = false
            let destination = host(for: target)
            let direction: UIPageViewController.NavigationDirection = movesForward ? .forward : .reverse
            guard animated else {
                // A nonanimated presentation is installed when the call returns;
                // UIKit need not invoke a completion to unlock the page.
                controller.setViewControllers([destination], direction: direction, animated: false)
                finishPresentation(transitionID, finished: true, in: controller)
                return
            }
            controller.setViewControllers(
                [destination],
                direction: direction,
                animated: true
            ) { [weak self, weak controller] finished in
                // UIKit must unwind its completion before another presentation.
                DispatchQueue.main.async { [weak self, weak controller] in
                    guard let self, let controller else { return }
                    self.finishPresentation(transitionID, finished: finished, in: controller)
                }
            }
        }

        private func finishPresentation(_ transitionID: UUID, finished: Bool, in controller: UIPageViewController) {
            guard isAttached, activeTransitionID == transitionID else { return }
            activeTransitionID = nil
            isTransitioning = false
            needsNormalization = !finished
            controller.view.isUserInteractionEnabled = finished
            if finished, let visibleTab = tab(for: controller.viewControllers?.first) {
                reportSettled(visibleTab)
            }
            // An interrupted slide can report its target without installing it.
            // Reinstall the latest requested cached host without an animation.
            scheduleSelectionUpdate(in: controller)
        }

        private func reportSettled(_ tab: Tab) {
            guard parent.selection == tab, lastSettledSelection != tab else { return }
            lastSettledSelection = tab
            // Initial/nonanimated presentation may finish during a SwiftUI update.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isAttached, !self.isTransitioning,
                      self.parent.selection == tab else { return }
                self.parent.onSelectionSettled?(tab)
            }
        }

        private func neighbor(of controller: UIViewController, step: Int) -> UIViewController? {
            guard let tab = tab(for: controller), let index = parent.tabs.firstIndex(of: tab) else { return nil }
            let next = index + step
            guard parent.tabs.indices.contains(next) else { return nil }
            return host(for: parent.tabs[next])
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            neighbor(of: viewController, step: parent.layoutDirection == .rightToLeft ? 1 : -1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            neighbor(of: viewController, step: parent.layoutDirection == .rightToLeft ? -1 : 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                willTransitionTo pendingViewControllers: [UIViewController]) {
            guard isAttached, !isTransitioning else { return }
            isTransitioning = true
            lastSettledSelection = nil
            swipeStartSelection = parent.selection
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard isAttached, activeTransitionID == nil, let swipeStartSelection else { return }
            isTransitioning = false
            if completed, parent.selection == swipeStartSelection,
               let visibleTab = tab(for: pageViewController.viewControllers?.first) {
                // A button pressed during the swipe takes precedence over its result.
                parent.selection = visibleTab
            }
            self.swipeStartSelection = nil
            needsNormalization = !finished
            scheduleSelectionUpdate(in: pageViewController)
        }
    }
}

struct PaneTabPagerPage<Content: View>: View {
    let content: () -> Content
    let environment: EnvironmentValues

    var body: some View { content().environment(\.self, environment) }
}
#endif
