//
//  CommonPayFactory.m
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import "CommonPayFactory.h"

#import "CommonPayManager.h"
#import "openssl_wrapper.h"

//get ip
#include <ifaddrs.h>
#include <arpa/inet.h>

//md5
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "CommonXMLParser.h"

NSString * strCommonPayDomain = @"com.yangch.commonpay";

@implementation CommonPayFactory

+ (id)GenAlipayAllInfoStringFromInfo:(NSDictionary *)dicInfo
{
    if (strAlipayPartner.length < 2 || strAlipaySeller.length < 2 || dicInfo.count == 0) {
        return [[self class] GenErrorCode:PFCAliPartnerOrSellerNil message:@"缺少支付宝partnerid或sellerid"];
    }
    
    if (nil == dicInfo[strKeyTradeNumber] || nil == dicInfo[strKeyTradeInfo] || nil == dicInfo[strKeyTradeCost] || nil == dicInfo[strKeyTradeNotifyUrl]){
        return [[self class] GenErrorCode:PFCLackTradeArguments message:@"缺少支付参数"];
    }
    
    NSMutableString * muString = [NSMutableString string];
    
    [muString appendFormat:@"partner=\"%@\"", strAlipayPartner];
    [muString appendFormat:@"&seller_id=\"%@\"", strAlipaySeller];
    
    if ([dicInfo objectForKey:strKeyTradeNumber]) {
        [muString appendFormat:@"&out_trade_no=\"%@\"", [dicInfo objectForKey:strKeyTradeNumber]];
    }
    
    if ([dicInfo objectForKey:strKeyTradeInfo]) {
        [muString appendFormat:@"&subject=\"%@\"", [dicInfo objectForKey:strKeyTradeInfo]];
    }
    
    if ([dicInfo objectForKey:strKeyTradeDetail]) {
        [muString appendFormat:@"&body=\"%@\"", [dicInfo objectForKey:strKeyTradeDetail]];
    }
    
    if ([dicInfo objectForKey:strKeyTradeCost]) {
        [muString appendFormat:@"&total_fee=\"%@\"", [dicInfo objectForKey:strKeyTradeCost]];
    }
    
    if ([dicInfo objectForKey:strKeyTradeNotifyUrl]) {
        [muString appendFormat:@"&notify_url=\"%@\"", [dicInfo objectForKey:strKeyTradeNotifyUrl]];
    }
    
    [muString appendFormat:@"&service=\"%@\"", @"mobile.securitypay.pay"];//mobile.securitypay.pay

    [muString appendFormat:@"&payment_type=\"%@\"", @"1"];//1
        
    [muString appendFormat:@"&_input_charset=\"%@\"", @"utf-8"];//utf-8
    
    [muString appendFormat:@"&it_b_pay=\"%@\"", @"30m"];//30m

    [muString appendFormat:@"&show_url=\"%@\"", @"m.alipay.com"];//m.alipay.com

    id dicOtherInfo = [dicInfo objectForKey:strKeyTradeOtherInfo];
    
    if (nil != dicOtherInfo && [dicOtherInfo isKindOfClass:[NSDictionary class]]) {
        for (NSString * strKey in [(NSDictionary *) dicOtherInfo allKeys]) {
            [muString appendFormat:@"&%@=\"%@\"", strKey, [(NSDictionary *)dicOtherInfo objectForKey:strKey]];
        }
    }
    
    return muString;
}


+ (NSError *)GenErrorCode:(NSInteger)errorCode message:(NSString *)message
{
    if (nil == message) {
        message = @"no message";
    }
    
    return [NSError errorWithDomain:strCommonPayDomain code:errorCode userInfo:@{@"message" : message}];
}


+ (NSString *)formatPrivateKey:(NSString *)privateKey
{
    const char *pstr = [privateKey UTF8String];
    NSInteger len = [privateKey length];
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"-----BEGIN PRIVATE KEY-----\n"];
    int index = 0;
    int count = 0;
    while (index < len) {
        char ch = pstr[index];
        if (ch == '\r' || ch == '\n') {
            ++index;
            continue;
        }
        [result appendFormat:@"%c", ch];
        if (++count == 64)
        {
            [result appendString:@"\n"];
            count = 0;
        }
        index++;
    }
    [result appendString:@"\n-----END PRIVATE KEY-----"];
    return result;
}


+ (NSString *)GenAlipaySignInfoString:(NSString *)string
{
    NSString * signedString = nil;
    
    NSString * strPrivateKey = [strAlipayPrivateKey copy];
    
    NSString *formatKey = [[self class] formatPrivateKey:strPrivateKey];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentPath stringByAppendingPathComponent:@"CommonPay-Alipay-RSAPrivateKey"];
    [formatKey writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    const char *message = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSInteger messageLength = strlen(message);
    unsigned char *sig = (unsigned char *)malloc(256);
    unsigned int sig_len;
    int ret = rsa_sign_with_private_key_pem((char *)message, (int)messageLength, sig, &sig_len, (char *)[path UTF8String]);
    //签名成功,需要给签名字符串base64编码和UrlEncode,该两个方法也可以根据情况替换为自己函数
    if (ret == 1) {
        NSString * base64String = base64StringFromData([NSData dataWithBytes:sig length:sig_len]);
        //NSData * UTF8Data = [base64String dataUsingEncoding:NSUTF8StringEncoding];
        signedString = [self urlEncodedString:base64String];
    }
    
    free(sig);
    return signedString;
}

+ (NSString*)urlEncodedString:(NSString *)string
{
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}


+ (id)GenWechatPayOrderXMLFromInfo:(NSDictionary *)dicInfo
{
//    按照文档要求appid，mch_id，nonce_str，sign，body，out_trade_no，total_fee，spbill_create_ip，notify_url，trade_type这十个参数是必须的
//    其中appid，mch_id是微信给的；trade_type传定值APP；nonce_str，spbill_create_ip是直接在手机上获取到的；body，out_trade_no，total_fee这三个是从服务端上获取的数据。sign根据以上键值对按照签名规则得到的。
    
    if (nil == dicInfo[strKeyTradeNumber] || nil == dicInfo[strKeyTradeInfo] || nil == dicInfo[strKeyTradeCost] || nil == dicInfo[strKeyTradeNotifyUrl]) {
        
        return [[self class] GenErrorCode:PFCLackTradeArguments message:@"缺少支付参数"];
    }
    
    if (strWeixinApiKey.length < 2) {
        
        return [[self class] GenErrorCode:PFCPrivateKeyNil message:@"缺少微信支付的商家key"];
    }
    
    NSMutableDictionary * dicFormated = [NSMutableDictionary dictionary];
    
    NSString * strAppid = [strWeixinAppid copy];
    NSString * strMchid = [strWeixinMchid copy];
    
    [dicFormated setObject:strAppid forKey:@"appid"];
    [dicFormated setObject:strMchid forKey:@"mch_id"];
    [dicFormated setObject:@"APP" forKey:@"trade_type"];
    
    [dicFormated setObject:[[self class] genRandomStringLength:15] forKey:@"nonce_str"];
    [dicFormated setObject:[[self class] getdeviceIPAdress] forKey:@"spbill_create_ip"];
    
    [dicFormated setObject:dicInfo[strKeyTradeNumber] forKey:@"out_trade_no"];
    
    [dicFormated setObject:dicInfo[strKeyTradeInfo] forKey:@"body"];
    
    NSInteger iFee = ([dicInfo[strKeyTradeCost] floatValue] * 100);//微信单位为分
    
    [dicFormated setObject:@(iFee) forKey:@"total_fee"];
    [dicFormated setObject:dicInfo[strKeyTradeNotifyUrl] forKey:@"notify_url"];

    NSString * strSign = [[self class] genWechatSignFromInfo:dicFormated];
    
    if (nil == strSign) {
        return [[self class] GenErrorCode:PFCGenSignStringNil message:@"签名校验错误"];
    }
    
    [dicFormated setObject:strSign forKey:@"sign"];
    
    return [CommonXMLParser GenStringFromObject:@{@"xml" : dicFormated} order:YES];
}

+ (NSDictionary *)GenWechatPayDictionFromInfo:(NSDictionary *)dicInfo
{
    NSMutableDictionary * muPayInfo = [NSMutableDictionary dictionary];
    
    NSString * strAppid = [strWeixinAppid copy];
    NSString * strMchid = [strWeixinMchid copy];
    
    [muPayInfo setObject:strAppid forKey:@"appid"];
    [muPayInfo setObject:strMchid forKey:@"partnerid"];
    [muPayInfo setObject:[dicInfo objectForKey:strKeyWechatPrepayid] forKey:@"prepayid"];
    
    [muPayInfo setObject:[[self class] genRandomStringLength:15] forKey:@"noncestr"];
    [muPayInfo setObject:@"Sign=WXPay" forKey:@"package"];
    [muPayInfo setObject:@((NSInteger)[[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];
    
    NSString * strSign = [self genWechatSignFromInfo:muPayInfo];
    
    [muPayInfo setObject:strSign forKey:@"sign"];
        
    return muPayInfo;
}


+ (NSString *)genWechatSignFromInfo:(NSDictionary *)dicOrderInfo
{
    NSArray * arrAllKey = [dicOrderInfo allKeys];
    arrAllKey = [arrAllKey sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableString * mString = [NSMutableString string];
    
    for (NSString * strkey in arrAllKey) {
        [mString appendFormat:@"%@=%@&", strkey, dicOrderInfo[strkey]];
    }
    
    NSString * strWechatKey = [strWeixinApiKey copy];
    
    [mString appendFormat:@"key=%@", strWechatKey];

    return [[[self class] md5Sign:mString] uppercaseString];
}

+ (NSString *)md5Sign:(NSString *)strInput
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    const void * cchat = [strInput UTF8String];
    
    CC_MD5( cchat, (CC_LONG)strlen(cchat), digest );
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return [result uppercaseString];
}


+ (NSString *)genRandomStringLength:(NSInteger)iLength
{
    if (iLength > 30) {
        iLength = 30;
    }
    else if (iLength <= 0) {
        return nil;
    }
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [NSMutableString string];
    srand((unsigned int)time(0));
    for (int i = 0; i < iLength; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    
    return resultStr;
}

//获取本机ip地址
+ (NSString *)getdeviceIPAdress
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                
                //NSLog(@"net interface name is:%s", temp_addr->ifa_name);
                // Check if interface is en0 which is the wifi connection on the iPhone
                
#if TARGET_IPHONE_SIMULATOR
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en1"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
#else
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
#endif
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return address;
}




@end
