// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "testing",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../../swift-foundations/swift-testing"),
    ],
    targets: [
        .testTarget(
            name: "Memory Pool Performance Tests",
            dependencies: [
                .product(name: "Memory Pool Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
        .testTarget(
            name: "Memory Arena Performance Tests",
            dependencies: [
                .product(name: "Memory Arena Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
        .testTarget(
            name: "Memory Alignment Performance Tests",
            dependencies: [
                .product(name: "Memory Primitives Core", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
                .product(name: "Testing", package: "swift-testing"),
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
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
