//
//  CountryMapView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif
import CoreLocation
// 导入集中管理的颜色定义
// Note: Swift 会自动将项目中所有的 .swift 文件包含在一起，所以不需要显式导入

#if os(iOS)
// 自定义地图覆盖层 - 在文件作用域内
class ColorOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var zoomLevel: Double // 存储创建时的缩放级别，用于调整渲染
    
    init(region: MKCoordinateRegion) {
        self.coordinate = region.center
        self.zoomLevel = region.span.latitudeDelta
        
        // 确保坐标在有效范围内
        let lat = min(max(region.center.latitude, -85.0), 85.0) // 避免贴近极点的无效请求
        let lon = min(max(region.center.longitude, -179.0), 179.0)
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        // 创建一个足够大但不过大的覆盖区域
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: min(max(region.center.latitude + region.span.latitudeDelta/2, -85.0), 85.0),
            longitude: min(max(region.center.longitude - region.span.longitudeDelta/2, -179.0), 179.0)))
        
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: min(max(region.center.latitude - region.span.latitudeDelta/2, -85.0), 85.0),
            longitude: min(max(region.center.longitude + region.span.longitudeDelta/2, -179.0), 179.0)))
        
        self.boundingMapRect = MKMapRect(
            x: topLeft.x,
            y: topLeft.y,
            width: max(1, bottomRight.x - topLeft.x), // 确保宽度至少为1
            height: max(1, bottomRight.y - topLeft.y)) // 确保高度至少为1
        
        super.init()
    }
}

// 自定义瓦片覆盖层 - 用于覆盖地图瓦片，处理资源加载失败情况
class CustomTileOverlay: MKTileOverlay {
    private let errorHandlingEnabled: Bool
    
    // 初始化时启用错误处理
    init(errorHandlingEnabled: Bool = true) {
        self.errorHandlingEnabled = errorHandlingEnabled
        super.init(urlTemplate: nil) // 使用nil而不是空字符串
        
        // 配置瓦片加载参数
        self.canReplaceMapContent = false
        self.tileSize = CGSize(width: 256, height: 256)
        self.minimumZ = 0
        self.maximumZ = 20
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // 返回一个有效的空白瓦片URL
        return URL(string: "https://example.com/empty_tile")!
    }
    
    // 加载瓦片数据，处理可能的错误
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // 创建一个空白半透明瓦片，防止红色背景和资源加载错误
        let tileData = createEmptyTile()
        result(tileData, nil)
    }
    
    // 创建空白半透明瓦片
    private func createEmptyTile() -> Data? {
        #if os(iOS)
        let size = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        // 创建一个完全透明的瓦片
        if let context = UIGraphicsGetCurrentContext() {
            // 使用白色作为基色但几乎完全透明
            context.setFillColor(UIColor.white.withAlphaComponent(0.01).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                return image.pngData()
            }
        }
        #endif
        return nil
    }
}

// 单例委托处理地图渲染 - 在文件作用域内
class MapViewCustomDelegate: NSObject, MKMapViewDelegate {
    static let shared = MapViewCustomDelegate()
    
    // 跟踪瓦片加载错误
    private var resourceLoadingErrors = 0
    private var lastErrorTime = Date()
    
    // 地图着色配置 - 符合要求的颜色方案
    private struct MapColors {
        // 道路颜色
        static let mainRoad = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // 黑色主要道路
        static let secondaryRoad = UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0) // 灰色次要道路
        static let minorRoad = UIColor(red: 0.65, green: 0.55, blue: 0.45, alpha: 1.0) // 棕色小路
        
        // 建筑颜色
        static let building = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) // 浅灰色建筑
        static let importantBuilding = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 白色重要建筑
        static let landmarkBuilding = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.8) // 蓝色地标建筑
        
        // 自然地形颜色
        static let water = UIColor(red: 0.6, green: 0.75, blue: 0.95, alpha: 1.0) // 蓝色水域
        static let vegetation = UIColor(red: 0.7, green: 0.85, blue: 0.65, alpha: 1.0) // 绿色植被
        static let denseVegetation = UIColor(red: 0.5, green: 0.75, blue: 0.45, alpha: 1.0) // 深绿色密集植被
        static let terrain = UIColor(red: 0.8, green: 0.75, blue: 0.65, alpha: 1.0) // 棕色地形
        
        // 背景颜色
        static let background = UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0) // 浅灰白色背景
    }
    
    // 处理地图加载错误消息
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        // 记录错误
        resourceLoadingErrors += 1
        lastErrorTime = Date()
        
        print("地图加载错误: \(error.localizedDescription)")
        
        // 如果10秒内发生超过2次错误，立即应用安全修复
        if resourceLoadingErrors > 2 && Date().timeIntervalSince(lastErrorTime) < 10.0 {
            // 重置错误计数
            resourceLoadingErrors = 0
            
            // 立即应用安全修复
            DispatchQueue.main.async {
                // 强制切换到标准地图类型
                if #available(iOS 16.0, *) {
                    let config = MKStandardMapConfiguration()
                    config.elevationStyle = .flat
                    config.pointOfInterestFilter = .includingAll
                    config.showsTraffic = false
                    mapView.preferredConfiguration = config
                }
                
                // 设置更安全的缩放级别
                let safeRegion = MKCoordinateRegion(
                    center: mapView.region.center,
                    span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                )
                mapView.setRegion(safeRegion, animated: true)
                
                // 添加覆盖层以防止红色背景
                let tileOverlay = CustomTileOverlay()
                mapView.addOverlay(tileOverlay, level: .aboveRoads)
            }
        }
    }
    
    // 地图加载完成时重置错误计数
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // 如果地图加载成功，重置错误计数
        resourceLoadingErrors = 0
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is ColorOverlay {
            // 创建一个带有自定义颜色的覆盖渲染器，修复红色背景问题
            let renderer = MKOverlayRenderer(overlay: overlay)
            
            // 使用非常低的不透明度，仅轻微影响地图颜色
            renderer.alpha = 0.05
            
            return renderer
        } else if overlay is MKTileOverlay {
            // 为瓦片覆盖层创建渲染器
            let renderer = MKTileOverlayRenderer(overlay: overlay)
            
            // 瓦片覆盖层用于修复错误，确保它几乎不可见
            renderer.alpha = 0.01
            
            return renderer
        } else if overlay is MKPolyline {
            // 为道路等线条创建渲染器
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            // 根据线条类型设置颜色
            if let polyline = overlay as? MKPolyline {
                // 识别道路类型并应用适当的颜色
                let roadType = getRoadTypeForPolyline(polyline)
                switch roadType {
                case .main:
                    renderer.strokeColor = MapColors.mainRoad // 黑色主要道路
                    renderer.lineWidth = 3.0
                case .secondary:
                    renderer.strokeColor = MapColors.secondaryRoad // 灰色次要道路
                    renderer.lineWidth = 2.0
                case .minor:
                    renderer.strokeColor = MapColors.minorRoad // 棕色小路
                    renderer.lineWidth = 1.5
                }
            } else {
                // 默认道路颜色
                renderer.strokeColor = MapColors.secondaryRoad
                renderer.lineWidth = 2.0
            }
            
            return renderer
        } else if overlay is MKPolygon {
            // 为建筑物、水域等多边形创建渲染器
            let renderer = MKPolygonRenderer(overlay: overlay)
            
            // 尝试识别多边形类型并应用适当的颜色
            if let polygon = overlay as? MKPolygon {
                let polygonType = getPolygonType(polygon, in: mapView)
                switch polygonType {
                case .building:
                    renderer.fillColor = MapColors.building
                    renderer.strokeColor = MapColors.building.withAlphaComponent(0.8)
                    renderer.lineWidth = 0.5
                case .water:
                    renderer.fillColor = MapColors.water
                    renderer.strokeColor = MapColors.water
                    renderer.lineWidth = 0.5
                case .vegetation:
                    renderer.fillColor = MapColors.vegetation
                    renderer.strokeColor = MapColors.vegetation
                    renderer.lineWidth = 0.5
                case .terrain:
                    renderer.fillColor = MapColors.terrain
                    renderer.strokeColor = MapColors.terrain
                    renderer.lineWidth = 0.5
                }
            } else {
                // 默认多边形颜色
                renderer.fillColor = UIColor.lightGray.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.lightGray.withAlphaComponent(0.5)
                renderer.lineWidth = 0.5
            }
            
            return renderer
        } else if overlay is MKCircle {
            // 为圆形覆盖层创建渲染器
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.blue.withAlphaComponent(0.3)
            renderer.lineWidth = 1.0
            
            return renderer
        }
        
        // 默认渲染器
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // 根据折线特性识别道路类型
    private enum RoadType {
        case main, secondary, minor
    }
    
    private func getRoadTypeForPolyline(_ polyline: MKPolyline) -> RoadType {
        // 在真实应用中，可以通过道路属性来确定类型
        // 这里使用简单的启发式方法
        let pointCount = polyline.pointCount
        if pointCount > 20 {
            return .main
        } else if pointCount > 10 {
            return .secondary
        } else {
            return .minor
        }
    }
    
    // 多边形类型枚举
    private enum PolygonType {
        case building, water, vegetation, terrain
    }
    
    // 尝试识别多边形类型
    private func getPolygonType(_ polygon: MKPolygon, in mapView: MKMapView) -> PolygonType {
        // 在实际应用中，可以基于位置、形状等特征来判断
        // 这里使用简化的面积和位置启发式方法
        
        // 计算多边形面积
        let area = getMKPolygonArea(polygon)
        
        // 获取多边形中心点
        let centerMapPoint = getCenterOfPolygon(polygon)
        // 使用现代API转换坐标
        let centerCoordinate = centerMapPoint.coordinate
        
        // 使用位置特征进行判断
        // 比如靠近水域的大面积多边形可能是水域
        // 城市区域中的小面积多边形可能是建筑物
        
        // 这里使用简单的随机分配进行演示
        // 在实际应用中，应该使用真实的地理信息进行判断
        let random = Int(centerCoordinate.latitude * 100 + centerCoordinate.longitude * 100) % 4
        
        if area > 10000 {
            // 大面积多边形
            if random == 0 {
                return .water
            } else {
                return .vegetation
            }
        } else {
            // 小面积多边形
            if random == 0 {
                return .terrain
            } else {
                return .building
            }
        }
    }
    
    // 计算多边形面积的辅助函数
    private func getMKPolygonArea(_ polygon: MKPolygon) -> Double {
        // 由于无法直接访问点数据，我们使用多边形的边界矩形面积作为近似
        let boundingMapRect = polygon.boundingMapRect
        return boundingMapRect.size.width * boundingMapRect.size.height
    }
    
    // 获取多边形中心点的辅助函数
    private func getCenterOfPolygon(_ polygon: MKPolygon) -> MKMapPoint {
        // 使用多边形的边界矩形中心作为近似
        let boundingMapRect = polygon.boundingMapRect
        return MKMapPoint(
            x: boundingMapRect.midX,
            y: boundingMapRect.midY
        )
    }
    
    // 当地图区域变化时应用颜色修复
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // 检查缩放级别
        let zoomLevel = mapView.region.span.latitudeDelta
        
        // 移除所有现有颜色覆盖层，保留其他覆盖层
        let overlaysToRemove = mapView.overlays.filter { $0 is ColorOverlay }
        mapView.removeOverlays(overlaysToRemove)
        
        // 只在需要的缩放级别添加颜色覆盖层
        if zoomLevel < 0.5 {
            // 添加自定义颜色覆盖以确保颜色正确
            let overlay = ColorOverlay(region: mapView.region)
            mapView.addOverlay(overlay, level: .aboveRoads)
            
            // 如果缩放级别较高，确保地图不会变成红色
            if zoomLevel < 0.1 {
                // 创建适当的缩放级别，避免红色背景
                let safeRegion = MKCoordinateRegion(
                    center: mapView.region.center,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
                
                // 如果之前没有设置瓦片覆盖层，添加一个
                let hasTileOverlay = mapView.overlays.contains { $0 is MKTileOverlay }
                if !hasTileOverlay {
                    let tileOverlay = CustomTileOverlay()
                    mapView.addOverlay(tileOverlay, level: .aboveLabels)
                }
                
                // 避免循环，只有在用户操作时设置区域
                if !animated {
                    mapView.setRegion(safeRegion, animated: true)
                }
            }
        }
    }
}

// 在文件作用域内扩展坐标类型
extension CLLocationCoordinate2D {
    func regionWithRadius(_ radius: CLLocationDistance) -> MKCoordinateRegion {
        // 计算以指定半径的区域
        let distanceInDegrees = radius / 111000.0 // 粗略的度到米换算
        let region = MKCoordinateRegion(
            center: self,
            span: MKCoordinateSpan(
                latitudeDelta: distanceInDegrees,
                longitudeDelta: distanceInDegrees
            )
        )
        return region
    }
}
#endif

struct CountryMapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var mapSelection: PhotoAnnotation?
    @State private var viewingPhotos = false
    @State private var showPhotoCapture = false
    @State private var showLocationPhotoAlbum = false
    @State private var mapStyle: MapStyle = .standard
    @State private var zoomLevel: Double = 0.05 // 用于跟踪缩放级别
    @State private var isZooming = false // 用于跟踪缩放动画
    @State private var lastZoomUpdate = Date()
    @State private var mapStyleVersion: Int = 0 // 用于跟踪样式更新
    @State private var resourceLoadingErrors = 0 // 用于跟踪资源加载错误
    
    // 添加搜索相关状态
    @State private var searchResults: [MKMapItem] = []
    @State private var searchIsActive = false
    @State private var selectedSearchResult: MKMapItem?
    
    // Sample photo annotations (in a real app, these would come from Firestore)
    @State private var photoAnnotations: [PhotoAnnotation] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                mapView
                
                // 搜索结果列表
                if searchIsActive && !searchResults.isEmpty {
                    searchResultsView
                }
                
                // 地图控制UI层
                controlsOverlay
            }
            .navigationTitle("旅迹")
            .compatibleSearchable(text: $searchText, prompt: "搜索地点")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty && newValue.count >= 2 {
                    searchPlaces(with: newValue)
                    searchIsActive = true
                } else {
                    searchResults = []
                    searchIsActive = false
                }
            }
            .sheet(isPresented: $showPhotoCapture) {
                InlinePhotoCaptureView()
            }
            .sheet(isPresented: $showLocationPhotoAlbum) {
                InlineLocationPhotoAlbumView()
            }
        }
        .onAppear {
            // 设置初始摄像机位置
            setInitialCameraPosition()
            
            // Request location authorization when the view appears
            requestLocationPermission()
            
            // Load sample photo annotations
            loadSamplePhotoAnnotations()
        }
    }
    
    // 设置初始摄像机位置
    private func setInitialCameraPosition() {
        // 使用更大的区域显示整个中国，确保地图完全加载
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.0, longitude: 105.0),
            span: MKCoordinateSpan(latitudeDelta: 40.0, longitudeDelta: 40.0)
        )
        cameraPosition = .region(defaultRegion)
        zoomLevel = defaultRegion.span.latitudeDelta
        
        // 确保初始化地图样式
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.initializeMapStyles()
        }
    }
    
    // MARK: - 地图视图
    private var mapView: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            // 显示照片标记
            ForEach(photoAnnotations) { annotation in
                Annotation(coordinate: annotation.coordinate) {
                    ZStack {
                        // 背景光晕效果，只在较高缩放级别显示
                        if zoomLevel < 0.3 {
                            Circle()
                                .fill(Color.primaryApp.opacity(0.2))
                                .frame(width: calculateMarkerSize(for: annotation) * 1.5, 
                                       height: calculateMarkerSize(for: annotation) * 1.5)
                                .blur(radius: 3)
                        }
                        
                        // 主要标记
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.primaryGradientStart, .primaryGradientEnd]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: calculateMarkerSize(for: annotation), 
                                   height: calculateMarkerSize(for: annotation))
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        
                        // 图标
                        Image(systemName: "photo.fill")
                            .font(.system(size: calculateIconSize(for: annotation)))
                            .foregroundColor(.white)
                    }
                } label: {
                    // 根据缩放级别调整标签可见性和样式
                    if zoomLevel < 0.15 {
                        Text("照片")
                            .font(.caption2)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            )
                    }
                }
                .tag(annotation)
            }
            
            // 显示搜索结果标记
            ForEach(searchResults, id: \.self) { item in
                Annotation(coordinate: item.placemark.coordinate) {
                    ZStack {
                        // 搜索结果标记，使用蓝色系
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.6, blue: 0.9), // 调整为更淡的蓝色
                                        Color(red: 0.2, green: 0.4, blue: 0.8)  // 调整为更接近Apple Maps的蓝色
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "mappin")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                } label: {
                    Text(item.name ?? "位置")
                        .font(.caption)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                }
            }
            
            // 如果有选中的搜索结果，使用不同的标记样式
            if let selectedItem = selectedSearchResult {
                Annotation(coordinate: selectedItem.placemark.coordinate) {
                    ZStack {
                        // 外围脉动光环效果
                        Circle()
                            .fill(Color.accentApp.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        // 中间光环
                        Circle()
                            .fill(Color.accentApp.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        // 主要背景
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 0.7, blue: 0.5),
                                        Color(red: 0.0, green: 0.5, blue: 0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.accentApp)
                        
                        Text(selectedItem.name ?? "已选择位置")
                            .font(.caption)
                            .bold()
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    )
                }
            }
        }
        .mapStyle(mapStyle)
        .mapControls {
            // 添加地图控制元素以实现更好的交互
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            // 移除MapPitchToggle以避免3D模式引起额外的资源加载问题
        }
        // 使用地图控件替代交互模式设置
        .edgesIgnoringSafeArea(.all)
        // 监听位置变化更新缩放级别
        .onChange(of: cameraPosition) { _, newPosition in
            // 监测地图位置变化，确保颜色保持正确
            // 防止节流，避免过多的更新调用
            let now = Date()
            if now.timeIntervalSince(lastZoomUpdate) > 0.5 {
                lastZoomUpdate = now
                
                // 检查是否在缩放过程中（避免动画期间重复设置）
                if !isZooming {
                    // 检查当前region并更新zoomLevel
                    if let region = cameraPosition.region {
                        // 更新zoomLevel
                        zoomLevel = region.span.latitudeDelta
                        
                        // 只有在过度缩放时才应用限制
                        if region.span.latitudeDelta < 0.3 {
                            // 在主线程延迟应用样式修复
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.fixMapZoomColorIssue()
                            }
                        }
                    }
                }
            }
        }
        // 确保应用正确的地图样式，防止深色模式问题
        .onAppear {
            // 先设置更大的区域显示整个中国
            setInitialCameraPosition()
            
            // 确保初始化地图样式
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.initializeMapStyles()
            }
        }
        // 处理错误情况
        .onDisappear {
            // 清理资源
            resourceLoadingErrors = 0
        }
    }
    
    // 计算背景覆盖不透明度
    private func getBackgroundOpacity() -> Double {
        if zoomLevel < 0.15 {
            // 最高缩放级别 - 需要较高不透明度来覆盖红色背景
            return 0.35
        } else if zoomLevel < 0.3 {
            // 高缩放级别 - 中等不透明度
            return 0.2
        } else if zoomLevel < 0.5 {
            // 中等缩放级别 - 低不透明度
            return 0.1
        } else {
            // 低缩放级别 - 不需要覆盖
            return 0
        }
    }
    
    // 道路网格覆盖视图 - 用于高缩放级别
    private struct RoadGridOverlay: View {
        var body: some View {
            ZStack {
                // 主要道路 - 黑色
                RoadGrid(lineWidth: 2.0, spacing: 80, color: Color.mapMainRoad.opacity(0.5))
                
                // 次要道路 - 灰色
                RoadGrid(lineWidth: 1.0, spacing: 40, color: Color.mapSecondaryRoad.opacity(0.3))
                
                // 小路 - 棕色
                RoadGrid(lineWidth: 0.5, spacing: 20, rotation: 45, color: Color.mapMinorRoad.opacity(0.2))
            }
        }
    }
    
    // 单一道路网格
    private struct RoadGrid: View {
        let lineWidth: CGFloat
        let spacing: CGFloat
        var rotation: Double = 0
        let color: Color
        
        var body: some View {
            ZStack {
                // 水平线
                VStack(spacing: spacing) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(height: lineWidth)
                    }
                }
                
                // 垂直线
                HStack(spacing: spacing) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: lineWidth)
                    }
                }
            }
            .rotationEffect(.degrees(rotation))
        }
    }
    
    // MARK: - 搜索结果视图
    private var searchResultsView: some View {
        VStack {
            VStack(spacing: 0) {
                // 搜索结果标题
                HStack {
                    Text("搜索结果")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(searchResults.count)个地点")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        searchIsActive = false
                        searchResults = []
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                )
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2))
                
                // 搜索结果列表
                List {
                    ForEach(searchResults, id: \.self) { item in
                        Button(action: {
                            selectSearchResult(item)
                        }) {
                            HStack(spacing: 12) {
                                // 位置图标
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.secondaryGradientStart, .secondaryGradientEnd]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    Image(systemName: "mappin")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                // 位置信息
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name ?? "未知位置")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(formatAddress(for: item.placemark))
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // 选择箭头
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        )
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(Color.white.opacity(0.95))
            .cornerRadius(10)
            .frame(height: min(CGFloat(searchResults.count * 60) + 60, 360))
            .padding(.horizontal)
            .padding(.top, 10)
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            
            Spacer()
        }
        .transition(.move(edge: .top))
    }
    
    // MARK: - 控制界面
    private var controlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    // 地图类型选择器
                    mapTypeMenu
                    
                    // 地图缩放控制
                    zoomControls
                }
                .padding(.top, 60)
                .padding(.trailing, 16)
            }
            
            Spacer()
            
            // 底部按钮组
            bottomControls
        }
    }
    
    // 地图类型菜单
    private var mapTypeMenu: some View {
        Menu {
            Button(action: {
                mapStyle = .standard
                // 强制确保在地图类型改变后保持正确的颜色
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    initializeMapStyles()
                }
            }) {
                Label("标准", systemImage: "map")
            }
            
            Button(action: {
                mapStyle = .hybrid
                // 强制确保在地图类型改变后保持正确的颜色
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    initializeMapStyles()
                }
            }) {
                Label("混合", systemImage: "map.fill")
            }
            
            Button(action: {
                mapStyle = .imagery
                // 强制确保在地图类型改变后保持正确的颜色
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    initializeMapStyles()
                }
            }) {
                Label("卫星", systemImage: "globe")
            }
        } label: {
            ZStack {
                // 主背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                // 边框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "map")
                    .font(.system(size: 18))
                    .foregroundColor(Color.primaryApp)
            }
        }
    }
    
    // 缩放控制按钮
    private var zoomControls: some View {
        VStack(spacing: 4) {
            Button(action: {
                zoomIn()
            }) {
                ZStack {
                    // 主背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    
                    // 边框
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(Color.primaryApp)
                }
            }
            
            Button(action: {
                zoomOut()
            }) {
                ZStack {
                    // 主背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    
                    // 边框
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "minus")
                        .font(.system(size: 18))
                        .foregroundColor(Color.primaryApp)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.05))
                .blur(radius: 0.5)
        )
    }
    
    // 底部控制按钮
    private var bottomControls: some View {
        HStack {
            // 照片专辑按钮
            Button(action: {
                showLocationPhotoAlbum = true
            }) {
                ZStack {
                    // 背景光晕
                    Circle()
                        .fill(Color.primaryApp.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    // 按钮背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.primaryApp)
                }
            }
            .padding(.leading, 30)
            
            Spacer()
            
            // 相机按钮
            Button(action: {
                showPhotoCapture = true
            }) {
                ZStack {
                    // 外部光晕
                    Circle()
                        .fill(Color.primaryApp.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    // 中间光晕
                    Circle()
                        .fill(Color.primaryApp.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    // 按钮背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    
                    // 边框增强视觉层次
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.primaryApp)
                }
            }
            
            Spacer()
            
            // 定位按钮
            Button(action: {
                centerOnUserLocation()
            }) {
                ZStack {
                    // 背景光晕
                    Circle()
                        .fill(Color.primaryApp.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    // 按钮背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.primaryApp)
                }
            }
            .padding(.trailing, 30)
        }
        .padding(.bottom, 30)
    }
    
    // 计算标记大小（根据缩放级别）
    private func calculateMarkerSize(for annotation: PhotoAnnotation) -> CGFloat {
        // 在不同缩放级别下调整标记大小，使用更平滑的变化
        if zoomLevel > 0.7 {  // 很远
            return 22
        } else if zoomLevel > 0.5 {  // 较远
            return 26
        } else if zoomLevel > 0.3 { // 中等
            return 32
        } else if zoomLevel > 0.15 { // 较近
            return 36
        } else { // 很近
            return 42
        }
    }
    
    // 计算图标大小（根据缩放级别）
    private func calculateIconSize(for annotation: PhotoAnnotation) -> CGFloat {
        // 与标记大小保持一定比例
        return calculateMarkerSize(for: annotation) * 0.45
    }
    
    // 放大地图
    private func zoomIn() {
        if let region = getCurrentRegion() {
            // 设置更灵活的最小缩放限制，允许更接近查看
            let newLatDelta = max(region.span.latitudeDelta * 0.5, 0.1) // 调整最小限制值为0.1，允许更灵活的缩放
            let newLongDelta = max(region.span.longitudeDelta * 0.5, 0.1)
            
            // 设置缩放标志
            isZooming = true
            
            // 先更新缩放级别
            self.zoomLevel = newLatDelta
            
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLongDelta)
                ))
            }
            
            // 延迟重置缩放标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                isZooming = false
                // 确保只在需要时应用样式修复
                if newLatDelta < 0.01 {
                    initializeMapStyles()
                }
            }
        }
    }
    
    // 缩小地图
    private func zoomOut() {
        if let region = getCurrentRegion() {
            // 使用MapStyleUtility获取最大允许的跨度
            let maxSpan = MapStyleUtility.getMaxSpan()
            
            // 计算新的跨度，使用更大的缩放因子，但不超过最大允许值
            let newLatDelta = min(region.span.latitudeDelta * 2.5, maxSpan.latitudeDelta)
            let newLongDelta = min(region.span.longitudeDelta * 2.5, maxSpan.longitudeDelta)
            
            // 设置缩放标志
            isZooming = true
            
            // 先更新缩放级别
            self.zoomLevel = newLatDelta
            
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLongDelta)
                ))
            }
            
            // 延迟重置缩放标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                isZooming = false
            }
        }
    }
    
    // 获取当前地图区域
    private func getCurrentRegion() -> MKCoordinateRegion? {
        if let region = cameraPosition.region {
            // 使用MapStyleUtility确保区域在允许的缩放范围内
            return MapStyleUtility.ensureRegionWithinLimits(region)
        } else {
            // 如果不能直接获取region，返回一个默认区域
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // 北京
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    // Request permission to use location services
    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Center the map on the user's current location
    private func centerOnUserLocation() {
        // 设置缩放标志
        isZooming = true
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
        }
        
        // 延迟重置缩放标志
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isZooming = false
            
            // 如果可以获取当前区域，更新缩放级别
            if let region = getCurrentRegion() {
                // 在主线程更新zoomLevel
                DispatchQueue.main.async {
                    self.zoomLevel = region.span.latitudeDelta
                }
            }
        }
    }
    
    // 实现地址搜索功能
    private func searchPlaces(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("搜索错误: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                self.searchResults = []
                return
            }
            
            self.searchResults = response.mapItems
        }
    }
    
    // 格式化地址
    private func formatAddress(for placemark: MKPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ]
        
        return components.compactMap { $0 }.joined(separator: ", ")
    }
    
    // 初始化地图样式并设置全局样式
    private func initializeMapStyles() {
        #if os(iOS)
        // 使用工具类确保浅色模式
        MapStyleUtility.enforceLightMode()
        
        // 通过系统 API 设置导航路线颜色
        let navigationColor = UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0) // 深蓝色导航颜色
        
        // 确保使用标准地图样式
        mapStyle = .standard
        
        // 获取当前区域，确保地图显示正确
        if let region = getCurrentRegion() {
            // 如果缩放级别过小，调整到更合适的缩放级别
            if region.span.latitudeDelta < 0.2 {
                let safeRegion = MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                )
                
                // 先更新zoomLevel状态变量
                self.zoomLevel = safeRegion.span.latitudeDelta
                
                // 然后更新相机位置
                cameraPosition = .region(safeRegion)
            }
        }
        
        // 设置地图视图的全局样式
        if #available(iOS 16.0, *) {
            // 为 MKMapView 实例设置全局的外观样式
            UIView.appearance(whenContainedInInstancesOf: [MKMapView.self]).tintColor = navigationColor
            
            // 查找并应用样式到所有已存在的地图视图
            applyStylesToExistingMapViews()
        }
        #endif
    }
    
    #if os(iOS)
    // 查找并应用样式到所有存在的地图视图
    private func applyStylesToExistingMapViews() {
        if let windowScenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> {
            for windowScene in windowScenes {
                for window in windowScene.windows {
                    findAndApplyStyleToMapViews(in: window)
                }
            }
        }
    }
    
    // 在视图层次结构中查找并应用样式
    private func findAndApplyStyleToMapViews(in view: UIView) {
        // 如果当前视图是地图视图，应用样式
        if let mapView = view as? MKMapView {
            applyFullMapStyling(to: mapView)
        }
        
        // 递归遍历所有子视图
        for subview in view.subviews {
            findAndApplyStyleToMapViews(in: subview)
        }
    }
    
    // 对单个地图视图应用完整样式
    private func applyFullMapStyling(to mapView: MKMapView) {
        // 应用代理
        if mapView.delegate == nil || !(mapView.delegate is MapViewCustomDelegate) {
            mapView.delegate = MapViewCustomDelegate.shared
        }
        
        // 应用基本样式
        MapStyleUtility.applyCustomStyle(to: mapView)
        
        // 仅在极端缩放级别时应用特殊处理
        if MapStyleUtility.isExtremeZoomLevel(mapView.region) {
            // 移除现有覆盖层
            let overlaysToRemove = mapView.overlays
            mapView.removeOverlays(overlaysToRemove)
            
            // 添加自定义颜色覆盖
            let overlay = ColorOverlay(region: mapView.region)
            mapView.addOverlay(overlay, level: .aboveRoads)
            
            // 添加瓦片覆盖
            // 创建自定义瓦片覆盖层
            let tileOverlay = CustomTileOverlay()
            mapView.addOverlay(tileOverlay, level: .aboveLabels)
        }
    }
    
    // 查找并应用全面的地图样式修复
    private func findAndApplyMapStyling() {
        let allWindows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        
        for window in allWindows {
            findAndApplyStyleToMapViews(in: window)
        }
    }
    #endif
    
    // 添加专门修复地图缩放红色背景问题的方法
    private func fixMapZoomColorIssue() {
        #if os(iOS)
        // 查找并应用特殊样式到当前地图视图
        if let windowScenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> {
            for windowScene in windowScenes {
                for window in windowScene.windows {
                    findAndFixMapRedBackgroundIssue(in: window)
                }
            }
        }
        #endif
    }
    
    #if os(iOS)
    // 查找并修复地图红色背景问题
    private func findAndFixMapRedBackgroundIssue(in view: UIView) {
        // 如果当前视图是地图视图，应用修复
        if let mapView = view as? MKMapView {
            // 完全移除所有现有覆盖层
            mapView.removeOverlays(mapView.overlays)
            
            // 设置合适的缩放级别避免红色背景
            if mapView.region.span.latitudeDelta < 0.2 {
                let safeRegion = MKCoordinateRegion(
                    center: mapView.region.center,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                )
                mapView.setRegion(safeRegion, animated: true)
            }
            
            // 添加空白瓦片覆盖层
            let tileOverlay = CustomTileOverlay()
            mapView.addOverlay(tileOverlay, level: .aboveRoads)
            
            // 添加颜色覆盖层，提供轻微的背景色
            let colorOverlay = ColorOverlay(region: mapView.region)
            mapView.addOverlay(colorOverlay, level: .aboveLabels)
            
            // 确保代理设置正确
            mapView.delegate = MapViewCustomDelegate.shared
            
            // 强制切换到标准地图类型
            if #available(iOS 16.0, *) {
                let config = MKStandardMapConfiguration()
                config.elevationStyle = .flat
                config.pointOfInterestFilter = .includingAll
                config.showsTraffic = false
                mapView.preferredConfiguration = config
            }
        }
        
        // 递归遍历所有子视图
        for subview in view.subviews {
            findAndFixMapRedBackgroundIssue(in: subview)
        }
    }
    #endif
    
    // 全局应用正确的地图颜色
    private func applyCorrectMapColors() {
        #if os(iOS)
        fixMapZoomColorIssue()
        #endif
    }
    
    // 选择搜索结果
    private func selectSearchResult(_ item: MKMapItem) {
        selectedSearchResult = item
        
        // 设置缩放标志
        isZooming = true
        
        // 先更新缩放级别
        self.zoomLevel = 0.15 // 更新为新的最小缩放级别
        
        // 在地图上显示选定位置，使用更流畅的动画并使用安全的缩放范围
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(MapStyleUtility.createSafeRegion(center: item.placemark.coordinate))
            
            // 移除这里的赋值，避免在闭包内修改let常量
        }
        
        // 延迟重置缩放标志
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isZooming = false
        }
        
        // 关闭搜索结果列表
        searchIsActive = false
    }
    
    // Load sample photo annotations (in a real app, these would come from Firestore)
    private func loadSamplePhotoAnnotations() {
        // Sample locations around the world
        let locations = [
            CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York
            CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
            CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo
            CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)  // Beijing
        ]
        
        // Create photo annotations
        for (index, location) in locations.enumerated() {
            let annotation = PhotoAnnotation(
                id: "photo\(index)",
                coordinate: location,
                imageUrl: "sample_url_\(index)",
                timestamp: Date()
            )
            photoAnnotations.append(annotation)
        }
    }
}

// Model for photo map annotations
struct PhotoAnnotation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let imageUrl: String
    let timestamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoAnnotation, rhs: PhotoAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 内联照片拍摄视图
#if os(iOS)
struct InlinePhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var locationDescription = "获取位置中..."
    @State private var cameraAvailable = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = capturedImage {
                    // Show the captured image with location info
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    Text(locationDescription)
                        .font(.headline)
                        .padding()
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            if cameraAvailable {
                                capturedImage = nil
                                showingCamera = true
                            } else {
                                // 提示用户相机不可用
                                print("相机不可用")
                            }
                        }) {
                            Text("重拍")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .disabled(!cameraAvailable)
                        
                        Button(action: {
                            savePhoto()
                            dismiss()
                        }) {
                            Text("保存")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                } else {
                    if !cameraAvailable {
                        // 相机不可用时显示提示
                        VStack(spacing: 20) {
                            Image(systemName: "camera.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("相机不可用")
                                .font(.headline)
                            
                            Text("请在真机上运行或检查相机权限")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("关闭") {
                                dismiss()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                        }
                        .padding()
                    } else {
                        // 加载相机中的占位图
                        ZStack {
                            Color.black
                                .compatibleIgnoresSafeArea()
                            
                            Text("加载相机...")
                                .foregroundColor(.white)
                                .font(.title)
                        }
                    }
                }
            }
            .navigationTitle("拍照")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 检查相机可用性
                cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
                
                // 只有当相机可用时才启动位置更新和相机
                if cameraAvailable {
                    startLocationUpdates()
                    // 延迟一点启动相机，避免UI阻塞
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingCamera = true
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera, onDismiss: {
                    if capturedImage != nil {
                        getLocationDescription()
                    } else {
                        dismiss()
                    }
                })
            }
        }
    }
    
    private func startLocationUpdates() {
        // In a real app, you would use CLLocationManager to get the user's location
        // For this demo, we'll simulate a location in Shanghai
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentLocation = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
            self.getLocationDescription()
        }
    }
    
    private func getLocationDescription() {
        guard let _ = currentLocation else { return }
        
        // In a real app, you would use CLGeocoder to reverse geocode the location
        // For this demo, we'll just use a hardcoded value
        self.locationDescription = "上海市"
    }
    
    private func savePhoto() {
        // In a real app, you would save the image to local storage and database
        // along with the location information
        print("Photo saved with location: \(locationDescription)")
    }
}

// UIImagePickerController SwiftUI wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // 检查设备是否支持指定的sourceType
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // 如果不支持（如模拟器无相机），则使用默认的photoLibrary
            picker.sourceType = .photoLibrary
        }
        
        // 设置委托
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
    }
}
#else
// 为非iOS平台提供一个简单的替代实现
struct InlinePhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("相机功能仅在iOS设备上可用")
                .font(.headline)
                .padding()
            
            Button("关闭") {
                dismiss()
            }
            .padding()
        }
    }
}
#endif

// MARK: - 内联位置照片专辑视图
struct InlineLocationPhotoAlbumView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Sample location data
    @State private var photoLocations: [LocationPhotoCollection] = sampleLocationPhotoCollections
    @State private var selectedLocation: LocationPhotoCollection?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(photoLocations) { location in
                        LocationAlbumSection(location: location) {
                            selectedLocation = location
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationTitle("照片地点")
            .compatibleNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedLocation) { location in
                LocationPhotoDetailView(location: location)
            }
        }
    }
}

struct LocationAlbumSection: View {
    let location: LocationPhotoCollection
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.secondaryApp)
                
                Text(location.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(location.photos.count) 张照片")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Photo preview grid
            let previewPhotos = Array(location.photos.prefix(4))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(previewPhotos) { photo in
                    SafeAsyncImage(url: URL(string: photo.url)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // "View all" button
            Button(action: onTap) {
                HStack {
                    Text("查看全部")
                        .font(.headline)
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct SafeAsyncImage<Content: View, Placeholder: View>: View {
    var url: URL?
    var content: (Image) -> Content
    var placeholder: () -> Placeholder
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder()
                case .success(let image):
                    content(image)
                case .failure(_):
                    // 显示错误状态
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                @unknown default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}

struct LocationPhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let location: LocationPhotoCollection
    @State private var mapPosition: MapCameraPosition
    @State private var isMapAnimated = false
    
    // Grid layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Initializer to set up the initial camera position
    init(location: LocationPhotoCollection) {
        self.location = location
        // Set the initial map position using safe region
        self._mapPosition = State(initialValue: .region(MapStyleUtility.createSafeRegion(center: location.coordinate)))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Map preview
                Map(position: $mapPosition) {
                    Annotation(coordinate: location.coordinate) {
                        ZStack {
                            // 创建光晕效果
                            Circle()
                                .fill(Color.primaryApp.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .blur(radius: isMapAnimated ? 5 : 2)
                            
                            Circle()
                                .fill(Color.primaryApp.opacity(0.9))
                                .frame(width: 36, height: 36)
                                .shadow(radius: 3)
                            
                            Image(systemName: "photo.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isMapAnimated ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isMapAnimated)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.primaryApp)
                            
                            Text(location.name)
                                .font(.caption)
                                .bold()
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .withAppleMapsStyling() // 使用工具类应用一致的地图样式
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 12)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .overlay(
                    // 添加地图边框装饰
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                // 避免使用 .disabled() 可能会有兼容性问题
                // 允许用户与地图交互
                
                // Location info section
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.secondaryApp)
                    
                    Text(location.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\(location.photos.count) 张照片")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Photo grid with improved visual hierarchy
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(location.photos) { photo in
                            SafeAsyncImage(url: URL(string: photo.url)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ZStack {
                                    Color.gray.opacity(0.3)
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                }
                            }
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .transition(.opacity)
                        }
                    }
                    .padding(6)
                    .animation(.easeInOut, value: location.photos.count)
                }
            }
            .navigationTitle(location.name)
            .compatibleNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 开始标记动画
                isMapAnimated = true
                
                // Animation for zooming in slightly on appear
                withAnimation(.easeInOut(duration: 1.2)) {
                    // 使用工具类创建安全的区域
                    mapPosition = .region(MapStyleUtility.createSafeRegion(center: location.coordinate))
                }
            }
        }
    }
}

// Model for location photo collections
struct LocationPhotoCollection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let photos: [PhotoItem]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LocationPhotoCollection, rhs: LocationPhotoCollection) -> Bool {
        lhs.id == rhs.id
    }
}

// Model for individual photos
struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let date: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Sample data
let sampleLocationPhotoCollections = [
    LocationPhotoCollection(
        name: "上海市",
        coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        photos: (1...8).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "北京市",
        coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        photos: (9...15).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "杭州市",
        coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
        photos: (16...23).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "成都市",
        coordinate: CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668),
        photos: (24...30).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "广州市",
        coordinate: CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644),
        photos: (31...38).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    )
]

#Preview {
    CountryMapView()
} 