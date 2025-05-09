//
//  EarthMetalRenderer.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import Foundation
import Metal
import MetalKit
import simd
import Combine

/// 使用Metal渲染地球的渲染器
class EarthMetalRenderer: NSObject, ObservableObject, MTKViewDelegate {
    // MARK: - 属性
    
    // Metal设备
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    
    // 纹理
    private var earthTexture: MTLTexture?
    private var normalMapTexture: MTLTexture?
    private var specularMapTexture: MTLTexture?
    private var nightTexture: MTLTexture?
    
    // 纹理加载状态
    @Published public var earthTextureLoaded: Bool = false
    
    // 模型数据
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var indexCount: Int = 0
    
    // 变换矩阵
    private var modelMatrix = matrix_identity_float4x4
    private var rotationX: Float = 0.0
    private var rotationY: Float = 0.0
    
    // 渲染参数
    public var atmosphereDensity: Float = 1.0
    public var elevationScale: Float = 0.01
    public var detailLevel: Float = 1.0
    public var rotationSpeed: Float = 0.001
    
    // MARK: - 初始化
    
    /// 默认初始化方法
    override init() {
        super.init()
        
        // 获取默认Metal设备
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal不支持的设备")
            return
        }
        
        self.device = device
        
        // 创建命令队列
        guard let commandQueue = device.makeCommandQueue() else {
            print("无法创建命令队列")
            return
        }
        self.commandQueue = commandQueue
        
        // 尝试初始化渲染管线
        _ = setupRenderPipeline()
        
        // 创建球体模型
        createSphereGeometry()
    }
    
    /// 使用MTKView初始化
    init(mtkView: MTKView) {
        super.init()
        
        // 设置Metal设备
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal不支持的设备")
            return
        }
        
        self.device = device
        mtkView.device = device
        
        // 创建命令队列
        guard let commandQueue = device.makeCommandQueue() else {
            print("无法创建命令队列")
            return
        }
        self.commandQueue = commandQueue
        
        // 尝试初始化渲染管线
        _ = setupRenderPipeline()
        
        // 创建球体模型
        createSphereGeometry()
    }
    
    // 加载纹理
    public func loadTextures() {
        print("EarthMetalRenderer.loadTextures: 开始加载纹理")
        
        // 检查设备和队列是否准备好
        if device == nil {
            print("无法加载纹理: Metal设备为nil")
            return
        }
        
        if MetalShaderManager.shared.device == nil {
            print("警告: MetalShaderManager设备为nil")
        }
        
        // 使用EarthTextureGenerator生成地球纹理
        print("生成地球表面纹理")
        if let earthTexture = EarthTextureGenerator.generateEarthTexture() {
            print("地球纹理生成成功，尺寸: \(earthTexture.size.width)x\(earthTexture.size.height)")
            self.earthTexture = MetalShaderManager.shared.createTexture(from: earthTexture)
            if self.earthTexture != nil {
                print("地球Metal纹理创建成功")
                self.earthTextureLoaded = true
            } else {
                print("地球Metal纹理创建失败")
            }
        } else {
            print("地球纹理生成失败")
        }
        
        // 生成夜间纹理
        print("生成夜间纹理")
        if let nightTexture = EarthTextureGenerator.generateNightTexture() {
            self.nightTexture = MetalShaderManager.shared.createTexture(from: nightTexture)
            if self.nightTexture == nil {
                print("夜间纹理创建失败")
            }
        }
        
        // 生成法线贴图
        print("生成法线贴图")
        if let normalMap = EarthTextureGenerator.generateNormalMap() {
            self.normalMapTexture = MetalShaderManager.shared.createTexture(from: normalMap)
            if self.normalMapTexture == nil {
                print("法线贴图创建失败")
            }
        }
        
        // 生成高光贴图
        print("生成高光贴图")
        if let specularMap = EarthTextureGenerator.generateSpecularMap() {
            self.specularMapTexture = MetalShaderManager.shared.createTexture(from: specularMap)
            if self.specularMapTexture == nil {
                print("高光贴图创建失败")
            }
        }
        
        // 记录纹理加载状态
        print("地球纹理加载状态: \(earthTextureLoaded)")
    }
    
    // 创建球体几何体
    private func createSphereGeometry() {
        // 创建一个高精度球体
        let radius: Float = 1.0
        let stacks: Int = 100
        let slices: Int = 100
        
        let vertexCount = (stacks + 1) * (slices + 1)
        let indexCount = stacks * slices * 6
        
        // 分配顶点缓冲区
        var vertices = [Float]()
        vertices.reserveCapacity(vertexCount * 8) // 位置(3) + 法线(3) + 纹理坐标(2) = 8
        
        // 创建顶点
        for stack in 0...stacks {
            let phi = Float.pi * Float(stack) / Float(stacks)
            let sinPhi = sin(phi)
            let cosPhi = cos(phi)
            
            for slice in 0...slices {
                let theta = 2.0 * Float.pi * Float(slice) / Float(slices)
                let sinTheta = sin(theta)
                let cosTheta = cos(theta)
                
                // 顶点位置
                let x = radius * sinPhi * cosTheta
                let y = radius * cosPhi
                let z = radius * sinPhi * sinTheta
                
                // 顶点法线 (归一化位置向量)
                let nx = sinPhi * cosTheta
                let ny = cosPhi
                let nz = sinPhi * sinTheta
                
                // 纹理坐标
                let s = 1.0 - Float(slice) / Float(slices)
                let t = 1.0 - Float(stack) / Float(stacks)
                
                // 添加顶点数据
                vertices.append(contentsOf: [x, y, z])      // 位置
                vertices.append(contentsOf: [nx, ny, nz])   // 法线
                vertices.append(contentsOf: [s, t])         // 纹理坐标
            }
        }
        
        // 创建索引
        var indices = [UInt32]()
        indices.reserveCapacity(indexCount)
        
        for stack in 0..<stacks {
            for slice in 0..<slices {
                let first = UInt32((stack * (slices + 1)) + slice)
                let second = UInt32(((stack + 1) * (slices + 1)) + slice)
                
                // 添加两个三角形 (一个四边形)
                indices.append(contentsOf: [first, second, first + 1])
                indices.append(contentsOf: [second, second + 1, first + 1])
            }
        }
        
        // 创建顶点缓冲区
        self.vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
        
        // 创建索引缓冲区
        self.indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt32>.size, options: [])
        self.indexCount = indices.count
    }
    
    // 设置渲染管线
    private func setupRenderPipeline() -> Bool {
        // 获取管道状态
        guard let pipelineState = MetalShaderManager.shared.earthRenderPipelineState else {
            return false
        }
        self.pipelineState = pipelineState
        return true
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 视图大小改变时的处理
    }
    
    func draw(in view: MTKView) {
        // 检查是否有可用的绘制区域
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // 创建命令缓冲区
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // 创建渲染命令编码器
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // 设置渲染状态
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // 设置视口和剪裁矩形
        let viewportSize = view.drawableSize
        let viewport = MTLViewport(
            originX: 0, originY: 0,
            width: Double(viewportSize.width),
            height: Double(viewportSize.height),
            znear: 0.0, zfar: 1.0
        )
        renderEncoder.setViewport(viewport)
        
        // 计算视图和投影矩阵
        let aspect = Float(viewportSize.width / viewportSize.height)
        let projectionMatrix = matrix_perspective_right_hand(
            fovyRadians: Float.pi / 3.0,
            aspectRatio: aspect,
            nearZ: 0.1,
            farZ: 100.0
        )
        
        // 设置相机位置
        let cameraPosition = SIMD3<Float>(0, 0, 3.0)
        let viewMatrix = matrix_look_at_right_hand(
            eye: cameraPosition,
            center: SIMD3<Float>(0, 0, 0),
            up: SIMD3<Float>(0, 1, 0)
        )
        
        // 更新统一变量
        updateUniforms(viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, cameraPosition: cameraPosition)
        
        // 创建和更新统一缓冲区
        let uniformsSize = MemoryLayout<Float>.size * 16 * 3 + MemoryLayout<Float>.size * 3 + MemoryLayout<Float>.size * 4
        guard let uniformBuffer = device.makeBuffer(length: uniformsSize, options: []) else {
            renderEncoder.endEncoding()
            return
        }
        
        var pointer = uniformBuffer.contents().bindMemory(to: Float.self, capacity: uniformsSize / MemoryLayout<Float>.size)
        
        // 复制矩阵数据
        let matrices: [matrix_float4x4] = [modelMatrix, viewMatrix, projectionMatrix]
        for matrix in matrices {
            for i in 0..<16 {
                pointer.pointee = matrix[i/4][i%4]
                pointer = pointer.advanced(by: 1)
            }
        }
        
        // 复制相机位置
        for i in 0..<3 {
            pointer.pointee = cameraPosition[i]
            pointer = pointer.advanced(by: 1)
        }
        
        // 渲染参数
        pointer.pointee = rotationX  // 时间
        pointer = pointer.advanced(by: 1)
        pointer.pointee = elevationScale  // 高程缩放
        pointer = pointer.advanced(by: 1)
        pointer.pointee = atmosphereDensity  // 大气密度
        pointer = pointer.advanced(by: 1)
        pointer.pointee = detailLevel  // 细节等级
        
        // 设置顶点和索引缓冲区
        if let vertexBuffer = vertexBuffer {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        }
        
        // 设置纹理
        if let earthTexture = earthTexture {
            renderEncoder.setFragmentTexture(earthTexture, index: 0)
            earthTextureLoaded = true
        } else {
            // 如果纹理不可用，使用备用的纯色球体
            print("使用备用的纯色地球渲染")
            
            // 创建一个简单的纯蓝色纹理作为地球颜色
            let width = 2
            let height = 2
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let rgbaData: [UInt8] = [0, 0, 200, 255, 0, 100, 200, 255, 0, 100, 200, 255, 0, 0, 200, 255]
            
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: width,
                height: height,
                mipmapped: false)
            
            if let fallbackTexture = device.makeTexture(descriptor: textureDescriptor) {
                let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                      size: MTLSize(width: width, height: height, depth: 1))
                
                fallbackTexture.replace(region: region,
                                       mipmapLevel: 0,
                                       withBytes: rgbaData,
                                       bytesPerRow: bytesPerRow)
                
                renderEncoder.setFragmentTexture(fallbackTexture, index: 0)
            }
            
            // 尝试重新加载纹理
            if !earthTextureLoaded {
                DispatchQueue.global().async {
                    self.loadTextures()
                }
            }
        }
        
        if let normalMapTexture = normalMapTexture {
            renderEncoder.setFragmentTexture(normalMapTexture, index: 1)
        }
        
        if let specularMapTexture = specularMapTexture {
            renderEncoder.setFragmentTexture(specularMapTexture, index: 2)
        }
        
        if let nightTexture = nightTexture {
            renderEncoder.setFragmentTexture(nightTexture, index: 3)
        }
        
        // 绘制球体
        if let indexBuffer = indexBuffer, indexCount > 0 {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0
            )
        }
        
        // 结束渲染并提交
        renderEncoder.endEncoding()
        
        // 提交并显示
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // 更新统一变量
    private func updateUniforms(viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4, cameraPosition: SIMD3<Float>) {
        // 更新模型旋转
        rotationX += rotationSpeed
        rotationY += rotationSpeed
        let rotationMatrix = matrix4x4_rotation(radians: rotationX, axis: SIMD3<Float>(0, 1, 0))
        modelMatrix = rotationMatrix
        
        // 创建统一变量缓冲区（如果尚未创建）
        let uniformsSize = MemoryLayout<Float>.size * 16 * 3 + MemoryLayout<Float>.size * 3 + MemoryLayout<Float>.size * 4
        let uniformBuffer = device.makeBuffer(length: uniformsSize, options: [])
        
        guard let buffer = uniformBuffer else { return }
        
        // 获取缓冲区指针
        var pointer = buffer.contents().bindMemory(to: Float.self, capacity: 16 * 3 + 3 + 4)
        
        // 复制矩阵数据
        let matrices: [matrix_float4x4] = [modelMatrix, viewMatrix, projectionMatrix]
        for matrix in matrices {
            for i in 0..<16 {
                pointer.pointee = matrix[i/4][i%4]
                pointer = pointer.advanced(by: 1)
            }
        }
        
        // 复制相机位置
        for i in 0..<3 {
            pointer.pointee = cameraPosition[i]
            pointer = pointer.advanced(by: 1)
        }
        
        // 时间
        pointer.pointee = rotationX
        pointer = pointer.advanced(by: 1)
        
        // 高程缩放
        pointer.pointee = elevationScale
        pointer = pointer.advanced(by: 1)
        
        // 大气密度
        pointer.pointee = atmosphereDensity
        pointer = pointer.advanced(by: 1)
        
        // 细节等级
        pointer.pointee = detailLevel
    }
    
    // 创建旋转矩阵
    private func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
        let normalizedAxis = normalize(axis)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z
        
        return matrix_float4x4(
            SIMD4<Float>(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
            SIMD4<Float>(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
            SIMD4<Float>(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    // 创建透视投影矩阵
    private func matrix_perspective_right_hand(fovyRadians: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        
        return matrix_float4x4(
            SIMD4<Float>(xs, 0, 0, 0),
            SIMD4<Float>(0, ys, 0, 0),
            SIMD4<Float>(0, 0, zs, -1),
            SIMD4<Float>(0, 0, nearZ * zs, 0)
        )
    }
    
    // 创建视图矩阵
    private func matrix_look_at_right_hand(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        
        let t = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))
        
        return matrix_float4x4(
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(t.x, t.y, t.z, 1)
        )
    }
} 