// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edda",
    products: [
        .library(
            name: "edda",
            type: .dynamic,
            targets: ["edda"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "edda",
            dependencies: []),
    ]
)
