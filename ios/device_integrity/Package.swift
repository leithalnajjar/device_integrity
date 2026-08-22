// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "device_integrity",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "device-integrity", targets: ["device_integrity"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "device_integrity",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("DeviceCheck")
            ]
        )
    ]
)
