// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftAST",
    products: [
        .library(
            name: "SwiftAST",
            targets: ["SwiftAST"]
        ),
        .library(
            name: "SwiftCFG",
            targets: ["SwiftCFG"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/LuizZak/MiniLexer.git", exact: "0.10.0"),
        .package(url: "https://github.com/LuizZak/MiniGraphviz.git", exact: "0.1.0"),
        .package(url: "https://github.com/LuizZak/MiniDigraph.git", exact: "0.2.1"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.1.0"),
    ],
    targets: [
        .target(
            name: "SwiftAST",
            dependencies: [
                .product(name: "MiniLexer", package: "MiniLexer"),
            ]
        ),
        .target(
            name: "SwiftCFG",
            dependencies: [
                "SwiftAST",
                .product(name: "MiniGraphviz", package: "MiniGraphviz"),
                .product(name: "MiniDigraph", package: "MiniDigraph"),
            ]
        ),
        .testTarget(
            name: "SwiftASTTests",
            dependencies: ["SwiftAST"]
        ),
        .testTarget(
            name: "SwiftCFGTests",
            dependencies: [
                "SwiftCFG",
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
    ]
)
