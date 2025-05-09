//
//  MetalEarthView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import MetalKit
import SceneKit

// MARK: - Earth Metal View 组件

/// 3D地球视图
struct MetalEarthView: View {
    // 渲染器
    @StateObject private var renderer = EarthMetalRenderer()
    
    // 状态
    @State private var isLoading = true
    @State private var earthOpacity: Double = 0.0
    @State private var useFallback: Bool = true  // 初始设置为使用备用方案
    
    // 渲染配置
    var atmosphereDensity: Float = 1.5    // 大气密度
    var elevationScale: Float = 0.02      // 高程缩放
    var detailLevel: Float = 1.5          // 细节级别 
    var rotationSpeed: Float = 0.003      // 旋转速度
    
    var body: some View {
        ZStack {
            // 星空背景
            StarFieldView()
                .ignoresSafeArea()
                .opacity(0.7)
            
            if !useFallback {
                // Metal渲染的地球
                MetalView(
                    renderer: renderer,
                    rotationSpeed: rotationSpeed,
                    atmosphereDensity: atmosphereDensity,
                    elevationScale: elevationScale,
                    detailLevel: detailLevel,
                    isLoading: $isLoading,
                    useFallback: $useFallback
                )
                .edgesIgnoringSafeArea(.all)
                .opacity(earthOpacity)
                .onAppear {
                    // 淡入效果
                    withAnimation(.easeIn(duration: 2.0).delay(1.0)) {
                        earthOpacity = 1.0
                    }
                    print("Metal视图已加载")
                }
            } else {
                // 备用SceneKit地球
                SimplifiedEarthView()
                    .opacity(earthOpacity)
                    .onAppear {
                        // 淡入效果
                        withAnimation(.easeIn(duration: 1.0)) {
                            earthOpacity = 1.0
                        }
                        print("已切换到SceneKit备用方案")
                    }
            }
            
            // 加载指示器
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            // 预加载着色器管理器
            print("MetalEarthView.onAppear: 预加载着色器管理器")
            let shaderManager = MetalShaderManager.shared
            print("着色器管理器初始化状态: \(shaderManager.isReady)")
            
            if let error = shaderManager.lastError {
                print("着色器管理器错误: \(error.localizedDescription)")
            }
            
            print("设备是否支持Metal: \(MetalShaderManager.isMetalSupported())")
            
            // 尝试自动切换回Metal
            if MetalShaderManager.isMetalSupported() && shaderManager.isReady {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 尝试在应用启动后半秒切换回Metal渲染
                    useFallback = false
                    isLoading = true
                    
                    // 如果3秒后仍未显示地球，切换回SceneKit
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        print("检查纹理加载状态: \(renderer.earthTextureLoaded)")
                        if !renderer.earthTextureLoaded {
                            useFallback = true
                            print("切换到SceneKit备用方案")
                            isLoading = false
                        }
                    }
                }
            } else {
                isLoading = false
                print("Metal不受支持或着色器初始化失败，使用SceneKit备用方案")
            }
        }
    }
}

// MARK: - Metal View

/// Metal视图
struct MetalView: UIViewRepresentable {
    var renderer: EarthMetalRenderer
    var rotationSpeed: Float = 0.05
    var atmosphereDensity: Float = 2.0
    var elevationScale: Float = 0.02
    var detailLevel: Float = 1.0
    
    @Binding var isLoading: Bool
    @Binding var useFallback: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        // 配置MTKView
        print("MetalView.makeUIView: 初始化MTKView")
        mtkView.delegate = renderer
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.05, alpha: 1.0)
        
        // 加载纹理
        print("开始加载纹理")
        renderer.loadTextures()
        
        // 设置渲染器参数
        renderer.rotationSpeed = rotationSpeed
        renderer.atmosphereDensity = atmosphereDensity
        renderer.elevationScale = elevationScale
        renderer.detailLevel = detailLevel
        
        // 检查Metal设备是否可用
        if mtkView.device == nil {
            print("警告: MTKView设备为nil")
        } else {
            print("MTKView设备可用: \(mtkView.device!)")
        }
        
        // 检查纹理是否加载成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("MetalView延迟检查: 纹理加载状态 = \(renderer.earthTextureLoaded)")
            if !renderer.earthTextureLoaded {
                print("Metal纹理加载失败，使用备用渲染")
                useFallback = true
            }
            isLoading = false
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        renderer.rotationSpeed = rotationSpeed
        renderer.atmosphereDensity = atmosphereDensity
        renderer.elevationScale = elevationScale
        renderer.detailLevel = detailLevel
    }
}

// MARK: - Simplified Earth View

/// 简化版地球视图（SceneKit备用）
struct SimplifiedEarthView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        print("SimplifiedEarthView.makeUIView: 创建SCNView")
        let scnView = SCNView()
        scnView.scene = createEarthScene()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        
        // 添加更好的环境光照
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        scnView.scene?.rootNode.addChildNode(ambientLight)
        
        // 添加定向光源（模拟太阳）
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        directionalLight.position = SCNVector3(x: 10, y: 10, z: 10)
        directionalLight.eulerAngles = SCNVector3(x: -0.5, y: 0.5, z: 0)
        scnView.scene?.rootNode.addChildNode(directionalLight)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 更新视图
    }
    
    /// 创建地球场景
    private func createEarthScene() -> SCNScene {
        print("SimplifiedEarthView.createEarthScene: 创建场景")
        let scene = SCNScene()
        
        // 创建地球球体
        let earthGeometry = SCNSphere(radius: 1.0)
        earthGeometry.segmentCount = 64 // 更高的细节
        let earthNode = SCNNode(geometry: earthGeometry)
        
        // 添加更美观的材质
        let earthMaterial = SCNMaterial()
        
        // 使用蓝色渐变作为基础
        let gradientImage = createGradientImage(
            colors: [
                UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0),
                UIColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1.0)
            ],
            size: CGSize(width: 256, height: 256)
        )
        
        // 添加一些随机圆点模拟大陆
        let textureWithContinents = addContinentsToTexture(gradientImage!)
        
        earthMaterial.diffuse.contents = textureWithContinents
        earthMaterial.specular.contents = UIColor.white
        earthMaterial.shininess = 0.3
        earthMaterial.emission.contents = UIColor(white: 0.05, alpha: 1.0) // 轻微发光效果
        
        // 添加云层
        let cloudGeometry = SCNSphere(radius: 1.05)
        cloudGeometry.segmentCount = 32
        let cloudNode = SCNNode(geometry: cloudGeometry)
        
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = createCloudTexture()
        cloudMaterial.transparent.contents = UIColor.white
        cloudMaterial.transparencyMode = .rgbZero
        cloudMaterial.writesToDepthBuffer = false
        cloudMaterial.readsFromDepthBuffer = true
        cloudMaterial.blendMode = .alpha
        cloudMaterial.transparency = 0.4
        
        cloudGeometry.materials = [cloudMaterial]
        
        // 应用材质
        earthGeometry.materials = [earthMaterial]
        
        // 添加到场景
        scene.rootNode.addChildNode(earthNode)
        scene.rootNode.addChildNode(cloudNode)
        
        // 添加旋转动画
        let earthRotation = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 30.0)
        let repeatEarthRotation = SCNAction.repeatForever(earthRotation)
        earthNode.runAction(repeatEarthRotation)
        
        // 添加稍慢的云层旋转
        let cloudRotation = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 40.0)
        let repeatCloudRotation = SCNAction.repeatForever(cloudRotation)
        cloudNode.runAction(repeatCloudRotation)
        
        return scene
    }
    
    // 创建渐变图像
    private func createGradientImage(colors: [UIColor], size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 创建渐变
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor as CGColor } as CFArray
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) {
            // 绘制圆形渐变
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size.width / 2,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 添加大陆纹理
    private func addContinentsToTexture(_ baseImage: UIImage) -> UIImage {
        let size = baseImage.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制基础图像
        baseImage.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else { return baseImage }
        
        // 添加随机大陆
        let landColor = UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 1.0)
        context.setFillColor(landColor.cgColor)
        
        // 北美
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.2, y: size.height * 0.3), size: CGSize(width: size.width * 0.3, height: size.height * 0.3))
        
        // 南美
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.25, y: size.height * 0.6), size: CGSize(width: size.width * 0.2, height: size.height * 0.3))
        
        // 欧洲
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.5, y: size.height * 0.3), size: CGSize(width: size.width * 0.15, height: size.height * 0.2))
        
        // 非洲
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.5, y: size.height * 0.5), size: CGSize(width: size.width * 0.25, height: size.height * 0.3))
        
        // 亚洲
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.7, y: size.height * 0.3), size: CGSize(width: size.width * 0.3, height: size.height * 0.3))
        
        // 澳大利亚
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.8, y: size.height * 0.6), size: CGSize(width: size.width * 0.2, height: size.height * 0.15))
        
        // 南极洲
        context.setFillColor(UIColor.white.cgColor)
        drawRandomOvalContinent(in: context, center: CGPoint(x: size.width * 0.5, y: size.height * 0.9), size: CGSize(width: size.width * 0.5, height: size.height * 0.15))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? baseImage
    }
    
    // 绘制随机椭圆形大陆
    private func drawRandomOvalContinent(in context: CGContext, center: CGPoint, size: CGSize) {
        let path = UIBezierPath()
        let steps = 20
        var lastPoint: CGPoint?
        
        for i in 0...steps {
            let angle = 2.0 * Double.pi * Double(i) / Double(steps)
            let radiusX = size.width / 2 * (0.8 + 0.4 * Double.random(in: 0...1))
            let radiusY = size.height / 2 * (0.8 + 0.4 * Double.random(in: 0...1))
            
            let x = center.x + CGFloat(radiusX * cos(angle))
            let y = center.y + CGFloat(radiusY * sin(angle))
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
                lastPoint = CGPoint(x: x, y: y)
            } else if let last = lastPoint {
                // 添加一点随机性让海岸线不那么规则
                let controlPoint = CGPoint(
                    x: (last.x + x) / 2 + CGFloat.random(in: -10...10),
                    y: (last.y + y) / 2 + CGFloat.random(in: -10...10)
                )
                path.addQuadCurve(to: CGPoint(x: x, y: y), controlPoint: controlPoint)
                lastPoint = CGPoint(x: x, y: y)
            }
        }
        
        path.close()
        context.addPath(path.cgPath)
        context.fillPath()
    }
    
    // 创建云层纹理
    private func createCloudTexture() -> UIImage {
        let size = CGSize(width: 512, height: 256)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        
        // 绘制透明背景
        context.clear(CGRect(origin: .zero, size: size))
        
        // 添加随机云朵
        context.setFillColor(UIColor.white.cgColor)
        
        for _ in 0..<30 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let cloudWidth = CGFloat.random(in: 20..<100)
            let cloudHeight = CGFloat.random(in: 10..<50)
            
            // 绘制不规则云朵
            let path = UIBezierPath()
            for i in 0..<8 {
                let angle = 2.0 * Double.pi * Double(i) / 8.0
                let xOffset = cloudWidth * CGFloat(cos(angle)) * CGFloat.random(in: 0.5...1.0)
                let yOffset = cloudHeight * CGFloat(sin(angle)) * CGFloat.random(in: 0.5...1.0)
                
                let point = CGPoint(x: x + xOffset, y: y + yOffset)
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            
            context.setAlpha(CGFloat.random(in: 0.3...0.8))
            context.addPath(path.cgPath)
            context.fillPath()
        }
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

// MARK: - Star Field View

/// 星空背景视图
struct StarFieldView: View {
    let starCount = 300
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 深色背景
                Color.black.edgesIgnoringSafeArea(.all)
                
                // 添加星星
                ForEach(0..<starCount, id: \.self) { _ in
                    Circle()
                        .fill(randomStarColor())
                        .frame(width: randomStarSize(), height: randomStarSize())
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.3...1.0))
                        .blur(radius: Double.random(in: 0...0.5))
                }
            }
        }
    }
    
    /// 随机星星颜色
    private func randomStarColor() -> Color {
        let colors: [Color] = [.white, .yellow, .blue, .red]
        let weights: [Double] = [0.7, 0.15, 0.1, 0.05]
        
        // 按权重选择颜色
        let value = Double.random(in: 0...1)
        var sum: Double = 0
        
        for i in 0..<colors.count {
            sum += weights[i]
            if value <= sum {
                return colors[i]
            }
        }
        
        return .white
    }
    
    /// 随机星星大小
    private func randomStarSize() -> CGFloat {
        let baseSize = CGFloat.random(in: 1...3)
        
        // 小概率生成更大的星星
        if Double.random(in: 0...1) > 0.95 {
            return baseSize * 2
        }
        
        return baseSize
    }
}

// MARK: - Preview

struct MetalEarthView_Previews: PreviewProvider {
    static var previews: some View {
        MetalEarthView()
    }
} 