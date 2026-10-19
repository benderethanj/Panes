#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import Panes

@Test @MainActor func paneTabPagerNonanimatedPresentationDoesNotRequireCompletion() async throws {
    let driver = PaneTabPagerDriver(completesNonanimatedImmediately: false)
    defer { driver.close() }

    driver.request(0)
    await drainPagerMainQueue()

    let initial = try #require(driver.controller.presentations.first)
    #expect(!initial.animated)
    #expect(driver.controller.view.isUserInteractionEnabled)

    driver.request(1)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 2)
    let next = try #require(driver.controller.presentations.last)
    #expect(next.animated)
    #expect(next.target === (try driver.cachedHost(at: 1)))
}

@Test @MainActor func paneTabPagerNeverPresentsInsideAnotherCompletion() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    driver.request(1)
    await drainPagerMainQueue()
    let first = try #require(driver.controller.presentations.last)
    #expect(first.animated)

    driver.request(2)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 2)
    driver.controller.finish(first, finished: true)
    #expect(driver.controller.presentations.allSatisfy { !$0.startedInsideCompletion })

    await drainPagerMainQueue()
    let second = try #require(driver.controller.presentations.last)
    #expect(driver.controller.presentations.count == 3)
    #expect(second.target === (try driver.cachedHost(at: 2)))
    #expect(!second.startedInsideCompletion)
    driver.controller.finish(second, finished: true)
    await drainPagerMainQueue()
    #expect(driver.controller.view.isUserInteractionEnabled)
    #expect(driver.state.settled.last == 2)
}

@Test @MainActor func paneTabPagerRapidBindingUpdatesConvergeOnLatestSelection() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let latestHost = try driver.cachedHost(at: 3)
    driver.request(1)
    await drainPagerMainQueue()
    let first = try #require(driver.controller.presentations.last)

    for selection in [2, 3, 0, 2, 3] { driver.request(selection) }
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 2)
    driver.controller.finish(first, finished: true)
    await drainPagerMainQueue()

    let latest = try #require(driver.controller.presentations.last)
    #expect(driver.controller.presentations.count == 3)
    #expect(latest.target === latestHost)
    driver.controller.finish(latest, finished: true)
    await drainPagerMainQueue()
    #expect(driver.state.selection == 3)
    #expect(driver.state.settled.last == 3)
    #expect(driver.controller.viewControllers?.first === latestHost)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerFailedTransitionNormalizesEvenWhenUIKitReportsLatestHost() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let latestHost = try driver.cachedHost(at: 2)
    driver.request(1)
    await drainPagerMainQueue()
    let interrupted = try #require(driver.controller.presentations.last)
    #expect(interrupted.animated)
    driver.request(2)
    await drainPagerMainQueue()

    // A reported target does not prove UIKit finished installing that page.
    driver.controller.report([latestHost])
    driver.controller.finish(interrupted, finished: false)
    await drainPagerMainQueue()

    #expect(driver.controller.presentations.count == 3)
    let normalized = try #require(driver.controller.presentations.dropFirst(2).first)
    #expect(!normalized.animated)
    #expect(!normalized.startedInsideCompletion)
    #expect(normalized.target === latestHost)
    #expect(driver.controller.viewControllers?.first === latestHost)
    #expect(driver.controller.view.isUserInteractionEnabled)
    #expect(driver.state.selection == 2)
    #expect(driver.state.settled.last == 2)
}

@Test @MainActor func paneTabPagerStaleCompletionCannotFinishANewerTransition() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let secondHost = try driver.cachedHost(at: 2)
    let latestHost = try driver.cachedHost(at: 3)
    driver.request(1)
    await drainPagerMainQueue()
    let first = try #require(driver.controller.presentations.last)
    driver.request(2)
    await drainPagerMainQueue()
    driver.controller.finish(first, finished: true)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 3)
    let second = try #require(driver.controller.presentations.last)
    #expect(second.target === secondHost)

    driver.request(3)
    await drainPagerMainQueue()
    driver.controller.finish(first, finished: true) // Replay the old callback while the second slide owns UIKit.
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 3)
    #expect(driver.controller.viewControllers?.first === secondHost)
    #expect(!driver.controller.view.isUserInteractionEnabled)
    #expect(driver.state.settled.last != 3)

    driver.controller.finish(second, finished: true)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 4)
    let latest = try #require(driver.controller.presentations.last)
    #expect(latest.target === latestHost)
    driver.controller.finish(latest, finished: true)
    await drainPagerMainQueue()
    #expect(driver.state.settled.last == 3)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerDismantleInvalidatesCallbacksAndRestoresInteraction() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    driver.request(1)
    await drainPagerMainQueue()
    let pending = try #require(driver.controller.presentations.last)
    #expect(pending.animated)
    #expect(!driver.controller.view.isUserInteractionEnabled)
    driver.request(2)
    await drainPagerMainQueue()
    let settledBeforeDismantle = driver.state.settled

    driver.detach()
    #expect(driver.controller.view.isUserInteractionEnabled)
    #expect(driver.controller.delegate == nil)
    #expect(driver.controller.dataSource == nil)
    driver.controller.finish(pending, finished: true)
    driver.request(3)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 2)
    #expect(driver.state.settled == settledBeforeDismantle)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerReusesCachedHostsWhenReturningToATab() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let firstHost = try driver.cachedHost(at: 0)
    let secondHost = try driver.cachedHost(at: 1)

    for (selection, expectedHost) in [(1, secondHost), (0, firstHost), (1, secondHost)] {
        driver.request(selection)
        await drainPagerMainQueue()
        let presentation = try #require(driver.controller.presentations.last)
        #expect(presentation.animated)
        #expect(presentation.target === expectedHost)
        driver.controller.finish(presentation, finished: true)
        await drainPagerMainQueue()
    }
    #expect(driver.controller.presentations.count == 4)
    #expect(driver.state.settled.last == 1)
    #expect(driver.controller.viewControllers?.first === secondHost)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerCompletedSwipeUpdatesBindingAndSettles() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let originalHost = try driver.cachedHost(at: 0)
    let swipedHost = try driver.cachedHost(at: 1)

    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, willTransitionTo: [swipedHost])
    }
    driver.controller.report([swipedHost])
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, didFinishAnimating: true,
                                             previousViewControllers: [originalHost], transitionCompleted: true)
    }
    await drainPagerMainQueue()

    #expect(driver.state.selection == 1)
    #expect(driver.state.settled.last == 1)
    #expect(driver.controller.viewControllers?.first === swipedHost)
    #expect(driver.controller.presentations.count == 1)
    #expect(driver.controller.presentations.allSatisfy { !$0.startedInsideDelegateCallback })
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerTabSelectionDuringSwipeWinsOverGestureResult() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let originalHost = try driver.cachedHost(at: 0)
    let swipedHost = try driver.cachedHost(at: 1)
    let requestedHost = try driver.cachedHost(at: 3)
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, willTransitionTo: [swipedHost])
    }
    driver.request(3)
    await drainPagerMainQueue()
    #expect(driver.controller.presentations.count == 1)

    driver.controller.report([swipedHost])
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, didFinishAnimating: true,
                                             previousViewControllers: [originalHost], transitionCompleted: true)
    }
    #expect(driver.state.selection == 3)
    #expect(driver.controller.presentations.allSatisfy { !$0.startedInsideDelegateCallback })
    await drainPagerMainQueue()

    #expect(driver.controller.presentations.count == 2)
    let requested = try #require(driver.controller.presentations.last)
    #expect(requested.animated)
    #expect(requested.target === requestedHost)
    #expect(!requested.startedInsideDelegateCallback)
    driver.controller.finish(requested, finished: true)
    await drainPagerMainQueue()
    #expect(driver.state.selection == 3)
    #expect(driver.state.settled.last == 3)
    #expect(driver.controller.viewControllers?.first === requestedHost)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@Test @MainActor func paneTabPagerCancelledSwipeReturnsToRequestedCachedHostOutsideDelegate() async throws {
    let driver = PaneTabPagerDriver()
    defer { driver.close() }
    driver.request(0)
    await drainPagerMainQueue()
    let originalHost = try driver.cachedHost(at: 0)
    let pendingHost = try driver.cachedHost(at: 1)
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, willTransitionTo: [pendingHost])
    }
    driver.controller.report([originalHost])
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, didFinishAnimating: true,
                                             previousViewControllers: [originalHost], transitionCompleted: false)
    }
    await drainPagerMainQueue()
    #expect(driver.state.selection == 0)
    #expect(driver.controller.viewControllers?.first === originalHost)
    #expect(driver.controller.presentations.count == 1)

    // An interrupted cancellation can leave the pending neighbor reported by UIKit.
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, willTransitionTo: [pendingHost])
    }
    driver.controller.report([pendingHost])
    driver.controller.withDelegateCallback {
        driver.coordinator.pageViewController(driver.controller, didFinishAnimating: false,
                                             previousViewControllers: [originalHost], transitionCompleted: false)
    }
    #expect(driver.controller.presentations.allSatisfy { !$0.startedInsideDelegateCallback })
    await drainPagerMainQueue()

    #expect(driver.controller.presentations.count == 2)
    let restored = try #require(driver.controller.presentations.last)
    #expect(!restored.animated)
    #expect(!restored.startedInsideDelegateCallback)
    #expect(restored.target === originalHost)
    #expect(driver.controller.viewControllers?.first === originalHost)
    #expect(driver.state.selection == 0)
    #expect(driver.state.settled.last == 0)
    #expect(driver.controller.view.isUserInteractionEnabled)
}

@MainActor private final class PaneTabPagerState {
    var selection = 0
    var settled: [Int] = []
}

@MainActor private final class PaneTabPagerDriver {
    typealias Pager = PaneTabPager<Int, Text>
    let state: PaneTabPagerState
    let controller: ControlledPanePageViewController
    let coordinator: Pager.Coordinator
    private let window: UIWindow
    private var detached = false

    init(completesNonanimatedImmediately: Bool = true) {
        let state = PaneTabPagerState()
        self.state = state
        let pager = Self.pager(state)
        coordinator = pager.makeCoordinator()
        controller = ControlledPanePageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        controller.completesNonanimatedImmediately = completesNonanimatedImmediately
        controller.dataSource = coordinator
        controller.delegate = coordinator
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        controller.loadViewIfNeeded()
        window.layoutIfNeeded()
    }

    private static func pager(_ state: PaneTabPagerState) -> Pager {
        Pager(selection: Binding(get: { state.selection }, set: { state.selection = $0 }),
              tabs: [0, 1, 2, 3], content: { Text("Page \($0)") },
              onSelectionSettled: { state.settled.append($0) })
    }

    func request(_ selection: Int) {
        state.selection = selection
        coordinator.update(controller, parent: Self.pager(state))
    }

    func cachedHost(at index: Int) throws -> UIViewController {
        var host = try #require(controller.presentations.first?.target)
        for _ in 0..<index {
            host = try #require(coordinator.pageViewController(controller, viewControllerAfter: host))
        }
        return host
    }

    func detach() {
        guard !detached else { return }
        detached = true
        Pager.dismantleUIViewController(controller, coordinator: coordinator)
    }

    func close() {
        detach()
        window.isHidden = true
        window.rootViewController = nil
    }
}

@MainActor private final class ControlledPanePageViewController: UIPageViewController {
    struct Presentation {
        let target: UIViewController?
        let animated: Bool
        let startedInsideCompletion: Bool
        let startedInsideDelegateCallback: Bool
        let completion: ((Bool) -> Void)?
    }

    var completesNonanimatedImmediately = true
    private(set) var presentations: [Presentation] = []
    private var reportedControllers: [UIViewController]?
    private var completionDepth = 0
    private var delegateCallbackDepth = 0

    override var viewControllers: [UIViewController]? { reportedControllers }

    override func setViewControllers(_ viewControllers: [UIViewController]?, direction: NavigationDirection,
                                     animated: Bool, completion: ((Bool) -> Void)? = nil) {
        reportedControllers = viewControllers
        let presentation = Presentation(target: viewControllers?.first, animated: animated,
                                        startedInsideCompletion: completionDepth > 0,
                                        startedInsideDelegateCallback: delegateCallbackDepth > 0, completion: completion)
        presentations.append(presentation)
        if !animated && completesNonanimatedImmediately { finish(presentation, finished: true) }
    }

    func report(_ controllers: [UIViewController]) { reportedControllers = controllers }

    func withDelegateCallback(_ callback: () -> Void) {
        delegateCallbackDepth += 1
        defer { delegateCallbackDepth -= 1 }
        callback()
    }

    func finish(_ presentation: Presentation, finished: Bool) {
        completionDepth += 1
        defer { completionDepth -= 1 }
        presentation.completion?(finished)
    }
}

@MainActor private func drainPagerMainQueue() async {
    // FIFO barriers drain the coordinator's deferred presentation and settlement work.
    for _ in 0..<3 {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
#endif
