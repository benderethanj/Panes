import SwiftUI
import Combine

public struct SmartScroll<Content: View>: View {
    public let content: (SmartScrollProxy) -> Content
    @StateObject private var proxy = SmartScrollProxy()
    private let offsetBinding: Binding<CGFloat>?

    public init(_ offset: Binding<CGFloat>? = nil,
         @ViewBuilder content: @escaping (SmartScrollProxy) -> Content) {
        self.content = content
        self.offsetBinding = offset
    }
    
    public var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                ZStack(alignment: .top) {
                    VStack {
                        Color.clear
                            .frame(height: 0)
                            .frame($proxy.detector, in: .named("scroll"))
                        
                        content(proxy)
                    }
                    .frame($proxy.contents)
                    VStack {
                        Spacer()
                            .frame(maxHeight: proxy.offset)
                        Color.clear
                            .frame(height: 0)
                            .id("offset")
                    }
                    VStack {
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                        Spacer()
                        Color.clear
                            .frame(height: 0)
                            .id("bottom")
                    }
                }
            }
            .scrollClipDisabled()
            .frame($proxy.frame)
            .onAppear {
                proxy.scroll = scroll
                offsetBinding?.wrappedValue = proxy.position(reference: .top)
            }
        }
        .coordinateSpace(name: "scroll")
        .onChange(of: proxy.detector) {
            offsetBinding?.wrappedValue = proxy.position(reference: .top)
        }
        .onChange(of: proxy.frame) {
            offsetBinding?.wrappedValue = proxy.position(reference: .top)
        }
        .onChange(of: proxy.contents) {
            offsetBinding?.wrappedValue = proxy.position(reference: .top)
        }
    }
}

#Preview {
    SmartScroll { proxy in
        Button {
            proxy.bottom()
        } label: {
            Text("Jump")
        }
        
        ForEach(0..<50, id: \.self) { index in
            Button {
                withAnimation {
                    proxy.scroll(on: index, anchor: .top)
                }
            } label: {
                Text("\(index): \(-proxy.detector.origin.y)")
            }
            .id(index)
            .foregroundStyle(.primary)
        }
    }
}

public enum SmartScrollReference {
    case top, bottom
}

public final class SmartScrollProxy: ObservableObject {
    public var reference: SmartScrollReference = .bottom
    
    @Published public var frame: CGRect = .zero
    @Published public var contents: CGRect = .zero
    @Published public var detector: CGRect = .zero
    @Published public var offset: CGFloat = .zero
    
    public var scroll: ScrollViewProxy?

    public init() {}
    
    public func scroll(to offset: CGFloat, anchor: UnitPoint = .bottom, reference: SmartScrollReference = .bottom) {
        if let scroll {
            self.offset = reference == .top ? offset : contents.height - offset
            scroll.scrollTo("offset", anchor: anchor)
        }
    }
    
    public func scroll(on id: any Hashable, anchor: UnitPoint = .top) {
        if let scroll {
            scroll.scrollTo(id, anchor: anchor)
        }
    }
    
    public func position(reference: SmartScrollReference) -> CGFloat {
        return reference == .top ? -self.detector.origin.y: contents.height + self.detector.origin.y - self.frame.height
    }
    
    public func bottom() {
        scroll(on: "bottom", anchor: .bottom)
    }
    
    public func top() {
        scroll(on: "top", anchor: .top)
    }
}
