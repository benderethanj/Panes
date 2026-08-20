#if canImport(UIKit)
import SwiftUI
import UIKit

struct PaneWindowMetrics: Equatable {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let interfaceOrientation: UIInterfaceOrientation
}

@MainActor
struct PaneWindowMetricsReader: UIViewRepresentable {
    let onChange: (PaneWindowMetrics) -> Void

    func makeUIView(context: Context) -> PaneWindowMetricsView {
        PaneWindowMetricsView(onChange: onChange)
    }

    func updateUIView(_ uiView: PaneWindowMetricsView, context: Context) {
        uiView.onChange = onChange
    }
}

@MainActor
final class PaneWindowMetricsView: UIView {
    var onChange: (PaneWindowMetrics) -> Void
    private var lastMetrics: PaneWindowMetrics?
    private var pendingMetrics: PaneWindowMetrics?

    init(onChange: @escaping (PaneWindowMetrics) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        publishMetrics()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        publishMetrics()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        publishMetrics()
    }

    private func publishMetrics() {
        guard let window, let scene = window.windowScene else { return }
        let metrics = PaneWindowMetrics(
            bounds: window.bounds,
            safeAreaInsets: window.safeAreaInsets,
            interfaceOrientation: scene.interfaceOrientation
        )
        guard metrics != lastMetrics, metrics != pendingMetrics else { return }
        pendingMetrics = metrics

        Task { @MainActor [weak self] in
            guard let self, pendingMetrics == metrics else { return }
            pendingMetrics = nil
            guard lastMetrics != metrics else { return }
            lastMetrics = metrics
            onChange(metrics)
        }
    }
}
#endif
