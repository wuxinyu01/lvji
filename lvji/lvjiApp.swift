//
//  lvjiApp.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import CoreLocation
import MapKit

@main
struct lvjiApp: App {
    // Location manager to request permissions early
    private let locationManager = CLLocationManager()
    
    init() {
        // 隐私权限描述（添加到Info.plist中的内容）
        // NSLocationWhenInUseUsageDescription - 旅迹需要访问您的位置以在地图上显示您的当前位置并记录照片位置
        // NSLocationAlwaysAndWhenInUseUsageDescription - 旅迹需要访问您的位置以在地图上显示您的当前位置、记录照片位置，并与好友分享您的位置
        // NSCameraUsageDescription - 旅迹需要访问您的相机以拍摄并分享照片
        // NSPhotoLibraryUsageDescription - 旅迹需要访问您的照片库以选择并分享照片
        
        // 配置全局的网络错误处理策略
        configureURLErrorHandling()
        
        // Setup locationManager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // 确保地图使用浅色模式，避免红色背景问题
        setupMapAppearance()
    }
    
    // 配置全局网络错误处理
    private func configureURLErrorHandling() {
        #if os(iOS)
        // 配置全局URLSession级别的重试和缓存策略
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        URLSession.shared.configuration.urlCache?.memoryCapacity = 10 * 1024 * 1024 // 10MB内存缓存
        URLSession.shared.configuration.urlCache?.diskCapacity = 50 * 1024 * 1024 // 50MB磁盘缓存
        #endif
    }
    
    // 全局设置地图外观
    private func setupMapAppearance() {
        #if os(iOS)
        // 强制使用浅色模式以避免地图显示问题
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
        // 设置地图全局样式
        if #available(iOS 16.0, *) {
            // 设置导航路线颜色
            let navigationColor = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
            UIView.appearance(whenContainedInInstancesOf: [MKMapView.self]).tintColor = navigationColor
            
            // 设置全局MKMapView默认配置
            // 使用标准地图避免卫星资源加载错误
            let config = MKStandardMapConfiguration()
            config.elevationStyle = .flat // 平面样式避免3D渲染问题
            config.showsTraffic = false // 禁用交通，减少资源加载
            MKMapView.appearance().preferredConfiguration = config
        }
        
        // 限制地图最小缩放级别，防止TiledGEOResourceFetcher错误
        MKMapView.appearance().cameraZoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 5000, // 限制最大缩放(最小距离)
            maxCenterCoordinateDistance: 10000000 // 限制最小缩放(最大距离)
        )
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if os(iOS)
                    // 延迟一小段时间应用样式，确保视图已加载
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        setupMapAppearance()
                        
                        // 清除可能的缓存问题
                        URLCache.shared.removeAllCachedResponses()
                    }
                    #endif
                }
        }
    }
}
