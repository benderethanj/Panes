import SwiftUI
import Combine

struct SmartScroll<Content: View>: View {
    let content: (SmartScrollProxy) -> Content
    @StateObject private var proxy = SmartScrollProxy()
    private let offsetBinding: Binding<CGFloat>?

    init(_ offset: Binding<CGFloat>? = nil,
         @ViewBuilder content: @escaping (SmartScrollProxy) -> Content) {
        self.content = content
        self.offsetBinding = offset
    }
    
    var body: some View {
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

enum SmartScrollReference {
    case top, bottom
}

class SmartScrollProxy: ObservableObject {
    var reference: SmartScrollReference = .bottom
    
    @Published var frame: CGRect = .zero
    @Published var contents: CGRect = .zero
    @Published var detector: CGRect = .zero
    @Published var offset: CGFloat = .zero
    
    var scroll: ScrollViewProxy?
    
    func scroll(to offset: CGFloat, anchor: UnitPoint = .bottom, reference: SmartScrollReference = .bottom) {
        if let scroll {
            self.offset = reference == .top ? offset : contents.height - offset
            scroll.scrollTo("offset", anchor: anchor)
        }
    }
    
    func scroll(on id: any Hashable, anchor: UnitPoint = .top) {
        if let scroll {
            scroll.scrollTo(id, anchor: anchor)
        }
    }
    
    func position(reference: SmartScrollReference) -> CGFloat {
        return reference == .top ? -self.detector.origin.y: contents.height + self.detector.origin.y - self.frame.height
    }
    
    func bottom() {
        scroll(on: "bottom", anchor: .bottom)
    }
    
    func top() {
        scroll(on: "top", anchor: .top)
    }
}
