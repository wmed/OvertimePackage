// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Overtime",
    platforms: [.macOS(.v10_15), .iOS(.v17), .tvOS(.v17), .watchOS(.v6), .macCatalyst(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Overtime",
            targets: ["Overtime"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/realm/realm-swift.git", exact: "10.53.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
        .package(url: "https://github.com/boraseoksoon/Throttler.git", .upToNextMajor(from: "2.1.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Overtime",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "Throttler", package: "Throttler"),
            ],
            resources: [
                Resource.process("Styling/Media.xcassets"),
                Resource.process("Styling/Colors.xcassets")
            ]
        ),
        .testTarget(
            name: "OvertimeTests",
            dependencies: ["Overtime"]
        ),
    ]
)
