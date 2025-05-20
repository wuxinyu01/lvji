//
//  MapStyleUtility.swift
//  lvji
//
//  Created on 2025/5/14.
//

import SwiftUI
import MapKit
// 使用来自 ColorExtensions.swift 的集中管理的颜色定义
// Note: Swift 会自动将项目中所有的 .swift 文件包含在一起，所以不需要显式导入

/// 地图样式工具类
/// 用于在应用程序中维护一致的地图样式设置
struct MapStyleUtility {
    
    /// 应用苹果地图风格到地图样式设置
    /// - Returns: 标准的地图样式
    static func appleMapStyle() -> MapStyle {
        // 使用标准样式，不尝试访问不存在的 Standard 成员
        return .standard
    }
    
    /// 确保使用浅色UI模式，避免地图在深色模式下出现红色背景
    static func enforceLightMode() {
        #if os(iOS)
        // 使用现代API设置浅色模式，避免使用已废弃的方法
        if let windowScenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> {
            for windowScene in windowScenes {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .light
                }
            }
        }
        #endif
    }
    
    /// 获取安全的缩放级别
    /// - Returns: 安全的地图跨度
    static func getSafeSpan() -> MKCoordinateSpan {
        // 返回一个更灵活的安全缩放级别，允许更大范围的地图显示
        return MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    }
    
    /// 获取最大的缩放级别（最小的缩放比例）
    /// - Returns: 最大允许的地图跨度
    static func getMaxSpan() -> MKCoordinateSpan {
        // 返回一个更大的最大缩放级别，允许查看更广阔的区域
        return MKCoordinateSpan(latitudeDelta: 180.0, longitudeDelta: 180.0)
    }
    
    /// 获取适合地图初始显示的默认区域
    /// - Returns: 默认区域
    static func getDefaultRegion() -> MKCoordinateRegion {
        // 中国中心位置，适当降低缩放级别以显示更大区域
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.0, longitude: 105.0),
            span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 30.0)
        )
    }
    
    /// 处理地图资源加载失败的问题
    /// - Parameter mapView: 需要修复的地图视图
    static func fixResourceLoadingIssue(for mapView: MKMapView) {
        #if os(iOS)
        // 1. 重置地图类型
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration()
            config.elevationStyle = .flat
            config.pointOfInterestFilter = .includingAll
            config.showsTraffic = false
            mapView.preferredConfiguration = config
        }
        
        // 2. 清除所有覆盖层并设置代理
        mapView.removeOverlays(mapView.overlays)
        mapView.delegate = MapViewCustomDelegate.shared
        
        // 3. 调整地图区域到更安全的缩放级别，确保能够正确加载瓦片资源
        let safeRegion = MKCoordinateRegion(
            center: mapView.region.center,
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
        mapView.setRegion(safeRegion, animated: true)
        
        // 4. 添加瓦片覆盖层来处理瓦片加载错误
        let tileOverlay = CustomTileOverlay()
        mapView.addOverlay(tileOverlay, level: .aboveRoads)
        #endif
    }
    
    /// 为地图创建区域，使用安全的缩放级别
    /// - Parameter center: 中心坐标
    /// - Returns: 带有安全缩放级别的坐标区域
    static func createSafeRegion(center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        // 使用更大的跨度确保地图可以完全显示
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
    }
    
    /// 确保地图区域在允许的缩放范围内
    /// - Parameter region: 原始地图区域
    /// - Returns: 调整后的地图区域
    static func ensureRegionWithinLimits(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let minSpan = getSafeSpan() // 最小跨度（最大缩放）
        let maxSpan = getMaxSpan() // 最大跨度（最小缩放）
        
        // 调整经纬度缩放，允许更灵活的地图区域显示
        let latDelta = min(max(region.span.latitudeDelta, minSpan.latitudeDelta * 0.8), maxSpan.latitudeDelta)
        let longDelta = min(max(region.span.longitudeDelta, minSpan.longitudeDelta * 0.8), maxSpan.longitudeDelta)
        
        // 确保坐标在有效范围内
        let latitude = min(max(region.center.latitude, -85.0), 85.0)
        let longitude = min(max(region.center.longitude, -179.5), 179.5)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        )
    }
    
    /// 根据当前区域计算MapKit缩放级别
    /// - Parameter region: 地图显示区域
    /// - Returns: 缩放级别（越小表示越放大）
    static func calculateZoomLevel(for region: MKCoordinateRegion) -> Double {
        return region.span.latitudeDelta
    }
    
    /// 检查是否处于高缩放级别（可能出现红色背景的区域）
    /// - Parameter region: 地图区域
    /// - Returns: 是否在高缩放级别
    static func isHighZoomLevel(_ region: MKCoordinateRegion) -> Bool {
        return region.span.latitudeDelta < 0.01 // 调整高缩放判定阈值
    }
    
    /// 检查是否处于极高缩放级别（肯定会出现红色背景的区域）
    /// - Parameter region: 地图区域
    /// - Returns: 是否在极高缩放级别
    static func isExtremeZoomLevel(_ region: MKCoordinateRegion) -> Bool {
        return region.span.latitudeDelta < 0.005 // 调整极端缩放判定阈值
    }
    
    /// 检查是否处于最低缩放级别（最远视图）
    /// - Parameter region: 地图区域
    /// - Returns: 是否在最低缩放级别
    static func isMinZoomLevel(_ region: MKCoordinateRegion) -> Bool {
        return region.span.latitudeDelta >= 90.0 // 允许更远的缩放视图
    }
    
    #if os(iOS)
    /// 适用于UIKit的MKMapView的样式设置
    /// - Parameter mapView: 要应用样式的地图视图
    static func applyCustomStyle(to mapView: MKMapView) {
        // 设置基本属性
        mapView.showsBuildings = true
        mapView.showsTraffic = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        
        // 只有在极端缩放级别时才限制地图区域
        let region = mapView.region
        if region.span.latitudeDelta < 0.005 {
            let safeRegion = MKCoordinateRegion(
                center: region.center, 
                span: getSafeSpan()
            )
            mapView.setRegion(safeRegion, animated: false)
        }
        
        // 设置导航线颜色
        mapView.tintColor = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
        
        // 对于iOS 16及以上版本使用现代API
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration()
            config.elevationStyle = .flat
            config.showsTraffic = false
            config.pointOfInterestFilter = .includingAll
            mapView.preferredConfiguration = config
        }
    }
    #endif
    
    /// 应用所有地图样式修饰符到视图
    /// - Parameter content: 要修饰的地图视图
    /// - Returns: 带有一致样式修饰符的视图
    static func applyMapStyleModifiers<Content: View>(_ content: Content) -> some View {
        return content
            .mapStyle(appleMapStyle())
            .preferredColorScheme(.light) // 确保使用浅色模式
            // 使用通用颜色而非特定导航颜色
            .tint(Color.mapPrimaryColor)
            .onAppear {
                // 在视图出现时强制使用浅色模式
                enforceLightMode()
                
                #if os(iOS)
                // 额外设置全局地图控件，确保颜色正确
                if #available(iOS 16.0, *) {
                    // 设置导航路线颜色
                    let navigationColor = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
                    UIView.appearance(whenContainedInInstancesOf: [MKMapView.self]).tintColor = navigationColor
                    
                    // 强制地图元素使用正确的颜色
                    if let proxy = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        proxy.windows.forEach { window in
                            window.subviews.forEach { view in
                                if let mapView = findMapView(in: view) {
                                    applyCustomStyle(to: mapView)
                                }
                            }
                        }
                    }
                }
                #endif
            }
    }
    
    #if os(iOS)
    /// 在视图层次结构中查找MKMapView
    /// - Parameter view: 父视图
    /// - Returns: 找到的第一个MKMapView或nil
    private static func findMapView(in view: UIView) -> MKMapView? {
        if let mapView = view as? MKMapView {
            return mapView
        }
        
        for subview in view.subviews {
            if let mapView = findMapView(in: subview) {
                return mapView
            }
        }
        
        return nil
    }
    #endif
}

// 扩展SwiftUI视图，添加便捷的地图样式方法
extension View {
    /// 应用一致的地图样式修饰符
    func withAppleMapsStyling() -> some View {
        return MapStyleUtility.applyMapStyleModifiers(self)
    }
} 