// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataCapturing",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DataCapturing",
            targets: ["DataCapturing"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // DataCompression Library to handle complicated ObjectiveC compression API.
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
        // Apple library to handle Protobuf conversion for transmitting files in the Protobuf format.
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
        // Library for handling OAuth Login Process
        .package(url: "https://github.com/openid/AppAuth-iOS.git", .upToNextMajor(from: "1.7.5")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DataCapturing",
            dependencies: [
                .product(name: "DataCompression", package: "DataCompression"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "AppAuth", package: "AppAuth-iOS"),
            ],
            // path: "Sources",
            resources: [
                .process("Persistence/Migration/V3toV4/V3toV4.xcmappingmodel"),
                .process("Model/CyfaceModel.xcdatamodeld"),
                .process("Persistence/Migration/V10toV11/V10toV11.xcmappingmodel"),
                .process("Persistence/Migration/V7toV8/V7toV8.xcmappingmodel"),
            ]
        ),
        .testTarget(
            name: "DataCapturingTests",
            dependencies: ["DataCapturing"],
            //path: "Tests",
            exclude: ["Resources/README.md"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
