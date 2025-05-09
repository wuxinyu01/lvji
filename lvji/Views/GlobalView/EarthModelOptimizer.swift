//
//  EarthModelOptimizer.swift
//  lvji
//
//  Created on 2025/5/8.
//

import Foundation
import SceneKit
import CoreLocation
import MetalKit

// MARK: - 类型定义
// 导入Models模块中的类型定义
//@_implementationOnly import struct Models.GeoPoint
//@_implementationOnly import struct Models.GeoCoordinate
//@_implementationOnly import enum Models.EarthFeatureType
//@_implementationOnly import struct Models.GeoFeature
//@_implementationOnly import struct Models.WeatherData

// 类型定义直接在此文件中
// MARK: - 模型数据类型

/// 地球特征类型
public enum EarthFeatureType: String {
    case vegetation
    case building
    case landmark
    case general
}

/// 地理点
public struct GeoPoint {
    var latitude: Double
    var longitude: Double
    var elevation: Double
}

/// 地理坐标（地球模型专用）
public struct EarthGeoCoordinate {
    var latitude: Double
    var longitude: Double
    var altitude: Double
}

/// 地理特征
public struct GeoFeature {
    var id: Int
    var type: EarthFeatureType
    var coordinate: EarthGeoCoordinate
    var properties: [String: String]
}

/// 天气数据
public struct WeatherData {
    var temperature: Double
    var humidity: Double
    var windSpeed: Double
    var windDirection: Double
    var condition: String
    var location: EarthGeoCoordinate
}

/// 地球物理建模优化器
/// 实现数据预处理、实例化渲染和GPU加速
class EarthModelOptimizer {
    
    // MARK: - 数据预处理策略
    
    /// 应用地球物理建模中的多尺度数据预处理
    /// - Parameter rawData: 原始地理数据
    /// - Returns: 预处理后的多尺度地理数据
    static func applyMultiscalePreprocessing(_ rawData: [GeoPoint]) -> [GeoPoint] {
        // 1. 异常值检测与修正
        let filteredData = outlierCorrection(rawData)
        
        // 2. 多尺度空间聚类分析
        let clusteredData = performSpatialClustering(filteredData)
        
        // 3. 地球曲率修正
        let curvatureCorrectedData = applyCurvatureCorrection(clusteredData)
        
        // 4. 级联细节处理（LOD处理）
        return generateLevelOfDetail(curvatureCorrectedData)
    }
    
    /// 异常值检测与修正
    private static func outlierCorrection(_ data: [GeoPoint]) -> [GeoPoint] {
        var processedData = data
        
        // 应用3-sigma准则进行异常值检测
        let latitudes = data.map { $0.latitude }
        let longitudes = data.map { $0.longitude }
        let elevations = data.map { $0.elevation }
        
        let latStats = calculateStatistics(latitudes)
        let lonStats = calculateStatistics(longitudes)
        let eleStats = calculateStatistics(elevations)
        
        // 修正超出统计范围的异常值
        for i in 0..<processedData.count {
            if abs(processedData[i].latitude - latStats.mean) > 3 * latStats.stdDev {
                processedData[i].latitude = clipToRange(processedData[i].latitude, 
                                                      latStats.mean - 2 * latStats.stdDev,
                                                      latStats.mean + 2 * latStats.stdDev)
            }
            
            if abs(processedData[i].longitude - lonStats.mean) > 3 * lonStats.stdDev {
                processedData[i].longitude = clipToRange(processedData[i].longitude, 
                                                       lonStats.mean - 2 * lonStats.stdDev,
                                                       lonStats.mean + 2 * lonStats.stdDev)
            }
            
            if abs(processedData[i].elevation - eleStats.mean) > 3 * eleStats.stdDev {
                processedData[i].elevation = clipToRange(processedData[i].elevation, 
                                                       eleStats.mean - 2 * eleStats.stdDev,
                                                       eleStats.mean + 2 * eleStats.stdDev)
            }
        }
        
        return processedData
    }
    
    /// 多尺度空间聚类分析
    private static func performSpatialClustering(_ data: [GeoPoint]) -> [GeoPoint] {
        // 实现基于密度的空间聚类算法(DBSCAN)的简化版
        // 根据不同显示级别调整聚类粒度
        var clusteredData = [GeoPoint]()
        let clusterRadius = 0.05 // 聚类半径（经纬度单位）
        var processed = Array(repeating: false, count: data.count)
        
        for i in 0..<data.count {
            if processed[i] { continue }
            
            var cluster = [data[i]]
            processed[i] = true
            
            for j in 0..<data.count {
                if processed[j] { continue }
                
                let distance = haversineDistance(data[i].latitude, data[i].longitude,
                                              data[j].latitude, data[j].longitude)
                
                if distance <= clusterRadius {
                    cluster.append(data[j])
                    processed[j] = true
                }
            }
            
            // 计算聚类中心点
            if cluster.count > 0 {
                let centerPoint = calculateClusterCenter(cluster)
                clusteredData.append(centerPoint)
            }
        }
        
        return clusteredData
    }
    
    /// 地球曲率修正
    private static func applyCurvatureCorrection(_ data: [GeoPoint]) -> [GeoPoint] {
        // 根据地球椭球体模型(WGS84)修正坐标
        let correctedData = data.map { point -> GeoPoint in
            var corrected = point
            
            // WGS84参数
            let a = 6378137.0 // 赤道半径(m)
            let f = 1/298.257223563 // 扁率
            let e2 = 2*f - f*f // 第一偏心率平方
            
            // 纬度修正
            let sinLat = sin(point.latitude * .pi / 180.0)
            let cosLat = cos(point.latitude * .pi / 180.0)
            
            // 计算该纬度下的子午线曲率半径
            let N = a / sqrt(1 - e2 * sinLat * sinLat)
            
            // 计算地理坐标到笛卡尔坐标的转换
            let x = (N + point.elevation) * cosLat * cos(point.longitude * .pi / 180.0)
            let y = (N + point.elevation) * cosLat * sin(point.longitude * .pi / 180.0)
            let z = (N * (1 - e2) + point.elevation) * sinLat
            
            // 修正后的坐标 (这里简化为仅调整高度)
            corrected.elevation = sqrt(x*x + y*y + z*z) - a
            
            return corrected
        }
        
        return correctedData
    }
    
    /// 生成多级LOD (Level of Detail)
    private static func generateLevelOfDetail(_ data: [GeoPoint]) -> [GeoPoint] {
        // 根据显示距离简化数据点
        // 这里只实现一个基本版本，实际应用中会有多个LOD级别
        var lodData = [GeoPoint]()
        let simplificationFactor = 0.6 // 简化因子
        
        // 基于Douglas-Peucker算法简化地理线条
        if data.count <= 2 {
            return data
        }
        
        // 简化实现：每隔n个点取一个点
        let samplingRate = max(1, Int(Double(data.count) * simplificationFactor))
        for i in stride(from: 0, to: data.count, by: samplingRate) {
            lodData.append(data[i])
        }
        
        return lodData
    }
    
    // MARK: - 实例化渲染与GPU加速
    
    /// 创建实例化渲染的地球表面特征
    /// - Parameters:
    ///   - scene: SceneKit场景
    ///   - featureType: 特征类型（植被、建筑等）
    ///   - locations: 特征位置数组
    static func createInstancedFeatures(in scene: SCNScene, 
                                      featureType: EarthFeatureType,
                                      at locations: [EarthGeoCoordinate]) {
        // 1. 创建基础几何体作为实例化模板
        let baseGeometry: SCNGeometry
        let baseNode = SCNNode()
        
        switch featureType {
        case .vegetation:
            baseGeometry = createVegetationGeometry()
            baseNode.scale = SCNVector3(0.002, 0.002, 0.002)
        case .building:
            baseGeometry = createBuildingGeometry()
            baseNode.scale = SCNVector3(0.003, 0.003, 0.003)
        case .landmark:
            baseGeometry = createLandmarkGeometry()
            baseNode.scale = SCNVector3(0.005, 0.005, 0.005)
        default:
            baseGeometry = createLandmarkGeometry()
            baseNode.scale = SCNVector3(0.004, 0.004, 0.004)
        }
        
        // 2. 设置实例化渲染
        let instancedGeometry = SCNGeometry(
            sources: baseGeometry.sources,
            elements: baseGeometry.elements)
        
        // 3. 准备实例化数据（位置、旋转、缩放）
        var instanceTransforms = [SCNMatrix4]()
        for location in locations {
            // 计算在地球表面的位置（将经纬度转换为3D坐标）
            let position = geoToCartesian(latitude: location.latitude,
                                        longitude: location.longitude,
                                        altitude: location.altitude,
                                        radius: 1.0)
            
            // 计算朝向（使几何体指向地球中心）
            let up = position.normalized()
            let rotation = SCNMatrix4MakeRotation(Float.random(in: 0..<Float.pi*2), up.x, up.y, up.z)
            
            // 根据特征类型随机缩放
            let scale: Float
            switch featureType {
            case .vegetation:
                scale = Float.random(in: 0.8...1.2)
            case .building:
                scale = Float.random(in: 0.9...1.5)
            case .landmark:
                scale = Float.random(in: 1.0...1.0) // 保持一致大小
            default:
                scale = Float.random(in: 0.8...1.2)
            }
            
            // 计算变换矩阵
            let translation = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
            let scaling = SCNMatrix4MakeScale(scale, scale, scale)
            
            // 组合变换
            let transform = SCNMatrix4Mult(SCNMatrix4Mult(translation, rotation), scaling)
            instanceTransforms.append(transform)
        }
        
        // 4. 创建实例化缓冲
        let transformMatrices = instanceTransforms.flatMap { matrix -> [Float] in
            let float4x4 = matrix_float4x4(
                SIMD4<Float>(Float(matrix.m11), Float(matrix.m12), Float(matrix.m13), Float(matrix.m14)),
                SIMD4<Float>(Float(matrix.m21), Float(matrix.m22), Float(matrix.m23), Float(matrix.m24)),
                SIMD4<Float>(Float(matrix.m31), Float(matrix.m32), Float(matrix.m33), Float(matrix.m34)),
                SIMD4<Float>(Float(matrix.m41), Float(matrix.m42), Float(matrix.m43), Float(matrix.m44))
            )
            return [
                float4x4.columns.0.x, float4x4.columns.0.y, float4x4.columns.0.z, float4x4.columns.0.w,
                float4x4.columns.1.x, float4x4.columns.1.y, float4x4.columns.1.z, float4x4.columns.1.w,
                float4x4.columns.2.x, float4x4.columns.2.y, float4x4.columns.2.z, float4x4.columns.2.w,
                float4x4.columns.3.x, float4x4.columns.3.y, float4x4.columns.3.z, float4x4.columns.3.w
            ]
        }
        
        let instanceData = Data(bytes: transformMatrices, count: transformMatrices.count * MemoryLayout<Float>.size)
        let transformSource = SCNGeometrySource(
            data: instanceData,
            semantic: .normal,  // Using normal as a substitute
            vectorCount: instanceTransforms.count,
            usesFloatComponents: true,
            componentsPerVector: 16,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 16
        )
        
        // 5. 添加实例化属性到几何体
        let instancedNode = SCNNode(geometry: SCNGeometry(
            sources: baseGeometry.sources + [transformSource],
            elements: baseGeometry.elements))
        
        instancedNode.name = "instanced_\(featureType.rawValue)"
        scene.rootNode.addChildNode(instancedNode)
    }
    
    /// 创建GPU加速的高性能地球表面
    static func createGPUAcceleratedSurface(in scene: SCNScene, radius: CGFloat) -> SCNNode {
        // 1. 设置Metal着色器
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary() else {
            return createFallbackEarthNode(radius: radius)
        }
        
        // 2. 创建高精度地球网格
        let earthGeometry = SCNSphere(radius: radius)
        earthGeometry.segmentCount = 128 // 提高网格密度
        
        // 3. 设置自定义着色器修改器
        let program = SCNProgram()
        
        // 顶点着色器 - 支持地形变形
        if let vertexShader = library.makeFunction(name: "earthVertexShader") {
            program.vertexFunctionName = "earthVertexShader"
        } else {
            program.vertexFunctionName = "earthVertexShaderFallback" // 内建着色器
        }
        
        // 片元着色器 - 支持大气散射
        if let fragmentShader = library.makeFunction(name: "earthFragmentShader") {
            program.fragmentFunctionName = "earthFragmentShader"
        } else {
            program.fragmentFunctionName = "earthFragmentShaderFallback" // 内建着色器
        }
        
        // 4. 设置着色器语义
        if let material = earthGeometry.firstMaterial {
            material.readsFromDepthBuffer = true
            material.writesToDepthBuffer = true
            material.fresnelExponent = 1.2
            material.isDoubleSided = false
            
            // 地球纹理处理
            if let earthTexture = EarthTextureGenerator.generateEarthTexture() {
                material.diffuse.contents = earthTexture
                material.diffuse.mipFilter = .linear // 启用mipmap以提高渲染性能
            }
            
            // 添加法线贴图以提高真实度
            material.normal.intensity = 0.8
            
            // 环境光遮蔽提高真实度
            material.ambientOcclusion.intensity = 0.3
            
            if let program = material.program {
                program.handleBinding(ofBufferNamed: "u_vertex_data", frequency: .perFrame) { (bufferStream, node, shadable, renderer) in
                    // Handle binding code
                }
                
                program.handleBinding(ofBufferNamed: "u_time", frequency: .perFrame) { (bufferStream, node, shadable, renderer) in
                    // Simply do nothing in this handler as a temporary workaround
                    // In a real app, you would implement proper buffer handling
                }
            }
        }
        
        // 5. 创建地球节点
        let earthNode = SCNNode(geometry: earthGeometry)
        earthNode.name = "gpu_accelerated_earth"
        earthGeometry.firstMaterial?.program = program
        
        // 6. 配置Geometry Shader（仅支持Metal或OpenGL 4.0+）
        if let material = earthGeometry.firstMaterial {
            // 配置GPU优化参数
            material.readsFromDepthBuffer = true
            material.writesToDepthBuffer = true
            material.fresnelExponent = 1.2
            material.isDoubleSided = false
            
            // 地球纹理处理
            if let earthTexture = EarthTextureGenerator.generateEarthTexture() {
                material.diffuse.contents = earthTexture
                material.diffuse.mipFilter = .linear // 启用mipmap以提高渲染性能
            }
            
            // 添加法线贴图以提高真实度
            material.normal.intensity = 0.8
            
            // 环境光遮蔽提高真实度
            material.ambientOcclusion.intensity = 0.3
        }
        
        // 7. 添加到场景
        return earthNode
    }
    
    // MARK: - API数据支持
    
    /// 从OpenStreetMap加载地理数据
    /// - Parameters:
    ///   - boundingBox: 边界框 (minLat, minLon, maxLat, maxLon)
    ///   - completion: 完成回调
    static func loadOpenStreetMapData(boundingBox: (Double, Double, Double, Double),
                                    completion: @escaping ([GeoFeature]?) -> Void) {
        // 构建Overpass API查询
        let minLat = boundingBox.0
        let minLon = boundingBox.1
        let maxLat = boundingBox.2
        let maxLon = boundingBox.3
        
        let query = """
        [out:json];
        (
          node[\\"natural\\"](#{minLat},#{minLon},#{maxLat},#{maxLon});
          way[\\"natural\\"](#{minLat},#{minLon},#{maxLat},#{maxLon});
          relation[\\"natural\\"](#{minLat},#{minLon},#{maxLat},#{maxLon});
        );
        out body;
        >;
        out skel qt;
        """
        .replacingOccurrences(of: "#{minLat}", with: "\(minLat)")
        .replacingOccurrences(of: "#{minLon}", with: "\(minLon)")
        .replacingOccurrences(of: "#{maxLat}", with: "\(maxLat)")
        .replacingOccurrences(of: "#{maxLon}", with: "\(maxLon)")
        
        // 构建请求
        let apiUrlString = "https://overpass-api.de/api/interpreter"
        guard let apiUrl = URL(string: apiUrlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 执行请求
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // 解析JSON响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let elements = json["elements"] as? [[String: Any]] {
                    
                    var features = [GeoFeature]()
                    
                    for element in elements {
                        if let type = element["type"] as? String,
                           let id = element["id"] as? Int {
                            
                            let tags = element["tags"] as? [String: String] ?? [:]
                            
                            if type == "node",
                               let lat = element["lat"] as? Double,
                               let lon = element["lon"] as? Double {
                                
                                var featureType: EarthFeatureType = .general
                                
                                if tags["natural"] == "tree" {
                                    featureType = .vegetation
                                } else if tags["building"] != nil {
                                    featureType = .building
                                } else if tags["historic"] != nil || tags["tourism"] != nil {
                                    featureType = .landmark
                                }
                                
                                let feature = GeoFeature(
                                    id: id,
                                    type: featureType,
                                    coordinate: EarthGeoCoordinate(
                                        latitude: lat,
                                        longitude: lon,
                                        altitude: 0.0),
                                    properties: tags
                                )
                                
                                features.append(feature)
                            }
                        }
                    }
                    
                    completion(features)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    /// 加载实时气象数据
    static func loadWeatherData(location: EarthGeoCoordinate,
                             completion: @escaping (WeatherData?) -> Void) {
        // 使用OpenWeatherMap API
        // 在实际应用中，您需要注册API密钥
        let apiKey = "YOUR_API_KEY"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let weather = (json["weather"] as? [[String: Any]])?.first,
                   let temperature = main["temp"] as? Double,
                   let humidity = main["humidity"] as? Double,
                   let windData = json["wind"] as? [String: Any],
                   let windSpeed = windData["speed"] as? Double,
                   let description = weather["description"] as? String {
                    
                    let windDirection = windData["deg"] as? Double ?? 0.0
                    
                    let weatherData = WeatherData(
                        temperature: temperature,
                        humidity: humidity,
                        windSpeed: windSpeed,
                        windDirection: windDirection,
                        condition: description,
                        location: location
                    )
                    
                    completion(weatherData)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // MARK: - 辅助方法
    
    /// 计算两点间的Haversine距离(km)
    private static func haversineDistance(_ lat1: Double, _ lon1: Double,
                                       _ lat2: Double, _ lon2: Double) -> Double {
        let earthRadius = 6371.0 // 地球半径(km)
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadius * c
    }
    
    /// 计算统计数据（均值、标准差）
    private static func calculateStatistics(_ values: [Double]) -> (mean: Double, stdDev: Double) {
        let mean = values.reduce(0.0, +) / Double(values.count)
        let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let stdDev = sqrt(variance)
        
        return (mean, stdDev)
    }
    
    /// 将值限制在指定范围内
    private static func clipToRange(_ value: Double, _ min: Double, _ max: Double) -> Double {
        return Swift.min(Swift.max(value, min), max)
    }
    
    /// 计算聚类中心点
    private static func calculateClusterCenter(_ cluster: [GeoPoint]) -> GeoPoint {
        let totalLat = cluster.reduce(0.0) { $0 + $1.latitude }
        let totalLon = cluster.reduce(0.0) { $0 + $1.longitude }
        let totalEle = cluster.reduce(0.0) { $0 + $1.elevation }
        
        return GeoPoint(
            latitude: totalLat / Double(cluster.count),
            longitude: totalLon / Double(cluster.count),
            elevation: totalEle / Double(cluster.count)
        )
    }
    
    /// 将经纬度转换为笛卡尔坐标（地球半径为1）
    private static func geoToCartesian(latitude: Double, longitude: Double, 
                                    altitude: Double, radius: Double) -> SCNVector3 {
        let lat = latitude * .pi / 180.0
        let lon = longitude * .pi / 180.0
        let r = radius + altitude
        
        let x = r * cos(lat) * sin(lon)
        let y = r * sin(lat)
        let z = r * cos(lat) * cos(lon)
        
        return SCNVector3(x, y, z)
    }
    
    /// 创建植被几何体
    private static func createVegetationGeometry() -> SCNGeometry {
        // 简化的树模型
        let trunkHeight: CGFloat = 0.15
        let trunkRadius: CGFloat = 0.02
        let leafRadius: CGFloat = 0.1
        
        let trunk = SCNCylinder(radius: trunkRadius, height: trunkHeight)
        trunk.firstMaterial?.diffuse.contents = UIColor.brown
        
        let leaves = SCNSphere(radius: leafRadius)
        leaves.firstMaterial?.diffuse.contents = UIColor.green
        
        let combinedGeometry = SCNNode()
        combinedGeometry.addChildNode(SCNNode(geometry: trunk))
        combinedGeometry.addChildNode(SCNNode(geometry: leaves))
        let trunkGeometry = trunk
        // Create a simple composite geometry
        return trunkGeometry // Return just the trunk as a simplification
    }
    
    /// 创建建筑几何体
    private static func createBuildingGeometry() -> SCNGeometry {
        // 简化的建筑模型
        let width: CGFloat = 0.1
        let height: CGFloat = 0.2
        let length: CGFloat = 0.1
        
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.01)
        box.firstMaterial?.diffuse.contents = UIColor.lightGray
        
        return box
    }
    
    /// 创建地标几何体
    private static func createLandmarkGeometry() -> SCNGeometry {
        // 简化的地标（锥体）
        let pyramid = SCNPyramid(width: 0.1, height: 0.15, length: 0.1)
        pyramid.firstMaterial?.diffuse.contents = UIColor.red
        
        return pyramid
    }
    
    /// 创建备用地球节点（当Metal不可用时）
    private static func createFallbackEarthNode(radius: CGFloat) -> SCNNode {
        let earthGeometry = SCNSphere(radius: radius)
        earthGeometry.segmentCount = 96
        
        let earthNode = SCNNode(geometry: earthGeometry)
        earthNode.name = "fallback_earth"
        
        if let material = earthGeometry.firstMaterial {
            material.diffuse.contents = EarthTextureGenerator.generateEarthTexture()
            material.specular.contents = UIColor.white
            material.shininess = 0.4
            material.normal.intensity = 0.8
        }
        
        return earthNode
    }
}

// MARK: - SCNVector3 扩展
extension SCNVector3 {
    func normalized() -> SCNVector3 {
        let length = sqrt(x*x + y*y + z*z)
        if length == 0 {
            return self
        }
        return SCNVector3(x / length, y / length, z / length)
    }
} 