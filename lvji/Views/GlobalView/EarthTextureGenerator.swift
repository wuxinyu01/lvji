//
//  EarthTextureGenerator.swift
//  lvji
//
//  Created on 2025/5/8.
//

import Foundation
import UIKit

/// 地球纹理生成器
/// 生成高质量地球纹理贴图
class EarthTextureGenerator {
    
    // 纹理尺寸
    private static let textureSize = CGSize(width: 2048, height: 1024)
    
    /// 生成地球表面纹理
    /// - Returns: 地球表面纹理
    static func generateEarthTexture() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(textureSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制背景（更深的海洋）
        let oceanColor = UIColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1.0)
        context.setFillColor(oceanColor.cgColor)
        context.fill(CGRect(origin: .zero, size: textureSize))
        
        // 添加海洋渐变效果
        addOceanGradients(in: context)
        
        // 绘制大陆（更增强的颜色）
        drawContinents(in: context)
        
        // 添加大陆细节
        addContinentDetails(in: context)
        
        // 绘制海岸线（更明显）
        drawCoastlines(in: context)
        
        // 绘制少量云层（更淡）
        drawClouds(in: context)
        
        // 添加极地冰盖
        drawPolarIceCaps(in: context)
        
        // 获取生成的图像
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 生成夜间地球纹理（城市灯光）
    /// - Returns: 夜间纹理
    static func generateNightTexture() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(textureSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制黑色背景
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: textureSize))
        
        // 绘制城市灯光
        drawCityLights(in: context)
        
        // 获取生成的图像
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 生成地球法线贴图
    /// - Returns: 法线贴图
    static func generateNormalMap() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(textureSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制基础法线（平坦海洋）
        let baseNormalColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
        context.setFillColor(baseNormalColor.cgColor)
        context.fill(CGRect(origin: .zero, size: textureSize))
        
        // 绘制大陆法线（凹凸效果）
        drawContinentNormals(in: context)
        
        // 获取生成的图像
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 生成地球高光贴图
    /// - Returns: 高光贴图
    static func generateSpecularMap() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(textureSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制基础高光（海洋较为反光）
        let oceanSpecular = UIColor(white: 0.8, alpha: 1.0)
        context.setFillColor(oceanSpecular.cgColor)
        context.fill(CGRect(origin: .zero, size: textureSize))
        
        // 绘制大陆高光（大陆较少反光）
        drawContinentSpecular(in: context)
        
        // 获取生成的图像
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - 私有辅助方法
    
    /// 添加海洋渐变效果
    private static func addOceanGradients(in context: CGContext) {
        context.saveGState()
        
        // 从深蓝到浅蓝的渐变
        let colors = [
            UIColor(red: 0.0, green: 0.1, blue: 0.5, alpha: 0.3).cgColor,
            UIColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 0.3).cgColor
        ]
        
        // 创建水平渐变
        let horizontalGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray,
                                  locations: [0.0, 1.0])!
        
        // 绘制几个随机渐变区域
        for _ in 0..<5 {
            let x = CGFloat.random(in: 0..<textureSize.width)
            let y = CGFloat.random(in: 0..<textureSize.height)
            let width = CGFloat.random(in: 300..<600)
            let height = CGFloat.random(in: 200..<400)
            
            context.drawLinearGradient(horizontalGradient,
                                     start: CGPoint(x: x, y: y),
                                     end: CGPoint(x: x + width, y: y + height),
                                     options: [])
        }
        
        context.restoreGState()
    }
    
    /// 添加大陆细节
    private static func addContinentDetails(in context: CGContext) {
        context.saveGState()
        
        // 添加山脉和地形变化
        let mountainColor = UIColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 0.4)
        context.setFillColor(mountainColor.cgColor)
        
        // 喜马拉雅山脉
        let himalayasPath = UIBezierPath()
        himalayasPath.move(to: CGPoint(x: textureSize.width * 0.7, y: textureSize.height * 0.4))
        himalayasPath.addLine(to: CGPoint(x: textureSize.width * 0.73, y: textureSize.height * 0.38))
        himalayasPath.addLine(to: CGPoint(x: textureSize.width * 0.75, y: textureSize.height * 0.4))
        himalayasPath.close()
        context.addPath(himalayasPath.cgPath)
        context.fillPath()
        
        // 安第斯山脉
        let andesPath = UIBezierPath()
        andesPath.move(to: CGPoint(x: textureSize.width * 0.25, y: textureSize.height * 0.5))
        andesPath.addLine(to: CGPoint(x: textureSize.width * 0.27, y: textureSize.height * 0.6))
        andesPath.addLine(to: CGPoint(x: textureSize.width * 0.24, y: textureSize.height * 0.63))
        andesPath.close()
        context.addPath(andesPath.cgPath)
        context.fillPath()
        
        // 洛基山脉
        let rockiesPath = UIBezierPath()
        rockiesPath.move(to: CGPoint(x: textureSize.width * 0.15, y: textureSize.height * 0.35))
        rockiesPath.addLine(to: CGPoint(x: textureSize.width * 0.17, y: textureSize.height * 0.38))
        rockiesPath.addLine(to: CGPoint(x: textureSize.width * 0.14, y: textureSize.height * 0.40))
        rockiesPath.close()
        context.addPath(rockiesPath.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    /// 绘制极地冰盖
    private static func drawPolarIceCaps(in context: CGContext) {
        context.saveGState()
        
        // 设置冰盖颜色
        context.setFillColor(UIColor(white: 0.95, alpha: 0.8).cgColor)
        
        // 北极冰盖
        let northPolarPath = UIBezierPath(ovalIn: CGRect(
            x: 0,
            y: 0,
            width: textureSize.width,
            height: textureSize.height * 0.2))
        context.addPath(northPolarPath.cgPath)
        context.fillPath()
        
        // 南极冰盖
        let southPolarPath = UIBezierPath(ovalIn: CGRect(
            x: 0,
            y: textureSize.height * 0.8,
            width: textureSize.width,
            height: textureSize.height * 0.2))
        context.addPath(southPolarPath.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    /// 绘制大陆
    private static func drawContinents(in context: CGContext) {
        // 北美洲
        drawContinent(in: context, 
                    color: UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0),
                    points: getNorthAmericaPoints())
        
        // 南美洲
        drawContinent(in: context, 
                    color: UIColor(red: 0.3, green: 0.8, blue: 0.2, alpha: 1.0),
                    points: getSouthAmericaPoints())
        
        // 欧洲
        drawContinent(in: context, 
                    color: UIColor(red: 0.4, green: 0.75, blue: 0.25, alpha: 1.0),
                    points: getEuropePoints())
        
        // 亚洲
        drawContinent(in: context, 
                    color: UIColor(red: 0.25, green: 0.7, blue: 0.25, alpha: 1.0),
                    points: getAsiaPoints())
        
        // 非洲
        drawContinent(in: context, 
                    color: UIColor(red: 0.85, green: 0.75, blue: 0.35, alpha: 1.0),
                    points: getAfricaPoints())
        
        // 澳大利亚
        drawContinent(in: context, 
                    color: UIColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0),
                    points: getAustraliaPoints())
        
        // 南极洲
        drawContinent(in: context, 
                    color: UIColor.white,
                    points: getAntarcticaPoints())
    }
    
    /// 绘制云层
    private static func drawClouds(in context: CGContext) {
        context.saveGState()
        
        // 设置透明度
        context.setAlpha(0.3)
        
        // 绘制随机云团
        let cloudColor = UIColor.white
        context.setFillColor(cloudColor.cgColor)
        
        for _ in 0..<20 {
            let x = CGFloat.random(in: 0..<textureSize.width)
            let y = CGFloat.random(in: 0..<textureSize.height)
            let width = CGFloat.random(in: 50..<200)
            let height = CGFloat.random(in: 30..<100)
            
            // 创建云朵路径
            let cloudPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: width, height: height))
            
            // 添加几个小圆形来创建云朵效果
            for _ in 0..<5 {
                let offsetX = CGFloat.random(in: -width/4..<width/4)
                let offsetY = CGFloat.random(in: -height/4..<height/4)
                let smallWidth = CGFloat.random(in: width/3..<width/2)
                let smallHeight = CGFloat.random(in: height/3..<height/2)
                
                let smallCloudPath = UIBezierPath(ovalIn: CGRect(
                    x: x + width/2 + offsetX - smallWidth/2,
                    y: y + height/2 + offsetY - smallHeight/2,
                    width: smallWidth,
                    height: smallHeight))
                
                cloudPath.append(smallCloudPath)
            }
            
            context.addPath(cloudPath.cgPath)
            context.fillPath()
        }
        
        context.restoreGState()
    }
    
    /// 绘制海岸线
    private static func drawCoastlines(in context: CGContext) {
        context.saveGState()
        
        // 设置海岸线颜色和宽度
        context.setStrokeColor(UIColor(white: 0.9, alpha: 0.7).cgColor)
        context.setLineWidth(3.0)
        
        // 为每个大陆绘制海岸线
        drawCoastline(in: context, points: getNorthAmericaPoints())
        drawCoastline(in: context, points: getSouthAmericaPoints())
        drawCoastline(in: context, points: getEuropePoints())
        drawCoastline(in: context, points: getAsiaPoints())
        drawCoastline(in: context, points: getAfricaPoints())
        drawCoastline(in: context, points: getAustraliaPoints())
        drawCoastline(in: context, points: getAntarcticaPoints())
        
        context.restoreGState()
    }
    
    /// 绘制城市灯光
    private static func drawCityLights(in context: CGContext) {
        context.saveGState()
        
        // 城市灯光颜色
        let lightColor = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        context.setFillColor(lightColor.cgColor)
        
        // 大城市的位置 (x/width, y/height)
        let cities: [(CGFloat, CGFloat, CGFloat)] = [
            (0.29, 0.36, 6.0),  // 纽约
            (0.22, 0.38, 5.0),  // 洛杉矶
            (0.54, 0.33, 6.0),  // 伦敦
            (0.56, 0.33, 5.0),  // 巴黎
            (0.70, 0.38, 7.0),  // 东京
            (0.68, 0.35, 6.0),  // 北京
            (0.67, 0.43, 5.0),  // 孟买
            (0.57, 0.49, 4.0),  // 开罗
            (0.26, 0.55, 4.0),  // 圣保罗
            (0.77, 0.66, 3.0)   // 悉尼
        ]
        
        // 绘制城市灯光
        for city in cities {
            let x = city.0 * textureSize.width
            let y = city.1 * textureSize.height
            let radius = city.2
            
            // 创建辉光效果
            for i in 0..<5 {
                let alpha = 1.0 - Double(i) / 5.0
                let currentRadius = radius * CGFloat(1 + i * 2)
                
                context.setAlpha(CGFloat(alpha))
                context.setFillColor(lightColor.withAlphaComponent(CGFloat(alpha)).cgColor)
                
                let rect = CGRect(
                    x: x - currentRadius/2,
                    y: y - currentRadius/2,
                    width: currentRadius,
                    height: currentRadius)
                
                context.fillEllipse(in: rect)
            }
        }
        
        // 随机小城市
        for _ in 0..<200 {
            let x = CGFloat.random(in: 0..<textureSize.width)
            let y = CGFloat.random(in: 0..<textureSize.height)
            let radius = CGFloat.random(in: 1..<3)
            let alpha = CGFloat.random(in: 0.3...1.0)
            
            context.setAlpha(CGFloat(alpha))
            context.setFillColor(lightColor.withAlphaComponent(alpha).cgColor)
            
            let rect = CGRect(
                x: x - radius/2,
                y: y - radius/2,
                width: radius,
                height: radius)
            
            context.fillEllipse(in: rect)
        }
        
        context.restoreGState()
    }
    
    /// 绘制大陆法线
    private static func drawContinentNormals(in context: CGContext) {
        context.saveGState()
        
        // 设置大陆法线颜色（略微隆起）
        let continentNormalColor = UIColor(red: 0.65, green: 0.65, blue: 1.0, alpha: 1.0)
        context.setFillColor(continentNormalColor.cgColor)
        
        // 为每个大陆创建路径
        let continentPath = UIBezierPath()
        
        addPathForPoints(getNorthAmericaPoints(), to: continentPath)
        addPathForPoints(getSouthAmericaPoints(), to: continentPath)
        addPathForPoints(getEuropePoints(), to: continentPath)
        addPathForPoints(getAsiaPoints(), to: continentPath)
        addPathForPoints(getAfricaPoints(), to: continentPath)
        addPathForPoints(getAustraliaPoints(), to: continentPath)
        addPathForPoints(getAntarcticaPoints(), to: continentPath)
        
        context.addPath(continentPath.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    /// 绘制大陆高光效果
    private static func drawContinentSpecular(in context: CGContext) {
        context.saveGState()
        
        // 设置大陆高光颜色（不太反光）
        let continentSpecularColor = UIColor(white: 0.2, alpha: 1.0)
        context.setFillColor(continentSpecularColor.cgColor)
        
        // 为每个大陆创建路径
        let continentPath = UIBezierPath()
        
        addPathForPoints(getNorthAmericaPoints(), to: continentPath)
        addPathForPoints(getSouthAmericaPoints(), to: continentPath)
        addPathForPoints(getEuropePoints(), to: continentPath)
        addPathForPoints(getAsiaPoints(), to: continentPath)
        addPathForPoints(getAfricaPoints(), to: continentPath)
        addPathForPoints(getAustraliaPoints(), to: continentPath)
        addPathForPoints(getAntarcticaPoints(), to: continentPath)
        
        context.addPath(continentPath.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    /// 绘制单个大陆
    private static func drawContinent(in context: CGContext, color: UIColor, points: [(CGFloat, CGFloat)]) {
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        
        let path = UIBezierPath()
        if let firstPoint = points.first {
            path.move(to: CGPoint(
                x: firstPoint.0 * textureSize.width,
                y: firstPoint.1 * textureSize.height))
            
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(
                    x: point.0 * textureSize.width,
                    y: point.1 * textureSize.height))
            }
            
            path.close()
        }
        
        context.addPath(path.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    /// 绘制海岸线
    private static func drawCoastline(in context: CGContext, points: [(CGFloat, CGFloat)]) {
        let path = UIBezierPath()
        if let firstPoint = points.first {
            path.move(to: CGPoint(
                x: firstPoint.0 * textureSize.width,
                y: firstPoint.1 * textureSize.height))
            
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(
                    x: point.0 * textureSize.width,
                    y: point.1 * textureSize.height))
            }
            
            path.close()
        }
        
        context.addPath(path.cgPath)
        context.strokePath()
    }
    
    /// 将点添加到路径
    private static func addPathForPoints(_ points: [(CGFloat, CGFloat)], to path: UIBezierPath) {
        guard let firstPoint = points.first else { return }
        
        let startPath = UIBezierPath()
        startPath.move(to: CGPoint(
            x: firstPoint.0 * textureSize.width,
            y: firstPoint.1 * textureSize.height))
        
        for point in points.dropFirst() {
            startPath.addLine(to: CGPoint(
                x: point.0 * textureSize.width,
                y: point.1 * textureSize.height))
        }
        
        startPath.close()
        path.append(startPath)
    }
    
    // MARK: - 大陆轮廓数据
    
    // 以下方法返回简化的大陆轮廓点
    // 每个点为相对于纹理大小的比例 (x/width, y/height)
    
    private static func getNorthAmericaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.15, 0.30), (0.18, 0.25), (0.22, 0.22), (0.25, 0.25),
            (0.28, 0.28), (0.30, 0.32), (0.32, 0.35), (0.30, 0.40),
            (0.27, 0.43), (0.25, 0.46), (0.22, 0.47), (0.20, 0.45),
            (0.18, 0.42), (0.16, 0.38), (0.14, 0.35), (0.15, 0.30)
        ]
    }
    
    private static func getSouthAmericaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.27, 0.48), (0.30, 0.50), (0.32, 0.55), (0.31, 0.60),
            (0.28, 0.65), (0.26, 0.70), (0.24, 0.67), (0.23, 0.64),
            (0.22, 0.60), (0.23, 0.55), (0.25, 0.50), (0.27, 0.48)
        ]
    }
    
    private static func getEuropePoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.50, 0.27), (0.53, 0.25), (0.56, 0.27), (0.58, 0.30),
            (0.56, 0.33), (0.54, 0.35), (0.52, 0.37), (0.50, 0.35),
            (0.48, 0.33), (0.47, 0.30), (0.50, 0.27)
        ]
    }
    
    private static func getAsiaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.58, 0.27), (0.63, 0.25), (0.70, 0.27), (0.75, 0.30),
            (0.80, 0.35), (0.77, 0.40), (0.73, 0.45), (0.68, 0.47),
            (0.65, 0.45), (0.62, 0.42), (0.60, 0.38), (0.58, 0.35),
            (0.56, 0.33), (0.58, 0.30), (0.58, 0.27)
        ]
    }
    
    private static func getAfricaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.50, 0.37), (0.54, 0.40), (0.58, 0.43), (0.56, 0.47),
            (0.54, 0.53), (0.52, 0.58), (0.49, 0.60), (0.46, 0.57),
            (0.44, 0.53), (0.46, 0.48), (0.48, 0.44), (0.47, 0.40),
            (0.50, 0.37)
        ]
    }
    
    private static func getAustraliaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.78, 0.55), (0.82, 0.57), (0.85, 0.60), (0.83, 0.63),
            (0.80, 0.65), (0.77, 0.64), (0.75, 0.62), (0.76, 0.58),
            (0.78, 0.55)
        ]
    }
    
    private static func getAntarcticaPoints() -> [(CGFloat, CGFloat)] {
        return [
            (0.30, 0.85), (0.40, 0.87), (0.50, 0.88), (0.60, 0.87),
            (0.70, 0.85), (0.65, 0.83), (0.55, 0.82), (0.45, 0.82),
            (0.35, 0.83), (0.30, 0.85)
        ]
    }
} 