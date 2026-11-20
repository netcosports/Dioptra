// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Dioptra",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Dioptra", targets: ["Dioptra"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.9.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxGesture.git", .upToNextMajor(from: "4.0.4")),
        .package(url: "https://github.com/RxSwiftCommunity/RxReachability.git", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        .target(
            name: "Dioptra",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxGesture", package: "RxGesture"),
                .product(name: "RxReachability", package: "RxReachability")
            ],
            path: "./Sources",
            sources: ["Core", "AV"],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS])),
                .linkedFramework("AVKit", .when(platforms: [.iOS]))
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)