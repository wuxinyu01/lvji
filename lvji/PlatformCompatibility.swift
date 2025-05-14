//
//  PlatformCompatibility.swift
//  lvji
//
//  Created on 2025/5/10.
//

import SwiftUI

// MARK: - 跨平台兼容性定义
// 这个文件用来解决iOS和macOS API之间的差异

// 定义每个平台上的ToolbarItemPlacement位置
extension ToolbarItemPlacement {
    #if os(iOS)
    static var compatibleTrailing: ToolbarItemPlacement { .navigationBarTrailing }
    static var compatibleLeading: ToolbarItemPlacement { .navigationBarLeading }
    #else
    static var compatibleTrailing: ToolbarItemPlacement { .automatic }
    static var compatibleLeading: ToolbarItemPlacement { .automatic }
    #endif
}

// 为不同平台定义标题显示模式
#if os(iOS)
enum CompatibleTitleDisplayMode {
    case inline
    case large
    case automatic
    
    var navigationValue: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .inline:
            return .inline
        case .large:
            return .large
        case .automatic:
            return .automatic
        }
    }
}
#else
enum CompatibleTitleDisplayMode {
    case inline
    case large
    case automatic
}
#endif

// 创建一个通用的视图修饰符，处理不同平台的API
extension View {
    @ViewBuilder
    func compatibleNavigationBarTitleDisplayMode(_ mode: CompatibleTitleDisplayMode) -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(mode.navigationValue)
        #else
        self // macOS无需此修饰符
        #endif
    }
    
    // 添加兼容的searchable修饰符
    @ViewBuilder
    func compatibleSearchable(text: Binding<String>, prompt: String) -> some View {
        #if os(iOS)
        self.searchable(text: text, prompt: prompt)
        #else
        self // macOS可能需要不同的搜索实现
        #endif
    }
    
    // 添加兼容的ignoresSafeArea修饰符
    @ViewBuilder
    func compatibleIgnoresSafeArea() -> some View {
        #if os(iOS)
        self.ignoresSafeArea()
        #else
        self // macOS无此概念
        #endif
    }
} 