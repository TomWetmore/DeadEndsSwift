// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DeadEndsSwift",

    products: [
        .library(
            name: "DeadEndsLib",
            targets: ["DeadEndsLib"]
        )
    ],

    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-parsing",
            from: "0.14.0"
        )
    ],

    targets: [
        .target(
            name: "DeadEndsLib",
            dependencies: [
                .product(
                    name: "Parsing",
                    package: "swift-parsing"
                )
            ],
            path: "DeadEndsLib"
        )
    ]
)
