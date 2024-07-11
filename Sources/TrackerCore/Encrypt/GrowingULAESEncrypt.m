//
//  GrowingULAESEncrypt.m
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

#import "GrowingULAESEncrypt.h"
#import "GrowingULEncryptor.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation GrowingULAESEncrypt

+ (nullable NSData *)aesEncrypt:(NSData *)data key:(NSData *)key {
    return [self aesCrypt:data operation:kCCEncrypt key:key];
}

+ (nullable NSData *)aesDecrypt:(NSData *)data key:(NSData *)key {
    return [self aesCrypt:data operation:kCCDecrypt key:key];
}

+ (nullable NSData *)aesCrypt:(NSData *)data operation:(CCOperation)operation key:(NSData *)key {
    NSData *iv = nil;
    size_t ivLength = kCCBlockSizeAES128;
    if (operation == kCCEncrypt) {
        iv = [GrowingULEncryptor randomGenerateBytes:ivLength];
    } else if (operation == kCCDecrypt) {
        if (data.length <= ivLength) {
            return nil;
        }
        iv = [data subdataWithRange:NSMakeRange(0, ivLength)];
        data = [data subdataWithRange:NSMakeRange(ivLength, data.length - ivLength)];
    }
    if (!iv) {
        return nil;
    }
    
    size_t dataOutAvailable = [data length] + kCCBlockSizeAES128 * 2;
    void *dataOut = malloc(dataOutAvailable);
    size_t dataOutMoved = 0;
    
    CCCryptorStatus status = CCCrypt(operation,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     [key bytes],
                                     [key length],
                                     [iv bytes],
                                     [data bytes],
                                     [data length],
                                     dataOut,
                                     dataOutAvailable,
                                     &dataOutMoved);
    NSData *result = nil;
    if (status == kCCSuccess) {
        NSMutableData *resultM = [NSMutableData data];
        if (operation == kCCEncrypt) {
            [resultM appendData:iv];
        }
        [resultM appendData:[NSData dataWithBytes:dataOut length:dataOutMoved]];
        result = [resultM copy];
    }
    free(dataOut);
    return result;
}

@end
