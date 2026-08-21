// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-memory-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
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
            name: "Memory Shift Primitives",
            targets: ["Memory Shift Primitives"]
        ),
        .library(
            name: "Memory Region Primitives",
            targets: ["Memory Region Primitives"]
        ),
        .library(
            name: "Memory Primitives Test Support",
            targets: ["Memory Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-ordinal-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-cardinal-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-carrier-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-affine-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-tagged-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-bit-index-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-span-primitives.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Memory Primitive",
            dependencies: []
        ),

        .target(
            name: "Memory Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Primitives Standard Library Integration"),
                .target(name: "Memory Address Primitives"),
                .target(name: "Memory Alignment Primitives"),
                .target(name: "Memory Shift Primitives"),
                .target(name: "Memory Region Primitives"),
            ]
        ),

        .target(
            name: "Memory Primitives Standard Library Integration",
            dependencies: [
                .target(name: "Memory Address Primitives"),
                .target(name: "Memory Alignment Primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
            ]
        ),

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

        .target(
            name: "Memory Shift Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .product(name: "Bit Index Primitives", package: "swift-bit-index-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),

        .target(
            name: "Memory Alignment Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Shift Primitives"),
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),

        .target(
            name: "Memory Region Primitives",
            dependencies: [
                .target(name: "Memory Primitive"),
                .target(name: "Memory Address Primitives"),
            ]
        ),

        .target(
            name: "Memory Primitives Test Support",
            dependencies: [
                "Memory Primitives",
                .product(
                    name: "Tagged Primitives Test Support",
                    package: "swift-tagged-primitives"
                ),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(
                    name: "Ordinal Primitives Test Support",
                    package: "swift-ordinal-primitives"
                ),
                .product(
                    name: "Cardinal Primitives Test Support",
                    package: "swift-cardinal-primitives"
                ),
                .product(
                    name: "Affine Primitives Test Support",
                    package: "swift-affine-primitives"
                ),
            ],
            path: "Tests/Support"
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("RawLayout")
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
