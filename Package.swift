// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FolderViewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FolderViewer", targets: ["FolderViewer"])
    ],
    targets: [
        .executableTarget(
            name: "FolderViewer",
            path: "Sources"
        )
    ]
)
