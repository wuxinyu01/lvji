//
//  ColorExtensions.swift
//  lvji
//
//  Created on 2025/5/15.
//

import SwiftUI

// 集中管理应用中的颜色扩展
public extension Color {
    // 主要应用颜色
    static let primaryApp = Color(red: 0.0, green: 0.4, blue: 0.8) // 主蓝色
    static let secondaryApp = Color(red: 0.2, green: 0.6, blue: 0.9) // 次要蓝色
    static let accentApp = Color(red: 0.0, green: 0.6, blue: 0.4) // 强调色
    
    // 地图基础颜色 - 标准地图风格 - 按照要求精确定义颜色
    static let mapBackground = Color(red: 0.97, green: 0.97, blue: 0.95) // 浅灰白色背景
    
    // 道路颜色 - 精确匹配要求
    static let mapMainRoad = Color(red: 0.1, green: 0.1, blue: 0.1) // 黑色主要道路
    static let mapSecondaryRoad = Color(red: 0.55, green: 0.55, blue: 0.55) // 灰色次要道路
    static let mapMinorRoad = Color(red: 0.65, green: 0.55, blue: 0.45) // 棕色小路
    
    // 建筑颜色
    static let mapBuilding = Color(red: 0.9, green: 0.9, blue: 0.9) // 浅灰色建筑
    static let mapImportantBuilding = Color(red: 0.96, green: 0.96, blue: 0.96) // 白色重要建筑
    
    // 自然地形颜色
    static let mapWater = Color(red: 0.6, green: 0.75, blue: 0.95) // 蓝色水域
    static let mapDeepWater = Color(red: 0.4, green: 0.6, blue: 0.9) // 深蓝色深水区
    
    // 植被颜色
    static let mapVegetation = Color(red: 0.7, green: 0.85, blue: 0.65) // 绿色植被
    static let mapDenseVegetation = Color(red: 0.5, green: 0.75, blue: 0.45) // 深绿色密集植被
    static let mapPark = Color(red: 0.75, green: 0.88, blue: 0.7) // 浅绿色公园
    
    // 地标和特殊区域
    static let mapLandmark = Color(red: 0.2, green: 0.5, blue: 0.9) // 蓝色地标
    static let mapTerrain = Color(red: 0.8, green: 0.75, blue: 0.65) // 棕色地形
    
    // 渐变色
    static let primaryGradientStart = Color(red: 0.1, green: 0.5, blue: 0.9)
    static let primaryGradientEnd = Color(red: 0.0, green: 0.3, blue: 0.7)
    static let secondaryGradientStart = Color(red: 0.3, green: 0.7, blue: 0.9)
    static let secondaryGradientEnd = Color(red: 0.2, green: 0.5, blue: 0.8)
    
    // 导航路线颜色
    static let navigationRouteColor = Color(red: 0.0, green: 0.3, blue: 0.7) // 深蓝色导航路线
    
    // 应用主色调
    static let mapPrimaryColor = Color(red: 0.0, green: 0.3, blue: 0.7) // 用于地图相关颜色
} 