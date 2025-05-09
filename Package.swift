// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "lvji",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "lvji",
            targets: ["lvji"]),
    ],
    dependencies: [
        // 暂时不添加Firebase依赖，等问题解决后再添加
    ],
    targets: [
        .target(
            name: "lvji",
            dependencies: []),
        .testTarget(
            name: "lvjiTests",
            dependencies: ["lvji"]),
    ]
) 