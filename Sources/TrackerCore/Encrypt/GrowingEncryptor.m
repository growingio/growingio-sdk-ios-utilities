//
//  GrowingEncryptor.m
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

#import "GrowingEncryptor.h"
#import "GrowingAESEncrypt.h"
#import "GrowingKeyChainWrapper.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString *const kGrowingKeychainAESEncryptKey = @"GrowingKeychainAESEncryptKey";

@interface GrowingEncryptor ()

@property (nonatomic, copy) NSData *key;

@end

@implementation GrowingEncryptor

+ (instancetype)encryptor {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (nullable NSData *)aesEncrypt:(NSData *)data {
    return [GrowingAESEncrypt aesEncrypt:data key:self.key];
}

- (nullable NSData *)aesDecrypt:(NSData *)data {
    return [GrowingAESEncrypt aesDecrypt:data key:self.key];
}

+ (nullable NSData *)randomGenerateBytes:(size_t)count {
    NSMutableData *result = [NSMutableData dataWithLength:count];
    int status = CCRandomGenerateBytes(result.mutableBytes, count);
    if (status != kCCSuccess) {
        return nil;
    }
    return result;
}

- (NSData *)key {
    if (!_key || _key.length != kCCBlockSizeAES128) {
        NSData *generateKey = [GrowingKeyChainWrapper keyChainObjectForKey:kGrowingKeychainAESEncryptKey];
        if (!generateKey || generateKey.length != kCCBlockSizeAES128) {
            // randomGenerateBytes may return nil
            generateKey = [GrowingEncryptor randomGenerateBytes:kCCBlockSizeAES128];
            [GrowingKeyChainWrapper setKeychainObject:[generateKey copy] forKey:kGrowingKeychainAESEncryptKey];
        }
        _key = generateKey;
    }
    return _key;
}

@end
