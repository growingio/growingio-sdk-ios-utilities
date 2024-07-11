//
//  GrowingULKeyChainWrapper.m
//  GrowingAnalytics
//
//  Created by YoloMao on 2024/7/11.
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

#import "GrowingULKeyChainWrapper.h"

@implementation GrowingULKeyChainWrapper

+ (void)setKeychainObject:(id)value forKey:(NSString *)key {
    // Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];

    // Delete old item before add new item
    SecItemDelete((CFDictionaryRef)keychainQuery);

    // Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:(id)kSecValueData];

    // Add item to keychain with the search dictionary
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

+ (id)keyChainObjectForKey:(NSString *)key {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    // Configure the search setting
    // Since in our simple case we are expecting only a single attribute to be
    // returned (the password) we can set the attribute kSecReturnData to
    // kCFBooleanTrue
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {

        } @finally {
            
        }
    }
    if (keyData) CFRelease(keyData);
    return ret;
}

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:(id)kSecClassGenericPassword,
                                                             (id)kSecClass,
                                                             key,
                                                             (id)kSecAttrService,
                                                             key,
                                                             (id)kSecAttrAccount,
                                                             (id)kSecAttrAccessibleAlwaysThisDeviceOnly,
                                                             (id)kSecAttrAccessible,
                                                             nil];
}

+ (void)removeKeyChainObjectForKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}

@end
