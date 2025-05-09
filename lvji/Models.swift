//
//  Models.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import Foundation
import CoreLocation

// 注意：本文件中的数据模型与Models/EarthModels.swift中定义的模型存在命名冲突
// 请在导入时使用明确的模块名以避免歧义

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var email: String
    var friends: [String]
    var photos: [String] // 关联照片ID
    var createdAt: Date
}

struct Photo: Identifiable, Codable {
    var id: String
    var userId: String
    var imageUrl: String
    var thumbnailUrl: String
    var location: GeoCoordinate
    var caption: String?
    var timestamp: Date
    var visibility: PhotoVisibility
    var sharedWith: [String] // 好友ID列表
    
    // 添加编码解码方法
    enum CodingKeys: String, CodingKey {
        case id, userId, imageUrl, thumbnailUrl, location, caption, timestamp, visibility, sharedWith
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(location, forKey: .location)
        try container.encode(caption, forKey: .caption)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(visibility, forKey: .visibility)
        try container.encode(sharedWith, forKey: .sharedWith)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        location = try container.decode(GeoCoordinate.self, forKey: .location)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        visibility = try container.decode(PhotoVisibility.self, forKey: .visibility)
        sharedWith = try container.decode([String].self, forKey: .sharedWith)
    }
}

// 注意：此结构与Models/EarthModels.swift中的GeoCoordinate存在命名冲突
// 此版本不包含altitude属性
struct GeoCoordinate: Codable {
    var latitude: Double
    var longitude: Double
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum PhotoVisibility: String, Codable {
    case `private`
    case friends
    case `public`
}

struct Route: Identifiable, Codable {
    var id: String
    var userA: String
    var userB: String
    var path: [GeoCoordinate] // 路线坐标点
    var isVisible: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 添加编码解码方法
    enum CodingKeys: String, CodingKey {
        case id, userA, userB, path, isVisible, createdAt, updatedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userA, forKey: .userA)
        try container.encode(userB, forKey: .userB)
        try container.encode(path, forKey: .path)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userA = try container.decode(String.self, forKey: .userA)
        userB = try container.decode(String.self, forKey: .userB)
        path = try container.decode([GeoCoordinate].self, forKey: .path)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// Helper extension to convert CLLocationCoordinate2D to GeoCoordinate
extension CLLocationCoordinate2D {
    func toGeoCoordinate() -> GeoCoordinate {
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }
} 