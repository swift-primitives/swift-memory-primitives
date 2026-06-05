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
            name: "Memory Primitive",
            targets: ["Memory Primitive"]
        ),
        .library(
            name: "Memory Primitives",
            targets: ["Memory Primitives"]
        ),
        .library(
            name: "Memory Primitives Standard Library Integration",
            targets: ["Memory Primitives Standard Library Integration"]
        ),
        .library(
            name: "Memory Address Primitives",
            targets: ["Memory Address Primitives"]
        ),
        .library(
            name: "Memory Alignment Primitives",
            targets: ["Memory Alignment Primitives"]
        ),
        .library(
            name: "Memory Allocation Primitives",
            targets: ["Memory Allocation Primitives"]
        ),
        .library(
            name: "Memory Contiguous Primitives",
            targets: ["Memory Contiguous Primitives"]
        ),
        .library(
            name: "Memory Shift Primitives",
            targets: ["Memory Shift Primitives"]
        ),
        .library(
            name: "Memory Tracked Primitives",
            targets: ["Memory Tracked Primitives"]
        ),
        .library(
            name: "Memory Allocatable Primitives",
            targets: ["Memory Allocatable Primitives"]
        ),
        .library(
            name: "Memory Unique Primitives",
            targets: ["Memory Unique Primitives"]
        ),
        .library(
            name: "Memory Primitives Test Support",
            targets: ["Memory Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-ordinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-cardinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-affine-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-store-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Namespace
        .target(
            name: "Memory Primitive",
            dependencies: []
        ),

        // MARK: - Umbrella
        .target(
            name: "Memory Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .target(name: "Memory Address Primitives"),
                .target(name: "Memory Alignment Primitives"),
                .target(name: "Memory Allocation Primitives"),
                .target(name: "Memory Contiguous Primitives"),
                .target(name: "Memory Shift Primitives"),
                .target(name: "Memory Tracked Primitives"),
                .target(name: "Memory Allocatable Primitives"),
                .target(name: "Memory Unique Primitives"),
            ]
        ),

        // MARK: - StdLib Integration
        .target(
            name: "Memory Primitives Standard Library Integration",
            dependencies: [
                .target(name: "Memory Address Primitives"),
                .target(name: "Memory Alignment Primitives"),
                .target(name: "Memory Contiguous Primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
            ]
        ),

        // MARK: - Address
        .target(
            name: "Memory Address Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Shift
        .target(
            name: "Memory Shift Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .product(name: "Bit Index Primitives", package: "swift-bit-index-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),

        // MARK: - Alignment
        .target(
            name: "Memory Alignment Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Shift Primitives"),
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),

        // MARK: - Allocation
        .target(
            name: "Memory Allocation Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Address Primitives"),
                .target(name: "Memory Alignment Primitives"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Contiguous
        .target(
            name: "Memory Contiguous Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
            ]
        ),

        // MARK: - Tracked (ledger seam — narrow Store.Tracked replacement, leaf-tier)
        .target(
            name: "Memory Tracked Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Store Protocol Primitives", package: "swift-store-primitives"),
                .product(name: "Store Initialization Primitives", package: "swift-store-primitives"),
            ]
        ),

        // MARK: - Allocatable (create + bulk relocate — narrow Store.Creatable replacement)
        .target(
            name: "Memory Allocatable Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Tracked Primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Store Protocol Primitives", package: "swift-store-primitives"),
                .product(name: "Store Initialization Primitives", package: "swift-store-primitives"),
            ]
        ),

        // MARK: - Unique (copy-on-write capability — sharing leaves only)
        .target(
            name: "Memory Unique Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
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
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
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
