// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SolMacAgent",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SolMacAgent", targets: ["SolMacAgent"])
    ],
    targets: [
        .executableTarget(name: "SolMacAgent", path: "Sources/SolMacAgent")
    ]
)
