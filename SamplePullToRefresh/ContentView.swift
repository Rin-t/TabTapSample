//
//  ContentView.swift
//  SamplePullToRefresh
//
//  Created by Rin on 2024/04/06.
//

import SwiftUI

struct Trigger: Equatable {
    private var key = false

    mutating func fire() {
        key.toggle()
    }
}

struct ContentView: View {

    enum Tab {
        case home
        case setting
    }

    @State private var selectedTab: Tab = .home
    @State private var tappedSameTabTrigger: Trigger = .init()

    var body: some View {

        let interceptor = Binding<Tab>(
            get: { selectedTab },
            set: {
                if selectedTab == $0, selectedTab == .home {
                    tappedSameTabTrigger.fire()
                }
                selectedTab = $0
            }
        )

        TabView(selection: interceptor){
            FirstView(tappedSameTabTrigger: $tappedSameTabTrigger)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(Tab.home)

            SecondView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(Tab.setting)
        }
    }
}

struct FirstView: View {

    @State private var items: [String] = []
    @Binding var tappedSameTabTrigger: Trigger
    @State var isTop = true
    @State var isLoading = false
    var previousOffset: CGFloat = 0

    var body: some View {

        NavigationStack {
            ScrollViewReader { scrollProxy in
                VStack {
                    if isLoading {
                        withAnimation {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                        }
                    }
                    ScrollView() {
                        LazyVStack {
                            EmptyView()
                                .id("top")
                            ForEach(items, id: \.self) { item in
                                Text(item)
                                    .padding(.vertical, 80)
                                    .frame(width: 240)
                                    .border(.gray)
                            }
                        }
                        .background(GeometryReader {
                            Color.clear.preference(
                                key: OffsetPreferenceKey.self,
                                value: $0.frame(in: .global).minY
                            )
                        })
                    }
                    .refreshable {
                        loadData()
                    }
                    .onChange(of: tappedSameTabTrigger) { newValue in
                        if isTop {
                            print("top")
                            isLoading = true
                            loadData()
                        } else {
                            withAnimation {
                                scrollProxy.scrollTo("top", anchor: .bottom)
                            }
                        }
                    }
                    .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                        isTop = offset >= 20
                        print(offset)
                        print(isTop)
                    }
                }
            }
        }
        .onAppear {
            print("onAppear")
            setupList()
        }

    }

    func setupList() {
        items = [
            "item 1",
            "item 2",
            "item 3",
            "item 4",
            "item 5",
            "item 6",
            "item 7"
        ]
    }

    func loadData() {
        Task {
            items.insert("new item \(items.count + 1)", at: 0)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        }
    }
}

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct SecondView: View {
    var body: some View {
        Text("second View")
    }
}

#Preview {
    ContentView()
}
