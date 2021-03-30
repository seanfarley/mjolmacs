// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edda",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(
            name: "edda",
            type: .dynamic,
            targets: ["edda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kentzo/ShortcutRecorder", from: "3.3.0"),
    ],
    targets: [
        .target(
            name: "edda",
            dependencies: ["ShortcutRecorder"]),
    ]
)
