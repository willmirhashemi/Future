// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EndlessCalendar",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EndlessCalendar",
            targets: ["EndlessCalendar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.4.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "EndlessCalendar",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            path: "EndlessCalendar"
        ),
    ]
)
