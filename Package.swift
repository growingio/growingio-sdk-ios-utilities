// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Package.swift
//  GrowingAnalytics
//
//  Created by YoloMao on 2022/10/17.
//  Copyright (C) 2022 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import PackageDescription

let package = Package(
    name: "GrowingUtils",
    platforms: [.iOS(.v10), .macCatalyst(.v13), .macOS(.v10_12)],
    products: [
        .library(
            name: "GrowingUtilsTrackerCore",
            targets: ["GrowingUtilsTrackerCore_Wrapper"]
        ),
        .library(
            name: "GrowingUtilsAutotrackerCore",
            targets: ["GrowingUtilsAutotrackerCore_Wrapper"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GrowingUtilsTrackerCore_Wrapper",
            dependencies: [.target(name: "GrowingUtilsTrackerCore",
                                   condition: .when(platforms: [.iOS, .macCatalyst, .macOS]))],
            path: "SwiftPM-Wrap/TrackerCore-Wrapper"
        ),
        .target(
            name: "GrowingUtilsAutotrackerCore_Wrapper",
            dependencies: [.target(name: "GrowingUtilsAutotrackerCore",
                                   condition: .when(platforms: [.iOS, .macCatalyst]))],
            path: "SwiftPM-Wrap/AutotrackerCore-Wrapper"
        ),
        .target(
            name: "GrowingUtilsTrackerCore",
            dependencies: [],
            path: "Sources/TrackerCore",
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Public"),
            ]
        ),
        .target(
            name: "GrowingUtilsAutotrackerCore",
            dependencies: ["GrowingUtilsTrackerCore"],
            path: "Sources/AutotrackerCore",
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Public"),
            ]
        ),
    ]
)
