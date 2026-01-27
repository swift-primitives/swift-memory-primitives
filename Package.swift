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
    ],
    dependencies: [
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-range-primitives"),
        .package(path: "../swift-property-primitives"),
    ],
    targets: [
        .target(
            name: "Memory Primitives",
            dependencies: [
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
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
