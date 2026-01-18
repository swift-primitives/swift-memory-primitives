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
        .package(path: "../swift-darwin-primitives"),
        .package(path: "../swift-linux-primitives"),
        .package(path: "../swift-windows-primitives"),
    ],
    targets: [
        .target(
            name: "Memory Primitives",
            dependencies: [
                .product(name: "Darwin Primitives", package: "swift-darwin-primitives",
                         condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])),
                .product(name: "Darwin Memory Primitives", package: "swift-darwin-primitives",
                         condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])),
                .product(name: "Linux Primitives", package: "swift-linux-primitives",
                         condition: .when(platforms: [.linux])),
                .product(name: "Linux Memory Primitives", package: "swift-linux-primitives",
                         condition: .when(platforms: [.linux])),
                .product(name: "Windows Primitives", package: "swift-windows-primitives",
                         condition: .when(platforms: [.windows])),
                .product(name: "Windows Memory Primitives", package: "swift-windows-primitives",
                         condition: .when(platforms: [.windows])),
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
