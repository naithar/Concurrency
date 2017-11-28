// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Concurrency",
    products: [
        .library(name: "Concurrency", targets: ["Concurrency"]),
    ],
    targets: [
        .target(name: "Concurrency", dependencies: []),
        .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),
    ]
)
