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

#import <Foundation/Foundation.h>

#pragma mark - Macros Based API

/// A macro for wrapping the return type of the swizzled method.
#define GUSWReturnType(type) type

/// A macro for wrapping arguments of the swizzled method.
#define GUSWArguments(arguments...) _GUSWArguments(arguments)

/// A macro for wrapping the replacement code for the swizzled method.
#define GUSWReplacement(code...) code

/// A macro for casting and calling original implementation.
/// May be used only in GrowingULSwizzleInstanceMethod or GrowingULSwizzleClassMethod macros.
#define GUSWCallOriginal(arguments...) _GUSWCallOriginal(arguments)

#pragma mark └ Swizzle Instance Method

/**
 Swizzles the instance method of the class with the new implementation.

 Example for swizzling `-(int)calculate:(int)number;` method:

 @code

    GrowingULSwizzleInstanceMethod(classToSwizzle,
                            @selector(calculate:),
                            GUSWReturnType(int),
                            GUSWArguments(int number),
                            GUSWReplacement(
    {
        // Calling original implementation.
        int res = GUSWCallOriginal(number);
        // Returning modified return value.
        return res + 1;
    }), 0, NULL);
 
 @endcode
 
 Swizzling frequently goes along with checking whether this particular class (or one of its superclasses) has been already swizzled. Here the `GrowingULSwizzleMode` and `key` parameters can help. See +[GrowingULSwizzle swizzleInstanceMethod:inClass:newImpFactory:mode:key:] for details.

 Swizzling is fully thread-safe.

 @param classToSwizzle The class with the method that should be swizzled.

 @param selector Selector of the method that should be swizzled.
 
 @param GUSWReturnType The return type of the swizzled method wrapped in the GUSWReturnType macro.
 
 @param GUSWArguments The arguments of the swizzled method wrapped in the GUSWArguments macro.
 
 @param GUSWReplacement The code of the new implementation of the swizzled method wrapped in the GUSWReplacement macro.
 
 @param GrowingULSwizzleMode The mode is used in combination with the key to indicate whether the swizzling should be done for the given class. You can pass 0 for GrowingULSwizzleModeAlways.
 
 @param key The key is used in combination with the mode to indicate whether the swizzling should be done for the given class. May be NULL if the mode is GrowingULSwizzleModeAlways.

 @return YES if successfully swizzled and NO if swizzling has been already done for given key and class (or one of superclasses, depends on the mode).

 */
#define GrowingULSwizzleInstanceMethod(classToSwizzle, \
                                selector, \
                                GUSWReturnType, \
                                GUSWArguments, \
                                GUSWReplacement, \
                                GrowingULSwizzleMode, \
                                key) \
    _GrowingULSwizzleInstanceMethod(classToSwizzle, \
                             selector, \
                             GUSWReturnType, \
                             _GUSWWrapArg(GUSWArguments), \
                             _GUSWWrapArg(GUSWReplacement), \
                             GrowingULSwizzleMode, \
                             key)

#pragma mark └ Swizzle Class Method

/**
 Swizzles the class method of the class with the new implementation.

 Example for swizzling `+(int)calculate:(int)number;` method:

 @code

    GrowingULSwizzleClassMethod(classToSwizzle,
                         @selector(calculate:),
                         GUSWReturnType(int),
                         GUSWArguments(int number),
                         GUSWReplacement(
    {
        // Calling original implementation.
        int res = GUSWCallOriginal(number);
        // Returning modified return value.
        return res + 1;
    }));
 
 @endcode

 Swizzling is fully thread-safe.

 @param classToSwizzle The class with the method that should be swizzled.

 @param selector Selector of the method that should be swizzled.
 
 @param GUSWReturnType The return type of the swizzled method wrapped in the GUSWReturnType macro.
 
 @param GUSWArguments The arguments of the swizzled method wrapped in the GUSWArguments macro.
 
 @param GUSWReplacement The code of the new implementation of the swizzled method wrapped in the GUSWReplacement macro.
 
 */
#define GrowingULSwizzleClassMethod(classToSwizzle, \
                             selector, \
                             GUSWReturnType, \
                             GUSWArguments, \
                             GUSWReplacement) \
    _GrowingULSwizzleClassMethod(classToSwizzle, \
                          selector, \
                          GUSWReturnType, \
                          _GUSWWrapArg(GUSWArguments), \
                          _GUSWWrapArg(GUSWReplacement))

#pragma mark - Main API

/**
 A function pointer to the original implementation of the swizzled method.
 */
typedef void (*GrowingULSwizzleOriginalIMP)(void /* id, SEL, ... */ );

/**
 GrowingULSwizzleInfo is used in the new implementation block to get and call original implementation of the swizzled method.
 */
@interface GrowingULSwizzleInfo : NSObject

/**
 Returns the original implementation of the swizzled method.

 It is actually either an original implementation if the swizzled class implements the method itself; or a super implementation fetched from one of the superclasses.
 
 @note You must always cast returned implementation to the appropriate function pointer when calling.
 
 @return A function pointer to the original implementation of the swizzled method.
 */
-(GrowingULSwizzleOriginalIMP)getOriginalImplementation;

/// The selector of the swizzled method.
@property (nonatomic, readonly) SEL selector;

@end

/**
 A factory block returning the block for the new implementation of the swizzled method.

 You must always obtain original implementation with swizzleInfo and call it from the new implementation.
 
 @param swizzleInfo An info used to get and call the original implementation of the swizzled method.

 @return A block that implements a method.
    Its signature should be: `method_return_type ^(id self, method_args...)`.
    The selector is not available as a parameter to this block.
 */
typedef id (^GrowingULSwizzleImpFactoryBlock)(GrowingULSwizzleInfo *swizzleInfo);

typedef NS_ENUM(NSUInteger, GrowingULSwizzleMode) {
    /// GrowingULSwizzle always does swizzling.
    GrowingULSwizzleModeAlways = 0,
    /// GrowingULSwizzle does not do swizzling if the same class has been swizzled earlier with the same key.
    GrowingULSwizzleModeOncePerClass = 1,
    /// GrowingULSwizzle does not do swizzling if the same class or one of its superclasses have been swizzled earlier with the same key.
    /// @note There is no guarantee that your implementation will be called only once per method call. If the order of swizzling is: first inherited class, second superclass, then both swizzlings will be done and the new implementation will be called twice.
    GrowingULSwizzleModeOncePerClassAndSuperclasses = 2
};

@interface GrowingULSwizzle : NSObject

#pragma mark └ Swizzle Instance Method

/**
 Swizzles the instance method of the class with the new implementation.

 Original implementation must always be called from the new implementation. And because of the the fact that for safe and robust swizzling original implementation must be dynamically fetched at the time of calling and not at the time of swizzling, swizzling API is a little bit complicated.

 You should pass a factory block that returns the block for the new implementation of the swizzled method. And use swizzleInfo argument to retrieve and call original implementation.

 Example for swizzling `-(int)calculate:(int)number;` method:
 
 @code

    SEL selector = @selector(calculate:);
    [GrowingULSwizzle
     swizzleInstanceMethod:selector
     inClass:classToSwizzle
     newImpFactory:^id(GrowingULSwizzleInfo *swizzleInfo) {
         // This block will be used as the new implementation.
         return ^int(__unsafe_unretained id self, int num){
             // You MUST always cast implementation to the correct function pointer.
             int (*originalIMP)(__unsafe_unretained id, SEL, int);
             originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
             // Calling original implementation.
             int res = originalIMP(self,selector,num);
             // Returning modified return value.
             return res + 1;
         };
     }
     mode:GrowingULSwizzleModeAlways
     key:NULL];
 
 @endcode

 Swizzling frequently goes along with checking whether this particular class (or one of its superclasses) has been already swizzled. Here the `mode` and `key` parameters can help.

 Here is an example of swizzling `-(void)dealloc;` only in case when neither class and no one of its superclasses has been already swizzled with our key. However "Deallocating ..." message still may be logged multiple times per method call if swizzling was called primarily for an inherited class and later for one of its superclasses.
 
 @code
 
    static const void *key = &key;
    SEL selector = NSSelectorFromString(@"dealloc");
    [GrowingULSwizzle
     swizzleInstanceMethod:selector
     inClass:classToSwizzle
     newImpFactory:^id(GrowingULSwizzleInfo *swizzleInfo) {
         return ^void(__unsafe_unretained id self){
             NSLog(@"Deallocating %@.",self);
             
             void (*originalIMP)(__unsafe_unretained id, SEL);
             originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
             originalIMP(self,selector);
         };
     }
     mode:GrowingULSwizzleModeOncePerClassAndSuperclasses
     key:key];
 
 @endcode

 Swizzling is fully thread-safe.
 
 @param selector Selector of the method that should be swizzled.

 @param classToSwizzle The class with the method that should be swizzled.
 
 @param factoryBlock The factory block returning the block for the new implementation of the swizzled method.
 
 @param mode The mode is used in combination with the key to indicate whether the swizzling should be done for the given class.
 
 @param key The key is used in combination with the mode to indicate whether the swizzling should be done for the given class. May be NULL if the mode is GrowingULSwizzleModeAlways.

 @return YES if successfully swizzled and NO if swizzling has been already done for given key and class (or one of superclasses, depends on the mode).
 */
+(BOOL)swizzleInstanceMethod:(SEL)selector
                     inClass:(Class)classToSwizzle
               newImpFactory:(GrowingULSwizzleImpFactoryBlock)factoryBlock
                        mode:(GrowingULSwizzleMode)mode
                         key:(const void *)key;

#pragma mark └ Swizzle Class method

/**
 Swizzles the class method of the class with the new implementation.

 Original implementation must always be called from the new implementation. And because of the the fact that for safe and robust swizzling original implementation must be dynamically fetched at the time of calling and not at the time of swizzling, swizzling API is a little bit complicated.

 You should pass a factory block that returns the block for the new implementation of the swizzled method. And use swizzleInfo argument to retrieve and call original implementation.

 Example for swizzling `+(int)calculate:(int)number;` method:
 
 @code

    SEL selector = @selector(calculate:);
    [GrowingULSwizzle
     swizzleClassMethod:selector
     inClass:classToSwizzle
     newImpFactory:^id(GrowingULSwizzleInfo *swizzleInfo) {
         // This block will be used as the new implementation.
         return ^int(__unsafe_unretained id self, int num){
             // You MUST always cast implementation to the correct function pointer.
             int (*originalIMP)(__unsafe_unretained id, SEL, int);
             originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
             // Calling original implementation.
             int res = originalIMP(self,selector,num);
             // Returning modified return value.
             return res + 1;
         };
     }];
 
 @endcode

 Swizzling is fully thread-safe.
 
 @param selector Selector of the method that should be swizzled.

 @param classToSwizzle The class with the method that should be swizzled.
 
 @param factoryBlock The factory block returning the block for the new implementation of the swizzled method.
 */
+(void)swizzleClassMethod:(SEL)selector
                  inClass:(Class)classToSwizzle
            newImpFactory:(GrowingULSwizzleImpFactoryBlock)factoryBlock;

// setDelegate时，返回正确的delegate
+ (id)realDelegate:(id)proxy toSelector:(SEL)selector;
+ (BOOL)realDelegateClass:(Class)cls respondsToSelector:(SEL)sel;

@end

#pragma mark - Implementation details
// Do not write code that depends on anything below this line.

// Wrapping arguments to pass them as a single argument to another macro.
#define _GUSWWrapArg(args...) args

#define _GUSWDel2Arg(a1, a2, args...) a1, ##args
#define _GUSWDel3Arg(a1, a2, a3, args...) a1, a2, ##args

// To prevent comma issues if there are no arguments we add one dummy argument
// and remove it later.
#define _GUSWArguments(arguments...) DEL, ##arguments

#define _GrowingULSwizzleInstanceMethod(classToSwizzle, \
                                 selector, \
                                 GUSWReturnType, \
                                 GUSWArguments, \
                                 GUSWReplacement, \
                                 GrowingULSwizzleMode, \
                                 KEY) \
    [GrowingULSwizzle \
     swizzleInstanceMethod:selector \
     inClass:[classToSwizzle class] \
     newImpFactory:^id(GrowingULSwizzleInfo *swizzleInfo) { \
        GUSWReturnType (*originalImplementation_)(_GUSWDel3Arg(__unsafe_unretained id, \
                                                               SEL, \
                                                               GUSWArguments)); \
        SEL selector_ = selector; \
        return ^GUSWReturnType (_GUSWDel2Arg(__unsafe_unretained id self, \
                                             GUSWArguments)) \
        { \
            GUSWReplacement \
        }; \
     } \
     mode:GrowingULSwizzleMode \
     key:KEY];

#define _GrowingULSwizzleClassMethod(classToSwizzle, \
                              selector, \
                              GUSWReturnType, \
                              GUSWArguments, \
                              GUSWReplacement) \
    [GrowingULSwizzle \
     swizzleClassMethod:selector \
     inClass:[classToSwizzle class] \
     newImpFactory:^id(GrowingULSwizzleInfo *swizzleInfo) { \
        GUSWReturnType (*originalImplementation_)(_GUSWDel3Arg(__unsafe_unretained id, \
                                                               SEL, \
                                                               GUSWArguments)); \
        SEL selector_ = selector; \
        return ^GUSWReturnType (_GUSWDel2Arg(__unsafe_unretained id self, \
                                             GUSWArguments)) \
        { \
            GUSWReplacement \
        }; \
     }];

#define _GUSWCallOriginal(arguments...) \
    ((__typeof(originalImplementation_))[swizzleInfo \
                                         getOriginalImplementation])(self, \
                                                                     selector_, \
                                                                     ##arguments)
