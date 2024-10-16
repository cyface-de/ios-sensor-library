// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataCapturing",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DataCapturing",
            targets: ["DataCapturing"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // DataCompression Library to handle complicated ObjectiveC compression API.
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
        // Apple library to handle Protobuf conversion for transmitting files in the Protobuf format.
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DataCapturing",
            dependencies: [
                "DataCompression",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Sources"),
        .testTarget(
            name: "DataCapturingTests",
            dependencies: ["DataCapturing"],
            path: "Tests")
    ]
)
