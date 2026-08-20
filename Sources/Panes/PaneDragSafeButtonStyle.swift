import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// A button style whose action is recognized only after a stationary touch ends
/// inside the control. Once the finger moves beyond `movementTolerance`, the
/// interaction permanently becomes a drag and can never trigger the button.
public struct PaneDragSafeButtonStyle: PrimitiveButtonStyle {
    public var movementTolerance: CGFloat

    public init(movementTolerance: CGFloat = 4) {
        self.movementTolerance = movementTolerance
    }

    public func makeBody(configuration: Configuration) -> some View {
        PaneDragSafeButtonBody(
            action: { configuration.trigger() },
            movementTolerance: max(0, movementTolerance)
        ) {
            configuration.label
        }
    }
}

private struct PaneDragSafeButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    let action: () -> Void
    let movementTolerance: CGFloat
    let label: () -> Label

    var body: some View {
        label()
            .contentShape(Rectangle())
            .overlay {
                #if canImport(UIKit)
                PaneUIKitResolvedTapOverlay(
                    isEnabled: isEnabled,
                    movementTolerance: movementTolerance,
                    action: action
                )
                #else
                PaneResolvedTapFallback(
                    isEnabled: isEnabled,
                    movementTolerance: movementTolerance,
                    action: action
                )
                #endif
            }
    }
}

#if canImport(UIKit)
private struct PaneUIKitResolvedTapOverlay: UIViewRepresentable {
    let isEnabled: Bool
    let movementTolerance: CGFloat
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isAccessibilityElement = false

        let recognizer = ResolvedTapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.recognizedTap(_:))
        )
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        view.addGestureRecognizer(recognizer)
        context.coordinator.recognizer = recognizer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
        context.coordinator.recognizer?.movementTolerance = max(0, movementTolerance)
        context.coordinator.recognizer?.isEnabled = isEnabled
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        weak var recognizer: ResolvedTapGestureRecognizer?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @MainActor @objc func recognizedTap(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            action()
        }

    }

    final class ResolvedTapGestureRecognizer: UIGestureRecognizer {
        var movementTolerance: CGFloat = 4
        private var initialWindowLocation: CGPoint?
        private var maximumTravel: CGFloat = 0

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            guard touches.count == 1, let touch = touches.first else {
                state = .failed
                return
            }
            initialWindowLocation = touch.location(in: view?.window)
            maximumTravel = 0
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            guard state == .possible,
                  let touch = touches.first,
                  let initialWindowLocation else { return }
            let location = touch.location(in: view?.window)
            maximumTravel = max(
                maximumTravel,
                hypot(
                    location.x - initialWindowLocation.x,
                    location.y - initialWindowLocation.y
                )
            )
            if maximumTravel >= movementTolerance {
                state = .failed
            }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            guard state == .possible,
                  let touch = touches.first,
                  let view,
                  let initialWindowLocation else { return }
            let finalWindowLocation = touch.location(in: view.window)
            maximumTravel = max(
                maximumTravel,
                hypot(
                    finalWindowLocation.x - initialWindowLocation.x,
                    finalWindowLocation.y - initialWindowLocation.y
                )
            )
            let finalLocalLocation = touch.location(in: view)
            guard maximumTravel < movementTolerance,
                  view.bounds.contains(finalLocalLocation) else {
                state = .failed
                return
            }
            state = .ended
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            state = .cancelled
        }

        override func reset() {
            initialWindowLocation = nil
            maximumTravel = 0
            super.reset()
        }
    }
}
#else
private struct PaneResolvedTapFallback: View {
    let isEnabled: Bool
    let movementTolerance: CGFloat
    let action: () -> Void

    @State private var maximumTravel: CGFloat = 0

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        maximumTravel = max(
                            maximumTravel,
                            hypot(value.translation.width, value.translation.height)
                        )
                    }
                    .onEnded { value in
                        let travel = max(
                            maximumTravel,
                            hypot(value.translation.width, value.translation.height)
                        )
                        maximumTravel = 0
                        guard isEnabled, travel < movementTolerance else { return }
                        action()
                    }
            )
    }
}
#endif
