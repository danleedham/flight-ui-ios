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
        .package(url: "https://github.com/Haelix-Code/AviationMathsFramework", .upToNextMinor(from: "0.4.0"))
    ],
    targets: [
        .target(
            name: "FlightUI",
            dependencies: [
                .product(name: "AviationMaths", package: "AviationMathsFramework")
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
