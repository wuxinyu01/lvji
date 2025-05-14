//
//  ViewImports.swift
//  lvji
//
//  Created on 2025/5/14
//

import SwiftUI

// 这个文件用于确保所有视图类型的可见性和导入
// 通过在这里导入和重新导出视图类型，可以避免类型重复声明的问题

// MARK: - 导出主要视图
// 如果需要，可以在这里添加条件编译，以处理不同平台或配置

// 注意：不要在这里使用typealias，因为这可能导致循环引用
// 相反，直接导入必要的模块或文件

// 导入必要的工具类型
@_exported import MapKit
@_exported import CoreLocation

// 这只是一个标记，表示此文件的目的是作为视图导入的集中点
struct ViewImportMarker {} 