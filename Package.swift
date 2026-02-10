// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-memory-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Memory Primitives",
            targets: ["Memory Primitives"]
        ),
        .library(
            name: "Memory Primitives Core",
            targets: ["Memory Primitives Core"]
        ),
        .library(
            name: "Memory Arena Primitives",
            targets: ["Memory Arena Primitives"]
        ),
        .library(
            name: "Memory Pool Primitives",
            targets: ["Memory Pool Primitives"]
        ),
        .library(
            name: "Memory Primitives Test Support",
            targets: ["Memory Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-cardinal-primitives"),
        .package(path: "../swift-affine-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-vector-primitives"),
        .package(path: "../swift-property-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-bit-vector-primitives"),
    ],
    targets: [
        .target(
            name: "Memory Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .target(name: "Memory Arena Primitives"),
                .target(name: "Memory Pool Primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),
        .target(
            name: "Memory Primitives Standard Library Integration",
            dependencies: [
                .target(name: "Memory Primitives Core"),
            ]
        ),
        .target(
            name: "Memory Primitives Core",
            dependencies: [
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),
        .target(
            name: "Memory Arena Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
            ]
        ),
        .target(
            name: "Memory Pool Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
            ]
        ),
        .target(
            name: "Memory Primitives Test Support",
            dependencies: [
                "Memory Primitives",
                .product(name: "Identity Primitives Test Support", package: "swift-identity-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Vector Primitives Test Support", package: "swift-vector-primitives"),
                .product(name: "Ordinal Primitives Test Support", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives Test Support", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives Test Support", package: "swift-affine-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Memory Arena Primitives Tests",
            dependencies: [
                "Memory Primitives",
                "Memory Primitives Test Support",
            ]
        ),
        .testTarget(
            name: "Memory Pool Primitives Tests",
            dependencies: [
                "Memory Primitives",
                "Memory Primitives Test Support",
            ]
        ),
        .testTarget(
            name: "Memory Primitives Tests",
            dependencies: [
                "Memory Primitives",
                "Memory Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety(),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
