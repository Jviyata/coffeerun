// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoffeeBreak",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CoffeeBreak",
            path: "CoffeeBreak",
            exclude: [
                "Info.plist",
                "CoffeeBreak.entitlements",
                "Resources"
            ],
            sources: [
                "CoffeeBreakApp.swift",
                "Models",
                "Services",
                "State",
                "Views"
            ]
        )
    ]
)
