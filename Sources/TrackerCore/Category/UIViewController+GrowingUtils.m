//
//  UIViewController+GrowingUtils.m
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

#if __has_include(<UIKit/UIKit.h>)
#import "UIViewController+GrowingUtils.h"

@implementation UIViewController (GrowingUtils)

- (nullable UIViewController *)growingul_topViewController {
    UIViewController *presented = self.presentedViewController;
    if (presented) {
        return [presented growingul_topViewController];
    }
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)self;
        return [nav.visibleViewController growingul_topViewController];
    }
    
    if ([self isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)self;
        return [tab.selectedViewController growingul_topViewController];
    }
    
    return self;
}

@end
#endif
