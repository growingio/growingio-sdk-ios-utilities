//
//  GrowingULViewControllerLifecycle.m
//  GrowingAnalytics
//
// Created by xiangyang on 2020/11/23.
//  Copyright (C) 2017 Beijing Yishu Technology Co., Ltd.
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

#import "GrowingULViewControllerLifecycle.h"
#import "GrowingULTimeUtil.h"
#import "GrowingULSwizzle.h"
#import <objc/runtime.h>

@interface GrowingULViewControllerLifecycle ()

@property (strong, nonatomic, readonly) NSPointerArray *lifecycleDelegates;
@property (strong, nonatomic, readonly) NSLock *delegateLock;

- (void)dispatchViewControllerLoadView:(UIViewController *)controller;
- (void)dispatchViewControllerDidLoad:(UIViewController *)controller;
- (void)dispatchViewControllerWillAppear:(UIViewController *)controller;
- (void)dispatchViewControllerDidAppear:(UIViewController *)controller;
- (void)dispatchViewControllerWillDisappear:(UIViewController *)controller;
- (void)dispatchViewControllerDidDisappear:(UIViewController *)controller;

@end

@implementation UIViewController (GrowingUtils)

- (void)growingul_loadView {
    [self growingul_loadView];
    [[GrowingULViewControllerLifecycle sharedInstance] dispatchViewControllerLoadView:self];
}

- (void)growingul_viewDidLoad {
    [self growingul_viewDidLoad];
    [[GrowingULViewControllerLifecycle sharedInstance] dispatchViewControllerDidLoad:self];
}

- (void)growingul_viewWillAppear:(BOOL)animated {
    [self growingul_viewWillAppear:animated];
    [[GrowingULViewControllerLifecycle sharedInstance] dispatchViewControllerWillAppear:self];
}

- (void)growingul_viewDidAppear:(BOOL)animated {
    [self growingul_viewDidAppear:animated];
    self.growingul_didAppear = YES;
    [[GrowingULViewControllerLifecycle sharedInstance] dispatchViewControllerDidAppear:self];
}

- (void)growingul_viewWillDisappear:(BOOL)animated {
    [self growingul_viewWillDisappear:animated];
    [GrowingULViewControllerLifecycle.sharedInstance dispatchViewControllerWillDisappear:self];
}

- (void)growingul_viewDidDisappear:(BOOL)animated {
    [self growingul_viewDidDisappear:animated];
    [GrowingULViewControllerLifecycle.sharedInstance dispatchViewControllerDidDisappear:self];
}

- (BOOL)growingul_didAppear {
    return ((NSNumber *)objc_getAssociatedObject(self, _cmd)).boolValue;
}

- (void)setGrowingul_didAppear:(BOOL)didAppear {
    objc_setAssociatedObject(self, @selector(growingul_didAppear), @(didAppear), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation GrowingULViewControllerLifecycle

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
        [[self sharedInstance] setupPageStateNotification];
    });
}

- (void)setupPageStateNotification {
    [UIViewController growingul_swizzleMethod:@selector(loadView)
                                   withMethod:@selector(growingul_loadView)
                                        error:nil];

    [UIViewController growingul_swizzleMethod:@selector(viewDidLoad)
                                   withMethod:@selector(growingul_viewDidLoad)
                                        error:nil];

    [UIViewController growingul_swizzleMethod:@selector(viewWillAppear:)
                                   withMethod:@selector(growingul_viewWillAppear:)
                                        error:nil];

    [UIViewController growingul_swizzleMethod:@selector(viewDidAppear:)
                                   withMethod:@selector(growingul_viewDidAppear:)
                                        error:nil];

    [UIViewController growingul_swizzleMethod:@selector(viewWillDisappear:)
                                   withMethod:@selector(growingul_viewWillDisappear:)
                                        error:nil];

    [UIViewController growingul_swizzleMethod:@selector(viewDidDisappear:)
                                   withMethod:@selector(growingul_viewDidDisappear:)
                                        error:nil];
}

- (void)addViewControllerLifecycleDelegate:(id<GrowingULViewControllerLifecycleDelegate>)delegate {
    [self.delegateLock lock];
    if (![self.lifecycleDelegates.allObjects containsObject:delegate]) {
        [self.lifecycleDelegates addPointer:(__bridge void *)delegate];
    }
    [self.delegateLock unlock];
}

- (void)removeViewControllerLifecycleDelegate:(id<GrowingULViewControllerLifecycleDelegate>)delegate {
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

- (void)dispatchViewControllerLoadView:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }
    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerLoadView:)]) {
            [delegate viewControllerLoadView:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerDidLoad:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }
    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerDidLoad:)]) {
            [delegate viewControllerDidLoad:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerWillAppear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }
    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerWillAppear:)]) {
            [delegate viewControllerWillAppear:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerDidAppear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }
    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerDidAppear:)]) {
            [delegate viewControllerDidAppear:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerWillDisappear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerWillDisappear:)]) {
            [delegate viewControllerWillDisappear:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerDidDisappear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }

    [self.delegateLock lock];
    for (id delegate in self.lifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerDidDisappear:)]) {
            [delegate viewControllerDidDisappear:controller];
        }
    }
    [self.delegateLock unlock];
}

@end
