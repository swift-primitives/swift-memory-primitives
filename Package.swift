// swift-tools-version: 6.3.1

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
            name: "Memory Namespace",
            targets: ["Memory Namespace"]
        ),
        .library(
            name: "Memory Primitives",
            targets: ["Memory Primitives"]
        ),
        .library(
            name: "Memory Primitives Core",
            targets: ["Memory Primitives Core"]
        ),
        .library(
            name: "Memory Primitives Standard Library Integration",
            targets: ["Memory Primitives Standard Library Integration"]
        ),
        .library(
            name: "Memory Arena Primitives",
            targets: ["Memory Arena Primitives"]
        ),
        .library(
            name: "Memory Buffer Primitives",
            targets: ["Memory Buffer Primitives"]
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
        .package(path: "../swift-tagged-primitives"),
        .package(path: "../swift-property-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-bit-primitives"),
        .package(path: "../swift-bit-vector-primitives"),
        .package(path: "../swift-vector-primitives"),
    ],
    targets: [

        // MARK: - Namespace
        .target(
            name: "Memory Namespace",
            dependencies: []
        ),

        // MARK: - Umbrella
        .target(
            name: "Memory Primitives",
            dependencies: [
                .target(name: "Memory Namespace"),
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .target(name: "Memory Buffer Primitives"),
                .target(name: "Memory Arena Primitives"),
                .target(name: "Memory Pool Primitives"),
            ]
        ),

        // MARK: - StdLib Integration
        .target(
            name: "Memory Primitives Standard Library Integration",
            dependencies: [
                .target(name: "Memory Primitives Core"),
            ]
        ),

        // MARK: - Core
        .target(
            name: "Memory Primitives Core",
            dependencies: [
                .target(name: "Memory Namespace"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Arena
        .target(
            name: "Memory Arena Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
            ]
        ),

        // MARK: - Buffer
        .target(
            name: "Memory Buffer Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
            ]
        ),

        // MARK: - Pool
        .target(
            name: "Memory Pool Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .product(name: "Bit Vector Primitives Core", package: "swift-bit-vector-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Memory Primitives Test Support",
            dependencies: [
                "Memory Primitives",
                .product(name: "Tagged Primitives Test Support", package: "swift-tagged-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Ordinal Primitives Test Support", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives Test Support", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives Test Support", package: "swift-affine-primitives"),
                .product(name: "Vector Primitives Test Support", package: "swift-vector-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
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
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
