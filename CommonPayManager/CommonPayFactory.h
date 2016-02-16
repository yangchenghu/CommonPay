//
//  CommonPayFactory.h
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CommonPayDefine.h"

@interface CommonPayFactory : NSObject

/**
 * @description 生成支付宝信息字符串
 * @param
 * @return
 */
+ (id)GenAlipayAllInfoStringFromInfo:(NSDictionary *)dicInfo;

/**
 * @description 生成错误信息
 * @param errorCode
 * @param message 
 * @return NSError
 */
+ (NSError *)GenErrorCode:(NSInteger)errorCode message:(NSString *)message;

/**
 * @description 格式化私钥
 * @param privateKey 私钥字符串
 * @return NSString 格式化好的私钥
 */
+ (NSString *)formatPrivateKey:(NSString *)privateKey;

/**
 * @description 阿里支付生成签名串
 * @param string 参数字符串
 * @return NSString 返回签名串
 */
+ (NSString *)GenAlipaySignInfoString:(NSString *)string;

/**
 * @description 生成微信支付统一下单的xml字符串
 * @param dicInfo 订单信息
 * @return NSString 返回xml字符串，或者NSError对象
 */
+ (id)GenWechatPayOrderXMLFromInfo:(NSDictionary *)dicInfo;

/**
 * @description 生成微信支付的参数
 * @param dicInfo 传入的参数，
 * @return NSDictionary 返回xml字符串
 */
+ (NSDictionary *)GenWechatPayDictionFromInfo:(NSDictionary *)dicInfo;



@end
