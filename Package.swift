// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DeadEndsSwift",
    platforms: [
        .macOS(.v13)
    ],

    products: [
        .library(
            name: "DeadEndsLib",
            targets: ["DeadEndsLib"]
        ),
        .executable(
            name: "deadends",
            targets: ["DeadEndsCommand"]
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
        ),

        .executableTarget(
            name: "DeadEndsCommand",
            dependencies: [
                "DeadEndsLib"
            ],
            path: "DeadEndsCommand"
        )
    ]
)
