//
//  GrowingTargetConditionals.h
//  GrowingAnalytics
//
//  Created by YoloMao on 2024/2/1.
//  Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

#import <TargetConditionals.h>

/*
 * ATTENTION: The IOS/MACCATALYST conditionals are NOT mutually exclusive in earlier versions.
 *
 * before iOS SDK 14.2:
 *    +----------------------------------------------------------------+
 *    |                TARGET_OS_MAC                                   |
 *    | +---+  +-----------------------------------------------------+ |
 *    | |   |  |          TARGET_OS_IPHONE                           | |
 *    | |OSX|  | +-----+ +----+ +-------+ +--------+ +-------------+ | |
 *    | |   |  | | IOS | | TV | | WATCH | | BRIDGE | | MACCATALYST | | |
 *    | |   |  | +-----+ +----+ +-------+ +--------+ +-------------+ | |
 *    | +---+  +-----------------------------------------------------+ |
 *    +----------------------------------------------------------------+
 
 * after iOS SDK 14.2:
 *    +---------------------------------------------------------------------------+
 *    |                             TARGET_OS_MAC                                 |
 *    | +-----+ +-------------------------------------------------+ +-----------+ |
 *    | |     | |                  TARGET_OS_IPHONE               | |           | |
 *    | |     | | +-----------------+ +----+ +-------+ +--------+ | |           | |
 *    | |     | | |       IOS       | |    | |       | |        | | |           | |
 *    | | OSX | | | +-------------+ | | TV | | WATCH | | BRIDGE | | | DRIVERKIT | |
 *    | |     | | | | MACCATALYST | | |    | |       | |        | | |           | |
 *    | |     | | | +-------------+ | |    | |       | |        | | |           | |
 *    | |     | | +-----------------+ +----+ +-------+ +--------+ | |           | |
 *    | +-----+ +-------------------------------------------------+ +-----------+ |
 *    +---------------------------------------------------------------------------+
 
 * after iOS SDK 17.2:
 *    +--------------------------------------------------------------------------------------+
 *    |                                    TARGET_OS_MAC                                     |
 *    | +-----+ +------------------------------------------------------------+ +-----------+ |
 *    | |     | |                  TARGET_OS_IPHONE                          | |           | |
 *    | |     | | +-----------------+ +----+ +-------+ +--------+ +--------+ | |           | |
 *    | |     | | |       IOS       | |    | |       | |        | |        | | |           | |
 *    | | OSX | | | +-------------+ | | TV | | WATCH | | BRIDGE | | VISION | | | DRIVERKIT | |
 *    | |     | | | | MACCATALYST | | |    | |       | |        | |        | | |           | |
 *    | |     | | | +-------------+ | |    | |       | |        | |        | | |           | |
 *    | |     | | +-----------------+ +----+ +-------+ +--------+ +--------+ | |           | |
 *    | +-----+ +------------------------------------------------------------+ +-----------+ |
 *    +--------------------------------------------------------------------------------------+
 */

#ifndef Growing_OS_IOS
#if defined(TARGET_OS_IOS) && TARGET_OS_IOS
    #define Growing_OS_IOS 1
#else
    #define Growing_OS_IOS 0
#endif
#endif

#ifndef Growing_OS_OSX
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
    #define Growing_OS_OSX 1
#else
    #define Growing_OS_OSX 0
#endif
#endif

#ifndef Growing_OS_MACCATALYST
#if defined(TARGET_OS_MACCATALYST) && TARGET_OS_MACCATALYST
    #define Growing_OS_MACCATALYST 1
#else
    #define Growing_OS_MACCATALYST 0
#endif
#endif

#ifndef Growing_OS_TV
#if defined(TARGET_OS_TV) && TARGET_OS_TV
    #define Growing_OS_TV 1
#else
    #define Growing_OS_TV 0
#endif
#endif

#ifndef Growing_OS_WATCH
#if defined(TARGET_OS_WATCH) && TARGET_OS_WATCH
    #define Growing_OS_WATCH 1
#else
    #define Growing_OS_WATCH 0
#endif
#endif

#ifndef Growing_OS_VISION
#if defined(TARGET_OS_VISION) && TARGET_OS_VISION
    #define Growing_OS_VISION 1
#else
    #define Growing_OS_VISION 0
#endif
#endif

#ifndef Growing_OS_PURE_IOS
#if Growing_OS_IOS && !Growing_OS_MACCATALYST
    #define Growing_OS_PURE_IOS 1
#else
    #define Growing_OS_PURE_IOS 0
#endif
#endif

#ifndef Growing_USE_APPKIT
#if Growing_OS_OSX
    #define Growing_USE_APPKIT 1
#else
    #define Growing_USE_APPKIT 0
#endif
#endif

#ifndef Growing_USE_UIKIT
#if Growing_OS_IOS || Growing_OS_MACCATALYST || Growing_OS_TV || Growing_OS_VISION
    #define Growing_USE_UIKIT 1
#else
    #define Growing_USE_UIKIT 0
#endif
#endif

#ifndef Growing_USE_WATCHKIT
#if Growing_OS_WATCH
    #define Growing_USE_WATCHKIT 1
#else
    #define Growing_USE_WATCHKIT 0
#endif
#endif

#if Growing_USE_APPKIT
    #import <AppKit/AppKit.h>
#elif Growing_USE_UIKIT
    #import <UIKit/UIKit.h>
#elif Growing_USE_WATCHKIT
    #import <WatchKit/WatchKit.h>
#endif
