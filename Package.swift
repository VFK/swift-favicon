// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-favicon",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Favicon",
            targets: ["Favicon"]),
    ],
    targets: [
        .target(
            name: "Favicon",
            dependencies: []),
        .testTarget(
            name: "FaviconTests",
            dependencies: ["Favicon"]),
    ]
)
