// swift-tools-version: 6.0
// Tools version 6.0 compiles the target in the Swift 6 language mode.

import PackageDescription

let package = Package(
    name: "daylight_camera",
    platforms: [
        // iOS 18.0 (REQ-CAMERA-2026-001-063): every API this plugin uses that
        // iOS 18.0 or earlier introduced is called without an availability check.
        .iOS(.v18)
    ],
    products: [
        .library(name: "daylight-camera", targets: ["daylight_camera"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "daylight_camera",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
