//
//  GrowingULApplication.m
//  GrowingAnalytics
//
//  Created by YoloMao on 2024/1/15.
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

#import "GrowingULApplication.h"

@implementation GrowingULApplication

+ (nullable id)sharedApplication {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class class;
#if Growing_USE_APPKIT
    class = NSClassFromString(@"NSApplication");
#elif Growing_USE_UIKIT
    class = NSClassFromString(@"UIApplication");
#elif Growing_USE_WATCHKIT
    class = NSClassFromString(@"WKApplication");
#endif
    
    SEL selector = NSSelectorFromString(@"sharedApplication");
    if(!class || ![class respondsToSelector:selector]) {
        return nil;
    }
    return [class performSelector:selector];
#pragma clang diagnostic pop
}

+ (BOOL)isAppExtension {
#if Growing_OS_IOS || Growing_OS_TV || Growing_OS_WATCH
    return [[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"];
#else
    return NO;
#endif
}

@end
