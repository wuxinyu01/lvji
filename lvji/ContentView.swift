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
            GlobalView()
                .tabItem {
                    Label("全球", systemImage: "globe")
                }
                .tag(0)
            
            CountryMapView()
                .tabItem {
                    Label("地图", systemImage: "map")
                }
                .tag(1)
            
            FriendsListView()
                .tabItem {
                    Label("社交", systemImage: "person.2")
                }
                .tag(2)
            
            UserProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
    }
}

struct GlobalView: View {
    var body: some View {
        ZStack {
            MetalEarthView()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer().frame(height: 40)
                
                Text("旅迹")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                    )
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
