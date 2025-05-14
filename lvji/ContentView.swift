//
//  ContentView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI

// 导入所需视图文件 - 注意：通常在良好组织的项目中，这些视图会自动在整个模块中可见，无需显式导入
// 这里假设视图文件可能不在同一模块或有可见性问题

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 使用可选视图，当相应的视图不可用时显示占位符
            #if DEBUG
            ContentViewHelper.getCountryMapView()
                .tabItem {
                    Label("旅迹", systemImage: "map")
                }
                .tag(0)
            
            ContentViewHelper.getFriendsListView()
                .tabItem {
                    Label("奔赴", systemImage: "person.2")
                }
                .tag(1)
            
            ContentViewHelper.getUserProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(2)
            #else
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
            #endif
        }
    }
}

// 定义一个辅助类，提供视图获取方法
#if DEBUG
enum ContentViewHelper {
    // 提供占位符视图，避免类型重复声明
    static func getCountryMapView() -> some View {
        do {
            // 尝试使用已定义的CountryMapView
            let _ = CountryMapView.self
            return AnyView(CountryMapView())
        } catch {
            // 如果不存在，返回占位符
            return AnyView(CountryMapViewPlaceholder())
        }
    }
    
    static func getFriendsListView() -> some View {
        do {
            let _ = FriendsListView.self
            return AnyView(FriendsListView())
        } catch {
            return AnyView(FriendsListViewPlaceholder())
        }
    }
    
    static func getUserProfileView() -> some View {
        do {
            let _ = UserProfileView.self
            return AnyView(UserProfileView())
        } catch {
            return AnyView(UserProfileViewPlaceholder())
        }
    }
}

// 占位符视图定义
struct CountryMapViewPlaceholder: View {
    var body: some View {
        Text("旅迹视图未找到")
    }
}

struct FriendsListViewPlaceholder: View {
    var body: some View {
        Text("奔赴视图未找到")
    }
}

struct UserProfileViewPlaceholder: View {
    var body: some View {
        Text("我的视图未找到")
    }
}
#endif

#Preview {
    ContentView()
}
