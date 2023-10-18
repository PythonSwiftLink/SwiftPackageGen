// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPackageGen",
	platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.1.0")),
		.package(url: "https://github.com/apple/swift-syntax", .upToNextMajor(from: "508.0.0")),
		.package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
		.package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "5.0.6")),
		.package(url: "https://github.com/YusukeHosonuma/SwiftPrettyPrint.git", from: .init(1, 4, 0))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SwiftPackageGen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "PathKit", package: "PathKit"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "Yams", package: "Yams"),
				.product(name: "SwiftPrettyPrint", package: "SwiftPrettyPrint")
            ]
        ),
    ]
)
