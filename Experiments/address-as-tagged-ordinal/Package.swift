// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "address-as-tagged-ordinal",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../../../swift-ordinal-primitives"),
        .package(path: "../../../swift-cardinal-primitives"),
        .package(path: "../../../swift-affine-primitives"),
        .package(path: "../../../swift-identity-primitives"),
        .package(path: "../../../swift-index-primitives"),
    ],
    targets: [
        .executableTarget(
            name: "address-as-tagged-ordinal",
            dependencies: [
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
                .strictMemorySafety(),
            ]
        )
    ]
)
