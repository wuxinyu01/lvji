//
//  MetalShaderManager.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import Foundation
import Metal
import MetalKit

class MetalShaderManager {
    // Singleton实例
    static let shared = MetalShaderManager()
    
    // Metal设备
    private(set) var device: MTLDevice?
    
    // 着色器管道状态
    private(set) var earthRenderPipelineState: MTLRenderPipelineState?
    private(set) var fallbackPipelineState: MTLRenderPipelineState?
    
    // 资源库
    private var library: MTLLibrary?
    
    // 错误状态
    var lastError: Error?
    var isReady: Bool = false
    
    private init() {
        setupMetal()
    }
    
    private func setupMetal() {
        // 初始化Metal设备
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("无法创建Metal设备")
            return
        }
        self.device = device
        print("Metal设备已创建: \(device)")
        
        do {
            // 尝试加载自定义shader
            if loadCustomMetalShaders(fromFile: "EarthShaders") {
                print("已成功加载自定义着色器文件")
            } else {
                // 加载默认Metal库
                guard let library = device.makeDefaultLibrary() else {
                    print("无法加载默认Metal库")
                    throw NSError(domain: "MetalShaderManager", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "无法加载默认Metal库"
                    ])
                }
                self.library = library
                print("已加载默认Metal库")
            }
            
            guard let library = self.library else {
                print("Metal库未正确初始化")
                throw NSError(domain: "MetalShaderManager", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Metal库未正确初始化"
                ])
            }
            
            // 检查并打印所有可用函数名
            print("Metal库中的所有函数:")
            for functionName in library.functionNames {
                print("- \(functionName)")
            }
            
            // 加载着色器函数
            guard let vertexFunction = library.makeFunction(name: "earthVertexShader"),
                  let fragmentFunction = library.makeFunction(name: "earthFragmentShader") else {
                print("无法加载着色器函数")
                throw NSError(domain: "MetalShaderManager", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "无法加载着色器函数"
                ])
            }
            
            print("着色器函数加载成功")
            
            // 创建渲染管道描述
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            // 创建渲染管道状态
            earthRenderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
            // 加载备用着色器函数
            if let fallbackVertex = library.makeFunction(name: "earthVertexShaderFallback"),
               let fallbackFragment = library.makeFunction(name: "earthFragmentShaderFallback") {
                pipelineDescriptor.vertexFunction = fallbackVertex
                pipelineDescriptor.fragmentFunction = fallbackFragment
                fallbackPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("备用着色器函数加载成功")
            }
            
            isReady = true
            print("Metal着色器管道初始化成功")
        } catch {
            lastError = error
            print("Metal着色器初始化失败: \(error.localizedDescription)")
        }
    }
    
    // 加载自定义.metal文件
    func loadCustomMetalShaders(fromFile filename: String) -> Bool {
        guard let device = device else { return false }
        
        do {
            // 尝试从Bundle加载自定义Metal文件
            if let url = Bundle.main.url(forResource: filename, withExtension: "metal") {
                let source = try String(contentsOf: url)
                let library = try device.makeLibrary(source: source, options: nil)
                self.library = library
                print("成功加载自定义Metal着色器: \(filename)")
                return true
            }
            print("无法找到Metal文件: \(filename)")
            return false
        } catch {
            lastError = error
            print("加载自定义Metal着色器失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 创建Metal纹理
    func createTexture(from image: UIImage) -> MTLTexture? {
        guard let device = device,
              let cgImage = image.cgImage else {
            return nil
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        do {
            let texture = try textureLoader.newTexture(cgImage: cgImage, options: nil)
            return texture
        } catch {
            print("创建纹理失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 检查Metal是否可用
    static func isMetalSupported() -> Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
} 