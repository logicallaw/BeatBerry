/*
 * This is file of the project BeatBerry
 * Licensed under the GNU General Public License v3.0.
 * Copyright (c) 2025-2026 BeatBerry
 * For full license text, see the LICENSE file in the root directory or at
 * https://www.gnu.org/licenses/gpl-3.0.txt
 * Author: Junho Kim
 * Latest Updated Date: 2026-02-28
 */

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BeatBerryMacOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BeatBerryMacOS", targets: ["BeatBerryMacOS"])
    ],
    targets: [
        .target(
            name: "BeatBerryDomain",
            path: "Sources/Domain"
        ),
        .target(
            name: "BeatBerryApplication",
            dependencies: ["BeatBerryDomain"],
            path: "Sources/Application"
        ),
        .target(
            name: "BeatBerryInfrastructure",
            dependencies: ["BeatBerryDomain"],
            path: "Sources/Infrastructure"
        ),
        .target(
            name: "BeatBerryPresentation",
            dependencies: [
                "BeatBerryApplication",
                "BeatBerryDomain"
            ],
            path: "Sources/Presentation"
        ),
        .executableTarget(
            name: "BeatBerryMacOS",
            dependencies: [
                "BeatBerryPresentation",
                "BeatBerryInfrastructure",
                "BeatBerryDomain"
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "BeatBerryMacOSTests",
            dependencies: [
                "BeatBerryApplication",
                "BeatBerryDomain",
                "BeatBerryInfrastructure"
            ],
            path: "Tests/BeatBerryMacOSTests"
        )
    ]
)
