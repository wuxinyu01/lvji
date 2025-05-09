//
//  EarthView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import SceneKit
import UIKit
import MetalKit
import CoreLocation

// 注意：直接使用EarthModelOptimizer中定义的类型
// import struct lvji.GeoPoint
// import struct lvji.GeoCoordinate
// import enum lvji.EarthFeatureType
// import struct lvji.GeoFeature
// import struct lvji.WeatherData

// MARK: - 使用EarthModelOptimizer中定义的类型

struct EarthView: View {
    // 添加配置选项
    @State private var useDataPreprocessing = true
    @State private var useGPUAcceleration = true
    @State private var useExternalData = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            SceneKitView(useDataPreprocessing: useDataPreprocessing,
                        useGPUAcceleration: useGPUAcceleration,
                        useExternalData: useExternalData)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct SceneKitView: UIViewRepresentable {
    // 配置选项
    var useDataPreprocessing: Bool
    var useGPUAcceleration: Bool
    var useExternalData: Bool
    
    var scene = SCNScene()

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.delegate = context.coordinator
        
        // 传递配置选项到协调器
        context.coordinator.useGPUAcceleration = useGPUAcceleration
        context.coordinator.useDataPreprocessing = useDataPreprocessing
        
        // 设置场景选项
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        scnView.autoenablesDefaultLighting = false
        
        // 启用HDR渲染和后处理效果
        scnView.preferredFramesPerSecond = 60
        
        // 设置相机
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // 高级相机设置
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.3
        cameraNode.camera?.bloomBlurRadius = 4.0
        cameraNode.camera?.exposureOffset = 0.1
        
        // 创建更高质量的地球
        context.coordinator.loadEarth(in: scene)
        
        // 加载环境光
        setupLighting()
        
        // 添加高质量星空背景
        addImprovedStars()
        
        // 添加点击手势识别器
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(EarthViewCoordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // 如果启用外部数据，加载API数据
        if useExternalData {
            context.coordinator.loadExternalAPIData()
        }
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 当配置选项变化时更新
        if context.coordinator.useGPUAcceleration != useGPUAcceleration ||
           context.coordinator.useDataPreprocessing != useDataPreprocessing {
            context.coordinator.useGPUAcceleration = useGPUAcceleration
            context.coordinator.useDataPreprocessing = useDataPreprocessing
            context.coordinator.loadEarth(in: scene)
        }
        
        // 如果需要加载外部数据且尚未加载
        if useExternalData && !context.coordinator.hasLoadedExternalData {
            context.coordinator.loadExternalAPIData()
            context.coordinator.hasLoadedExternalData = true
        }
    }
    
    func makeCoordinator() -> EarthViewCoordinator {
        EarthViewCoordinator(self)
    }
    
    // 设置照明
    private func setupLighting() {
        // 创建主光源（模拟太阳）
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.color = UIColor(white: 1.0, alpha: 1.0)
        mainLight.light?.intensity = 1000
        mainLight.light?.castsShadow = true
        mainLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.8)
        mainLight.light?.shadowMode = .forward
        mainLight.light?.shadowRadius = 3.0
        mainLight.position = SCNVector3(x: 2, y: 1, z: 3)
        mainLight.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(mainLight)
        
        // 创建环境光（模拟整体照明）
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)
        
        // 创建填充光（照亮阴影区域）
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.color = UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        fillLight.light?.intensity = 400
        fillLight.position = SCNVector3(x: -2, y: -0.5, z: -1)
        scene.rootNode.addChildNode(fillLight)
    }
    
    // 添加高质量星空背景
    private func addImprovedStars() {
        let stars = SCNNode()
        stars.name = "stars"
        
        let starCount = 2000
        let starSpread: Float = 100.0
        
        // 为性能优化，使用实例化渲染星星
        let starGeometry = SCNSphere(radius: 0.15)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor.white
        starMaterial.emission.contents = UIColor.white
        starMaterial.transparency = 0.8
        starGeometry.firstMaterial = starMaterial
        
        var instancedStarGeometries = [SCNGeometry]()
        
        // 创建不同大小的星星原型
        let smallStarGeometry = SCNSphere(radius: 0.05)
        smallStarGeometry.firstMaterial = starMaterial.copy() as? SCNMaterial
        
        let mediumStarGeometry = SCNSphere(radius: 0.1)
        mediumStarGeometry.firstMaterial = starMaterial.copy() as? SCNMaterial
        
        let largeStarGeometry = SCNSphere(radius: 0.15)
        largeStarGeometry.firstMaterial = starMaterial.copy() as? SCNMaterial
        
        // 创建星星实例
        for _ in 0..<starCount {
            // 随机星星大小
            let starSize = Int.random(in: 0...2)
            var starNode: SCNNode
            
            switch starSize {
            case 0:
                starNode = SCNNode(geometry: smallStarGeometry)
                starNode.opacity = CGFloat(Float.random(in: 0.3...0.6))
            case 1:
                starNode = SCNNode(geometry: mediumStarGeometry)
                starNode.opacity = CGFloat(Float.random(in: 0.5...0.8))
            default:
                starNode = SCNNode(geometry: largeStarGeometry)
                starNode.opacity = CGFloat(Float.random(in: 0.7...1.0))
            }
            
            // 随机位置
            let x = Float.random(in: -starSpread...starSpread)
            let y = Float.random(in: -starSpread...starSpread)
            let z = Float.random(in: -starSpread...starSpread)
            
            // 确保星星在距离原点足够远的地方
            let distance = sqrt(x*x + y*y + z*z)
            if distance < 20.0 { continue }
            
            starNode.position = SCNVector3(x, y, z)
            
            // 添加光晕效果
            if Float.random(in: 0...1) > 0.8 {
                let glowGeometry = SCNSphere(radius: 0.3)
                let glowMaterial = SCNMaterial()
                glowMaterial.diffuse.contents = UIColor.clear
                glowMaterial.emission.contents = UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
                glowMaterial.transparency = 0.3
                glowGeometry.firstMaterial = glowMaterial
                
                let glowNode = SCNNode(geometry: glowGeometry)
                starNode.addChildNode(glowNode)
            }
            
            stars.addChildNode(starNode)
        }
        
        scene.rootNode.addChildNode(stars)
    }
}

class EarthViewCoordinator: NSObject, SCNSceneRendererDelegate {
    
    let parent: SceneKitView
    var earthNode: SCNNode?
    var materialParameters: SCNMaterialProperty?
    var lastRenderTime: TimeInterval = 0
    
    // 添加性能统计
    var frameCount: Int = 0
    var lastFPSTime: TimeInterval = 0
    var currentFPS: Int = 0
    
    // 添加配置控制
    var useGPUAcceleration: Bool = true
    var useDataPreprocessing: Bool = true
    var useInstancedRendering: Bool = true
    var hasLoadedExternalData: Bool = false
    
    init(_ parent: SceneKitView) {
        self.parent = parent
        super.init()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 性能监控
        frameCount += 1
        if time - lastFPSTime > 1.0 {
            currentFPS = frameCount
            frameCount = 0
            lastFPSTime = time
            print("Current FPS: \(currentFPS)")
        }
        
        // 更新时间参数（用于着色器动画）
        if let material = earthNode?.geometry?.firstMaterial,
           let program = material.program {
            let timeValue = Float(time)
            program.handleBinding(ofBufferNamed: "u_time", frequency: .perFrame) { (stream, node, shadable, renderer) in
                // Handle binding code here
            }
        }
        
        // 更新星星位置（增加随机微小移动以增强视觉效果）
        if time - lastRenderTime > 0.1 {
            lastRenderTime = time
            
            // 为了优化性能，仅在必要时更新
            parent.scene.rootNode.childNodes.forEach { node in
                if node.name == "stars" {
                    let randomRotation = SCNVector4(
                        0, 1, 0, 
                        Float.random(in: -0.0001...0.0001)
                    )
                    node.rotation = randomRotation
                }
            }
        }
    }
    
    // 实现优化的载入流程
    func loadEarth(in scene: SCNScene) {
        // 移除现有的地球节点（如果存在）
        scene.rootNode.childNodes.forEach { node in
            if node.name == "earth" || node.name == "gpu_accelerated_earth" || 
               node.name?.hasPrefix("instanced_") == true {
                node.removeFromParentNode()
            }
        }
        
        // 根据是否使用GPU加速选择创建方式
        if useGPUAcceleration {
            // 使用GPU加速的地球
            let earthNode = EarthModelOptimizer.createGPUAcceleratedSurface(in: scene, radius: 1.0)
            scene.rootNode.addChildNode(earthNode)
            self.earthNode = earthNode
            
            // 设置高级着色器参数
            if let material = earthNode.geometry?.firstMaterial {
                // 设置着色器统一变量
                let elevationScale: Float = 1.0
                let atmosphereDensity: Float = 1.2
                let detailLevel: Float = 1.0
                
                material.setValue(elevationScale, forKey: "elevationScale")
                material.setValue(atmosphereDensity, forKey: "atmosphereDensity")
                material.setValue(detailLevel, forKey: "detailLevel")
            }
        } else {
            // 使用标准地球
            let geometry = SCNSphere(radius: 1.0)
            geometry.segmentCount = 96
            
            let earthNode = SCNNode(geometry: geometry)
            earthNode.name = "earth"
            scene.rootNode.addChildNode(earthNode)
            self.earthNode = earthNode
            
            // 应用原有材质
            if let material = geometry.firstMaterial {
                material.diffuse.contents = EarthTextureGenerator.generateEarthTexture()
                material.specular.contents = UIColor.white
                material.shininess = 0.7
                material.emission.contents = UIColor(white: 0.2, alpha: 1.0)
                material.reflective.contents = UIColor(white: 0.4, alpha: 1.0)
            }
        }
        
        // 应用多尺度数据预处理（如果有数据）
        if useDataPreprocessing, let dataPoints = loadGeoData() {
            let optimizedData = EarthModelOptimizer.applyMultiscalePreprocessing(dataPoints)
            addDataPointsToGlobe(optimizedData)
        }
        
        // 如果使用实例化渲染，添加地球表面特征
        if useInstancedRendering {
            addInstancedFeatures(to: scene)
        }
    }
    
    // 加载地理数据
    private func loadGeoData() -> [GeoPoint]? {
        // 这里应该从外部源加载数据
        // 示例数据（随机生成的）
        var dataPoints = [GeoPoint]()
        
        for _ in 0..<100 {
            let point = GeoPoint(
                latitude: Double.random(in: -80...80),
                longitude: Double.random(in: -180...180),
                elevation: Double.random(in: 0...0.05)
            )
            dataPoints.append(point)
        }
        
        return dataPoints
    }
    
    // 向地球添加数据点
    private func addDataPointsToGlobe(_ dataPoints: [GeoPoint]) {
        guard let earthNode = self.earthNode else { return }
        
        for point in dataPoints {
            // 将地理坐标转换为3D位置
            let position = geoToCartesian(latitude: point.latitude,
                                        longitude: point.longitude,
                                        elevation: point.elevation + 0.01)
            
            // 创建数据点标记
            let markerGeometry = SCNSphere(radius: 0.005)
            markerGeometry.firstMaterial?.diffuse.contents = UIColor.red
            
            let markerNode = SCNNode(geometry: markerGeometry)
            markerNode.position = position
            
            // 添加到地球
            earthNode.addChildNode(markerNode)
        }
    }
    
    // 添加实例化特征（使用实例化渲染）
    private func addInstancedFeatures(to scene: SCNScene) {
        // 生成随机位置的植被
        var vegetationLocations = [EarthGeoCoordinate]()
        for _ in 0..<1000 {
            let location = EarthGeoCoordinate(
                latitude: Double.random(in: -80...80),
                longitude: Double.random(in: -180...180),
                altitude: 0.01
            )
            vegetationLocations.append(location)
        }
        
        // 生成随机位置的建筑
        var buildingLocations = [EarthGeoCoordinate]()
        for _ in 0..<500 {
            let location = EarthGeoCoordinate(
                latitude: Double.random(in: -60...60),
                longitude: Double.random(in: -170...170),
                altitude: 0.01
            )
            buildingLocations.append(location)
        }
        
        // 生成随机位置的地标
        var landmarkLocations = [EarthGeoCoordinate]()
        for _ in 0..<100 {
            let location = EarthGeoCoordinate(
                latitude: Double.random(in: -70...70),
                longitude: Double.random(in: -175...175),
                altitude: 0.01
            )
            landmarkLocations.append(location)
        }
        
        // 应用实例化渲染
        EarthModelOptimizer.createInstancedFeatures(in: scene, 
                                                  featureType: .vegetation, 
                                                  at: vegetationLocations)
        
        EarthModelOptimizer.createInstancedFeatures(in: scene, 
                                                  featureType: .building, 
                                                  at: buildingLocations)
        
        EarthModelOptimizer.createInstancedFeatures(in: scene, 
                                                  featureType: .landmark, 
                                                  at: landmarkLocations)
    }
    
    // 将地理坐标转换为3D坐标
    private func geoToCartesian(latitude: Double, longitude: Double, elevation: Double) -> SCNVector3 {
        let radius = 1.0 + elevation
        let phi = latitude * .pi / 180.0
        let theta = longitude * .pi / 180.0
        
        let x = radius * cos(phi) * sin(theta)
        let y = radius * sin(phi)
        let z = radius * cos(phi) * cos(theta)
        
        return SCNVector3(x, y, z)
    }

    // 加载外部API数据示例
    func loadExternalAPIData() {
        // 定义感兴趣的区域 (纽约附近)
        let bbox = (40.70, -74.01, 40.80, -73.95)
        
        EarthModelOptimizer.loadOpenStreetMapData(boundingBox: bbox) { [weak self] features in
            guard let features = features else {
                print("Failed to load OSM data")
                return
            }
            
            DispatchQueue.main.async {
                print("Loaded \(features.count) features from OpenStreetMap")
                
                // 添加到场景中
                var buildingLocations = [EarthGeoCoordinate]()
                var landmarkLocations = [EarthGeoCoordinate]()
                
                for feature in features {
                    switch feature.type {
                    case .building:
                        buildingLocations.append(feature.coordinate)
                    case .landmark:
                        landmarkLocations.append(feature.coordinate)
                    default:
                        break
                    }
                }
                
                // 应用实例化渲染
                if let scene = self?.parent.scene {
                    if !buildingLocations.isEmpty {
                        EarthModelOptimizer.createInstancedFeatures(in: scene, 
                                                                  featureType: .building, 
                                                                  at: buildingLocations)
                    }
                    
                    if !landmarkLocations.isEmpty {
                        EarthModelOptimizer.createInstancedFeatures(in: scene, 
                                                                  featureType: .landmark, 
                                                                  at: landmarkLocations)
                    }
                }
                
                self?.hasLoadedExternalData = true
            }
        }
        
        // 加载气象数据示例
        let nyc = EarthGeoCoordinate(latitude: 40.7128, longitude: -74.0060, altitude: 0.0)
        EarthModelOptimizer.loadWeatherData(location: nyc) { [weak self] weatherData in
            if let weather = weatherData {
                DispatchQueue.main.async {
                    print("Loaded weather data for NYC: \(weather.temperature)°C, \(weather.condition)")
                    // 这里可以将天气数据可视化在地球上
                }
            }
        }
    }
    
    // 添加点击处理方法
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        // 获取点击位置
        let scnView = gestureRecognize.view as! SCNView
        let location = gestureRecognize.location(in: scnView)
        
        // 执行碰撞测试确定点击了哪个节点
        let hitResults = scnView.hitTest(location, options: [:])
        
        if !hitResults.isEmpty {
            let result = hitResults.first!
            let node = result.node
            
            print("Tapped on node: \(node.name ?? "unnamed")")
            
            // 检查是否点击了地球
            if node == earthNode || node.parent == earthNode {
                if let geometryResult = hitResults.first(where: { $0.geometryIndex >= 0 }) {
                    // 获取纹理坐标
                    let texCoords = geometryResult.textureCoordinates(withMappingChannel: 0)
                    print("Tapped at texture coordinates: (\(texCoords.x), \(texCoords.y))")
                    
                    // 将纹理坐标转换为地理坐标
                    let longitude = (texCoords.x - 0.5) * 360.0
                    let latitude = (0.5 - texCoords.y) * 180.0
                    print("Corresponding geo coordinates: lat \(latitude), lon \(longitude)")
                    
                    // 在这里可以根据地理坐标加载该区域的详细数据
                    loadDetailedDataForRegion(latitude: latitude, longitude: longitude)
                }
            }
        }
    }
    
    // 加载区域详细数据
    private func loadDetailedDataForRegion(latitude: Double, longitude: Double) {
        // 定义一个小区域
        let delta = 0.5
        let bbox = (latitude - delta, longitude - delta, latitude + delta, longitude + delta)
        
        // 从API加载区域数据
        EarthModelOptimizer.loadOpenStreetMapData(boundingBox: bbox) { [weak self] features in
            guard let features = features else { return }
            
            DispatchQueue.main.async {
                print("Loaded \(features.count) detailed features for region")
                
                // 可以为该区域创建更高细节的数据可视化
                // 例如，显示小型弹出标签或高亮显示该区域
            }
        }
    }
}

#Preview {
    EarthView()
} 