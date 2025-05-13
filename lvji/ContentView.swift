//
//  ContentView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CountryMapView()
                .tabItem {
                    Label("旅迹", systemImage: "map")
                }
                .tag(0)
            
            FriendsListView()
                .tabItem {
                    Label("奔赴", systemImage: "person.2")
                }
                .tag(1)
            
            UserProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
