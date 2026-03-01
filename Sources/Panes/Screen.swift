import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - Public API (back-compat helpers)
@MainActor
@Observable
public final class ScreenMetrics {
    public static let shared = ScreenMetrics()

    private init() {}

    // Published state
    public private(set) var insets: UIEdgeInsets = .zero
    public private(set) var size: CGSize = .zero
    public private(set) var orientation: UIInterfaceOrientation = .unknown

    // Internals
    private weak var window: UIWindow?

    // Attach once we can resolve the actual key window from SwiftUI
    public func attach(window: UIWindow) {
        if self.window == nil { self.window = window }
        // Always refresh metrics on resolve (rotation/splitview/layout changes)
        updateFromWindow()
    }

    // Update values from the current window/scene in a single pass
    @objc private func updateFromWindow() {
        guard let window = window, let scene = window.windowScene else { return }
        self.insets = window.safeAreaInsets
        self.size = window.bounds.size
        self.orientation = scene.interfaceOrientation
    }
}

// MARK: - SwiftUI glue to resolve the window and keep metrics fresh

/// Embed once at the root of your app/view tree to keep `ScreenMetrics.shared` up-to-date.
public struct ScreenMetricsInjector: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(WindowResolver { window in
                Task { @MainActor in
                    ScreenMetrics.shared.attach(window: window)
                }
            })
    }
}

public extension View {
    /// Call `.injectScreenMetrics()` near the app root (e.g., inside your root `NavigationStack`).
    func injectScreenMetrics() -> some View { modifier(ScreenMetricsInjector()) }
}

// Finds the current UIWindow from SwiftUI and notifies on layout/inset changes
@available(iOS 17.0, *)
private struct WindowResolver: UIViewRepresentable {
    let onResolve: (UIWindow) -> Void

    func makeUIView(context: Context) -> ResolverView { ResolverView(onResolve: onResolve) }
    func updateUIView(_ uiView: ResolverView, context: Context) {}

    @available(iOS 17.0, *)
    final class ResolverView: UIView {
        let onResolve: (UIWindow) -> Void
        private var traitRegistrations: [UITraitChangeRegistration] = []
        private var orientationObserver: NSObjectProtocol?

        init(onResolve: @escaping (UIWindow) -> Void) {
            self.onResolve = onResolve
            super.init(frame: .zero)
            isHidden = true
            isUserInteractionEnabled = false
        }
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let w = window { onResolve(w) }

            if let token = orientationObserver {
                NotificationCenter.default.removeObserver(token)
                orientationObserver = nil
            }
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self, let w = self.window else { return }
                self.onResolve(w)
            }

            traitRegistrations.removeAll()

            let reg = registerForTraitChanges([
                UITraitUserInterfaceStyle.self,
                UITraitDisplayScale.self,
                UITraitHorizontalSizeClass.self,
                UITraitVerticalSizeClass.self,
                UITraitPreferredContentSizeCategory.self,
                UITraitDisplayGamut.self
            ]) { (view: ResolverView, _) in
                if let w = view.window { view.onResolve(w) }
            }
            traitRegistrations.append(reg)
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            if newWindow == nil, let token = orientationObserver {
                NotificationCenter.default.removeObserver(token)
                orientationObserver = nil
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let w = window { onResolve(w) }
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            if let w = window { onResolve(w) }
        }
    }
}

// MARK: - Back-compat global helpers
@MainActor @inline(__always) public func orientation() -> UIInterfaceOrientation { ScreenMetrics.shared.orientation }
@MainActor @inline(__always) public func isPortrait() -> Bool { ScreenMetrics.shared.orientation.isPortrait }
@MainActor @inline(__always) public func isLandscape() -> Bool { ScreenMetrics.shared.orientation.isLandscape }
@MainActor @inline(__always) public func isLandscapeLeft() -> Bool { ScreenMetrics.shared.orientation == .landscapeLeft }
@MainActor @inline(__always) public func isLandscapeRight() -> Bool { ScreenMetrics.shared.orientation == .landscapeRight }
@MainActor @inline(__always) public func screenSize() -> CGSize { ScreenMetrics.shared.size }
@MainActor @inline(__always) public func screenWidth() -> CGFloat { ScreenMetrics.shared.size.width }
@MainActor @inline(__always) public func screenHeight() -> CGFloat { ScreenMetrics.shared.size.height }
@MainActor @inline(__always) public func insets() -> UIEdgeInsets { ScreenMetrics.shared.insets }
@MainActor @inline(__always) public func topInset() -> CGFloat { ScreenMetrics.shared.insets.top }
@MainActor @inline(__always) public func bottomInset() -> CGFloat { ScreenMetrics.shared.insets.bottom }
@MainActor @inline(__always) public func leftInset() -> CGFloat { ScreenMetrics.shared.insets.left }
@MainActor @inline(__always) public func rightInset() -> CGFloat { ScreenMetrics.shared.insets.right }
#endif
