// swift-tools-version: 5.10
import PackageDescription
import CompilerPluginSupport

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
        .package(url: "https://github.com/LuizZak/MiniDigraph.git", exact: "0.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftASTMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "SwiftAST",
            dependencies: [
                .product(name: "MiniLexer", package: "MiniLexer"),
                "SwiftASTMacros",
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
        .testTarget(
            name: "SwiftASTMacrosTests",
            dependencies: [
                "SwiftASTMacros",
            ]
        )
    ]
)
