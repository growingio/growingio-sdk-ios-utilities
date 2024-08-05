//  The MIT License (MIT)
//
// Copyright (c) 2013 Yan Rabovik
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is furnished
// to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//  https://github.com/rabovik/RSSwizzle
//
//  GrowingULSwizzler.h
//  GrowingAnalytics
//
//  Created by YoloMao on 2023/9/28.
//  Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
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

#import "GrowingULSwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <os/lock.h>

#if !__has_feature(objc_arc)
#error This code needs ARC. Use compiler option -fobjc-arc
#endif

#pragma mark - Block Helpers
#if !defined(NS_BLOCK_ASSERTIONS)

// See http://clang.llvm.org/docs/Block-ABI-Apple.html#high-level
struct Block_literal_1 {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 {
        unsigned long int reserved;         // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};
typedef int BlockFlags;

static const char *blockGetType(id block){
    struct Block_literal_1 *blockRef = (__bridge struct Block_literal_1 *)block;
    BlockFlags flags = blockRef->flags;
    
    if (flags & BLOCK_HAS_SIGNATURE) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (flags & BLOCK_HAS_COPY_DISPOSE) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return signature;
    }
    
    return NULL;
}

static BOOL blockIsCompatibleWithMethodType(id block, const char *methodType){
    
    const char *blockType = blockGetType(block);
    
    NSMethodSignature *blockSignature;
    
    if (0 == strncmp(blockType, (const char *)"@\"", 2)) {
        // Block return type includes class name for id types
        // while methodType does not include.
        // Stripping out return class name.
        char *quotePtr = strchr(blockType+2, '"');
        if (NULL != quotePtr) {
            ++quotePtr;
            char filteredType[strlen(quotePtr) + 2];
            memset(filteredType, 0, sizeof(filteredType));
            *filteredType = '@';
            strncpy(filteredType + 1, quotePtr, sizeof(filteredType) - 2);
            
            blockSignature = [NSMethodSignature signatureWithObjCTypes:filteredType];
        }else{
            return NO;
        }
    }else{
        blockSignature = [NSMethodSignature signatureWithObjCTypes:blockType];
    }
    
    NSMethodSignature *methodSignature =
        [NSMethodSignature signatureWithObjCTypes:methodType];
    
    if (!blockSignature || !methodSignature) {
        return NO;
    }
    
    if (blockSignature.numberOfArguments != methodSignature.numberOfArguments){
        return NO;
    }
    
    if (strcmp(blockSignature.methodReturnType, methodSignature.methodReturnType) != 0) {
        return NO;
    }
    
    for (int i=0; i<methodSignature.numberOfArguments; ++i){
        if (i == 0){
            // self in method, block in block
            if (strcmp([methodSignature getArgumentTypeAtIndex:i], "@") != 0) {
                return NO;
            }
            if (strcmp([blockSignature getArgumentTypeAtIndex:i], "@?") != 0) {
                return NO;
            }
        }else if(i == 1){
            // SEL in method, self in block
            if (strcmp([methodSignature getArgumentTypeAtIndex:i], ":") != 0) {
                return NO;
            }
            if (strncmp([blockSignature getArgumentTypeAtIndex:i], "@", 1) != 0) {
                return NO;
            }
        }else {
            const char *blockSignatureArg = [blockSignature getArgumentTypeAtIndex:i];
            
            if (strncmp(blockSignatureArg, "@?", 2) == 0) {
                // Handle function pointer / block arguments
                blockSignatureArg = "@?";
            }
            else if (strncmp(blockSignatureArg, "@", 1) == 0) {
                blockSignatureArg = "@";
            }
            
            if (strcmp(blockSignatureArg,
                       [methodSignature getArgumentTypeAtIndex:i]) != 0)
            {
                return NO;
            }
        }
    }
    
    return YES;
}

static BOOL blockIsAnImpFactoryBlock(id block){
    const char *blockType = blockGetType(block);
    GrowingULSwizzleImpFactoryBlock dummyFactory = ^id(GrowingULSwizzleInfo *swizzleInfo){
        return nil;
    };
    const char *factoryType = blockGetType(dummyFactory);
    return 0 == strcmp(factoryType, blockType);
}

#endif // NS_BLOCK_ASSERTIONS


#pragma mark - Swizzling

#pragma mark └ GrowingULSwizzleInfo
typedef IMP (^GUSWizzleImpProvider)(void);

@interface GrowingULSwizzleInfo()
@property (nonatomic,copy) GUSWizzleImpProvider impProviderBlock;
@property (nonatomic, readwrite) SEL selector;
@end

@implementation GrowingULSwizzleInfo

-(GrowingULSwizzleOriginalIMP)getOriginalImplementation{
    NSAssert(_impProviderBlock,nil);
    // Casting IMP to GrowingULSwizzleOriginalIMP to force user casting.
    return (GrowingULSwizzleOriginalIMP)_impProviderBlock();
}

@end


#pragma mark └ GrowingULSwizzle
@implementation GrowingULSwizzle

static void swizzle(Class classToSwizzle,
                    SEL selector,
                    GrowingULSwizzleImpFactoryBlock factoryBlock)
{
    Method method = class_getInstanceMethod(classToSwizzle, selector);
    
    NSCAssert(NULL != method,
              @"Selector %@ not found in %@ methods of class %@.",
              NSStringFromSelector(selector),
              class_isMetaClass(classToSwizzle) ? @"class" : @"instance",
              classToSwizzle);
    
    NSCAssert(blockIsAnImpFactoryBlock(factoryBlock),
             @"Wrong type of implementation factory block.");
    
    __block os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    // To keep things thread-safe, we fill in the originalIMP later,
    // with the result of the class_replaceMethod call below.
    __block IMP originalIMP = NULL;

    // This block will be called by the client to get original implementation and call it.
    GUSWizzleImpProvider originalImpProvider = ^IMP{
        // It's possible that another thread can call the method between the call to
        // class_replaceMethod and its return value being set.
        // So to be sure originalIMP has the right value, we need a lock.
        os_unfair_lock_lock(&lock);
        IMP imp = originalIMP;
        os_unfair_lock_unlock(&lock);
        
        if (NULL == imp){
            // If the class does not implement the method
            // we need to find an implementation in one of the superclasses.
            Class superclass = class_getSuperclass(classToSwizzle);
            imp = method_getImplementation(class_getInstanceMethod(superclass,selector));
        }
        return imp;
    };
    
    GrowingULSwizzleInfo *swizzleInfo = [GrowingULSwizzleInfo new];
    swizzleInfo.selector = selector;
    swizzleInfo.impProviderBlock = originalImpProvider;
    
    // We ask the client for the new implementation block.
    // We pass swizzleInfo as an argument to factory block, so the client can
    // call original implementation from the new implementation.
    id newIMPBlock = factoryBlock(swizzleInfo);
    
    const char *methodType = method_getTypeEncoding(method);
    
    NSCAssert(blockIsCompatibleWithMethodType(newIMPBlock,methodType),
             @"Block returned from factory is not compatible with method type.");
    
    IMP newIMP = imp_implementationWithBlock(newIMPBlock);
    
    // Atomically replace the original method with our new implementation.
    // This will ensure that if someone else's code on another thread is messing
    // with the class' method list too, we always have a valid method at all times.
    //
    // If the class does not implement the method itself then
    // class_replaceMethod returns NULL and superclasses's implementation will be used.
    //
    // We need a lock to be sure that originalIMP has the right value in the
    // originalImpProvider block above.
    os_unfair_lock_lock(&lock);
    originalIMP = class_replaceMethod(classToSwizzle, selector, newIMP, methodType);
    os_unfair_lock_unlock(&lock);
}

static NSMutableDictionary *swizzledClassesDictionary(void){
    static NSMutableDictionary *swizzledClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [NSMutableDictionary new];
    });
    return swizzledClasses;
}

static NSMutableSet *swizzledClassesForKey(const void *key){
    NSMutableDictionary *classesDictionary = swizzledClassesDictionary();
    NSValue *keyValue = [NSValue valueWithPointer:key];
    NSMutableSet *swizzledClasses = [classesDictionary objectForKey:keyValue];
    if (!swizzledClasses) {
        swizzledClasses = [NSMutableSet new];
        [classesDictionary setObject:swizzledClasses forKey:keyValue];
    }
    return swizzledClasses;
}

+(BOOL)swizzleInstanceMethod:(SEL)selector
                     inClass:(Class)classToSwizzle
               newImpFactory:(GrowingULSwizzleImpFactoryBlock)factoryBlock
                        mode:(GrowingULSwizzleMode)mode
                         key:(const void *)key
{
    NSAssert(!(NULL == key && GrowingULSwizzleModeAlways != mode),
             @"Key may not be NULL if mode is not GrowingULSwizzleModeAlways.");

    @synchronized(swizzledClassesDictionary()){
        if (key){
            NSSet *swizzledClasses = swizzledClassesForKey(key);
            if (mode == GrowingULSwizzleModeOncePerClass) {
                if ([swizzledClasses containsObject:classToSwizzle]){
                    return NO;
                }
            }else if (mode == GrowingULSwizzleModeOncePerClassAndSuperclasses){
                for (Class currentClass = classToSwizzle;
                     nil != currentClass;
                     currentClass = class_getSuperclass(currentClass))
                {
                    if ([swizzledClasses containsObject:currentClass]) {
                        return NO;
                    }
                }
            }
        }
        
        swizzle(classToSwizzle, selector, factoryBlock);
        
        if (key){
            [swizzledClassesForKey(key) addObject:classToSwizzle];
        }
    }
    
    return YES;
}

+(void)swizzleClassMethod:(SEL)selector
                  inClass:(Class)classToSwizzle
            newImpFactory:(GrowingULSwizzleImpFactoryBlock)factoryBlock
{
    [self swizzleInstanceMethod:selector
                        inClass:object_getClass(classToSwizzle)
                  newImpFactory:factoryBlock
                           mode:GrowingULSwizzleModeAlways
                            key:NULL];
}

+ (id)realDelegate:(id)proxy toSelector:(SEL)selector {
    // 不再兼容forwardingTargetForSelector场景，仅通过下方的class_respondsToSelector判断当前类是否有对应实现
    return proxy;
}

+ (BOOL)realDelegateClass:(Class)cls respondsToSelector:(SEL)sel {
    //如果cls继承自NSProxy，使用respondsToSelector来判断会崩溃
    //因为NSProxy本身未实现respondsToSelector
    return class_respondsToSelector(cls, sel);
}

@end
