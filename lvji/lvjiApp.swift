//
//  lvjiApp.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import CoreLocation

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
        
        // Setup locationManager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
