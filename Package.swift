// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FlightUI",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "FlightUI",
            targets: ["FlightUI"])
    ],
    dependencies: [
        .package(path: "../../danleedham/AviationMaths")
    ],
    targets: [
        .target(
            name: "FlightUI",
            dependencies: [
                .product(name: "AviationMaths", package: "AviationMaths")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FlightUITests",
            dependencies: [
                "FlightUI"
            ]
        )
    ]
)
