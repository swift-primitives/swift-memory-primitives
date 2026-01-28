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
            name: "Memory Primitives Test Support",
            targets: ["Memory Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-cardinal-primitives"),
        .package(path: "../swift-affine-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-range-primitives"),
        .package(path: "../swift-property-primitives"),
    ],
    targets: [
        .target(
            name: "Memory Primitives",
            dependencies: [
                .target(name: "Memory Primitives Core"),
                .target(name: "Memory Primitives Standard Library Integration"),
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
                .product(name: "Range Primitives", package: "swift-range-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),
        .target(
            name: "Memory Primitives Test Support",
            dependencies: [
                "Memory Primitives",
                .product(name: "Identity Primitives Test Support", package: "swift-identity-primitives"),
                .product(name: "Ordinal Primitives Test Support", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives Test Support", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives Test Support", package: "swift-affine-primitives"),
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
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety(),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
