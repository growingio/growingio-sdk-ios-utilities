//
//  UIApplication+GrowingUtilsTrackerCore.m
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
#import "UIApplication+GrowingUtilsTrackerCore.h"
#import "UIViewController+GrowingUtilsTrackerCore.h"
#import "GrowingULApplication.h"

@implementation UIApplication (GrowingUtilsTrackerCore)

- (nullable UIWindow *)growingul_keyWindow {
    if ([GrowingULApplication isAppExtension]) {
        return nil;
    }
    
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in self.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows.reverseObjectEnumerator) {
                    if (window.isHidden || window.alpha < 0.001) {
                        continue;
                    }
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                break;
            }
        }
    }

    for (UIWindow *window in self.windows.reverseObjectEnumerator) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    
    return nil;
}

- (nullable UIViewController *)growingul_topViewController {
    UIWindow *keyWindow = self.growingul_keyWindow;
    if (!keyWindow) {
        return nil;
    }
    UIViewController *root = keyWindow.rootViewController;
    if (!root) {
        return nil;
    }
    return root.growingul_topViewController;
}

- (CGFloat)growingul_statusBarHeight {
    if (@available(iOS 13.0, *)) {
        return self.growingul_keyWindow.windowScene.statusBarManager.statusBarFrame.size.height;
    }
    
    return self.statusBarFrame.size.height;
}

@end
#endif
