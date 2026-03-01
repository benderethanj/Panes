import SwiftUI

public struct SizeReader<Content: View>: View {
    @Binding var size: CGSize
    let content: () -> Content
    
    init(_ size: Binding<CGSize>, @ViewBuilder content: @escaping () -> Content) {
        _size = size
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                )
        }
        .onPreferenceChange(SizePreferenceKey.self) { preferences in
            DispatchQueue.main.async {
                self.size = preferences
            }
        }
    }
}

public struct FrameReader<Content: View>: View {
    @Binding var frame: CGRect
    let space: CoordinateSpaceProtocol
    let content: () -> Content
    
    init(_ frame: Binding<CGRect>, in space: CoordinateSpaceProtocol = .global, @ViewBuilder content: @escaping () -> Content) {
        _frame = frame
        self.space = space
        self.content = content
    }
    
    @State private var lastFrameUpdate: TimeInterval = 0
    
    public var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: FramePreferenceKey.self, value: proxy.frame(in: space))
                    }
                )
        }
        .onPreferenceChange(FramePreferenceKey.self) { preferences in
            DispatchQueue.main.async {
                let currentTime = Date().timeIntervalSince1970
                
                if currentTime - lastFrameUpdate > 0.1 {
                    lastFrameUpdate = currentTime
                    self.frame = preferences
                }
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static let defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct ShowModifier: ViewModifier {
    let show: Bool

    func body(content: Content) -> some View {
        if show {
            content
        } else {
            EmptyView()
        }
    }
}

public extension View {
    func show(_ bool: Bool) -> some View {
        modifier(ShowModifier(show: bool))
    }
}

struct SizeReaderModifier: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        SizeReader($size) {
            content
        }
    }
}

public extension View {
    func size(_ size: Binding<CGSize>) -> some View {
        modifier(SizeReaderModifier(size: size))
    }
}



struct FramePreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static let defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct FrameReaderModifier: ViewModifier {
    @Binding var frame: CGRect
    var space: CoordinateSpaceProtocol = .global

    func body(content: Content) -> some View {
        FrameReader($frame, in: space) {
            content
        }
    }
}

public extension View {
    func frame(_ frame: Binding<CGRect>, in space: CoordinateSpaceProtocol = .global) -> some View {
        modifier(FrameReaderModifier(frame: frame, space: space))
    }
}
