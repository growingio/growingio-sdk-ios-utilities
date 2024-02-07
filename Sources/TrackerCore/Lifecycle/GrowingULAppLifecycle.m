//
//  GrowingULAppLifecycle.m
//  GrowingAnalytics
//
// Created by xiangyang on 2020/11/10.
//  Copyright (C) 2020 Beijing Yishu Technology Co., Ltd.
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
#import "GrowingULAppLifecycle.h"
#import "GrowingULTimeUtil.h"

@interface GrowingULAppLifecycle ()

@property (strong, nonatomic, readonly) NSPointerArray *lifecycleDelegates;
@property (strong, nonatomic, readonly) NSLock *delegateLock;

@end

@implementation GrowingULAppLifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _lifecycleDelegates = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
        _delegateLock = [[NSLock alloc] init];
    }

    return self;
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self sharedInstance] setupAppStateNotification];
    });
}

- (void)setupAppStateNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

#if Growing_USE_UIKIT
    for (NSString *name in @[
        UIApplicationDidFinishLaunchingNotification,
        UIApplicationWillTerminateNotification]) {
        [nc addObserver:self
               selector:@selector(handleProcessLifecycleNotification:)
                   name:name
                 object:[GrowingULApplication sharedApplication]];
    }

    NSDictionary *sceneManifestDict = [[NSBundle mainBundle] infoDictionary][@"UIApplicationSceneManifest"];
    if (sceneManifestDict && UIDevice.currentDevice.systemVersion.doubleValue >= 13.0) {
        [self addSceneNotification];
    } else {
        for (NSString *name in @[
            UIApplicationDidBecomeActiveNotification,
            UIApplicationWillEnterForegroundNotification,
            UIApplicationWillResignActiveNotification,
            UIApplicationDidEnterBackgroundNotification]) {
            [nc addObserver:self
                   selector:@selector(handleUILifecycleNotification:)
                       name:name
                     object:[GrowingULApplication sharedApplication]];
        }
    }
#elif Growing_USE_APPKIT
    for (NSString *name in @[
        NSApplicationDidFinishLaunchingNotification,
        NSApplicationWillTerminateNotification]) {
        [nc addObserver:self
               selector:@selector(handleProcessLifecycleNotification:)
                   name:name
                 object:[GrowingULApplication sharedApplication]];
    }
    
    for (NSString *name in @[
        NSApplicationDidBecomeActiveNotification,
        NSApplicationWillResignActiveNotification]) {
        [nc addObserver:self
               selector:@selector(handleUILifecycleNotification:)
                   name:name
                 object:[GrowingULApplication sharedApplication]];
    }
#elif Growing_USE_WATCHKIT
    if (@available (watchOS 7.0, *)) {
        for (NSString *name in @[
            WKApplicationDidFinishLaunchingNotification]) {
            [nc addObserver:self
                   selector:@selector(handleProcessLifecycleNotification:)
                       name:name
                     object:nil];
        }
        
        for (NSString *name in @[
            WKApplicationDidBecomeActiveNotification,
            WKApplicationWillEnterForegroundNotification,
            WKApplicationWillResignActiveNotification,
            WKApplicationDidEnterBackgroundNotification]) {
            [nc addObserver:self
                   selector:@selector(handleUILifecycleNotification:)
                       name:name
                     object:nil];
        }
    }
#endif
}

#if Growing_USE_UIKIT
- (void)addSceneNotification {
    if (@available(iOS 13, *)) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        // notification name use NSString rather than UISceneWillDeactivateNotification. Xcode 9 package error for no
        // iOS 13 SDK (use of undeclared identifier 'UISceneDidEnterBackgroundNotification'; did you mean
        // 'UIApplicationDidEnterBackgroundNotification'?)
        [nc addObserver:self
               selector:@selector(dispatchApplicationWillResignActive)
                   name:@"UISceneWillDeactivateNotification"
                 object:nil];

        [nc addObserver:self
               selector:@selector(dispatchApplicationDidBecomeActive)
                   name:@"UISceneDidActivateNotification"
                 object:nil];

        [nc addObserver:self
               selector:@selector(dispatchApplicationWillEnterForeground)
                   name:@"UISceneWillEnterForegroundNotification"
                 object:nil];

        [nc addObserver:self
               selector:@selector(dispatchApplicationDidEnterBackground)
                   name:@"UISceneDidEnterBackgroundNotification"
                 object:nil];
    }
}
#endif

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleProcessLifecycleNotification:(NSNotification *)notification {
    NSString *name = notification.name;

#if Growing_USE_UIKIT
    if ([name isEqualToString:UIApplicationDidFinishLaunchingNotification]) {
        [self dispatchApplicationDidFinishLaunching:notification.userInfo];
    } else if ([name isEqualToString:UIApplicationWillTerminateNotification]) {
        [self dispatchApplicationWillTerminate];
    }
#elif Growing_USE_APPKIT
    if ([name isEqualToString:NSApplicationDidFinishLaunchingNotification]) {
        [self dispatchApplicationDidFinishLaunching:notification.userInfo];
    } else if ([name isEqualToString:NSApplicationWillTerminateNotification]) {
        [self dispatchApplicationWillTerminate];
    }
#elif Growing_USE_WATCHKIT
    if (@available (watchOS 7.0, *)) {
        if ([name isEqualToString:WKApplicationDidFinishLaunchingNotification]) {
            [self dispatchApplicationDidFinishLaunching:notification.userInfo];
        }
    }
#endif
}

- (void)handleUILifecycleNotification:(NSNotification *)notification {
    NSString *name = notification.name;

#if Growing_USE_UIKIT
    if ([name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        [self dispatchApplicationDidBecomeActive];
    } else if ([name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        [self dispatchApplicationWillEnterForeground];
    } else if ([name isEqualToString:UIApplicationWillResignActiveNotification]) {
        [self dispatchApplicationWillResignActive];
    } else if ([name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        [self dispatchApplicationDidEnterBackground];
    }
#elif Growing_USE_APPKIT
    if ([name isEqualToString:NSApplicationDidBecomeActiveNotification]) {
        [self dispatchApplicationDidBecomeActive];
    } else if ([name isEqualToString:NSApplicationWillResignActiveNotification]) {
        [self dispatchApplicationWillResignActive];
    }
#elif Growing_USE_WATCHKIT
    if (@available (watchOS 7.0, *)) {
        if ([name isEqualToString:WKApplicationDidBecomeActiveNotification]) {
            [self dispatchApplicationDidBecomeActive];
        } else if ([name isEqualToString:WKApplicationWillEnterForegroundNotification]) {
            [self dispatchApplicationWillEnterForeground];
        } else if ([name isEqualToString:WKApplicationWillResignActiveNotification]) {
            [self dispatchApplicationWillResignActive];
        } else if ([name isEqualToString:WKApplicationDidEnterBackgroundNotification]) {
            [self dispatchApplicationDidEnterBackground];
        }
    }
#endif
}

- (void)addAppLifecycleDelegate:(id)delegate {
    [self.delegateLock lock];
    if (![self.lifecycleDelegates.allObjects containsObject:delegate]) {
        [self.lifecycleDelegates addPointer:(__bridge void *)delegate];
    }
    [self.delegateLock unlock];
}

- (void)removeAppLifecycleDelegate:(id)delegate {
    [self.delegateLock lock];
    [self.lifecycleDelegates.allObjects enumerateObjectsWithOptions:NSEnumerationReverse
                                                         usingBlock:^(NSObject *obj,
                                                                      NSUInteger idx,
                                                                      BOOL *_Nonnull stop) {
        if (delegate == obj) {
            [self.lifecycleDelegates removePointerAtIndex:idx];
            *stop = YES;
        }
    }];
    [self.delegateLock unlock];
}

- (void)dispatchApplicationDidFinishLaunching:(NSDictionary *)userInfo {
    self.appDidFinishLaunchingTime = [GrowingULTimeUtil currentSystemTimeMillis];

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
            [delegate applicationDidFinishLaunching:userInfo];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchApplicationWillTerminate {
    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationWillTerminate)]) {
            [delegate applicationWillTerminate];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchApplicationDidEnterBackground {
    self.appDidEnterBackgroundTime = [GrowingULTimeUtil currentSystemTimeMillis];

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationDidEnterBackground)]) {
            [delegate applicationDidEnterBackground];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchApplicationDidBecomeActive {
    self.appDidBecomeActiveTime = [GrowingULTimeUtil currentSystemTimeMillis];

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationDidBecomeActive)]) {
            [delegate applicationDidBecomeActive];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchApplicationWillResignActive {
    self.appWillResignActiveTime = [GrowingULTimeUtil currentSystemTimeMillis];

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationWillResignActive)]) {
            [delegate applicationWillResignActive];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchApplicationWillEnterForeground {
    self.appWillEnterForegroundTime = [GrowingULTimeUtil currentSystemTimeMillis];

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(applicationWillEnterForeground)]) {
            [delegate applicationWillEnterForeground];
        }
    }
    [self.delegateLock unlock];
}

@end
