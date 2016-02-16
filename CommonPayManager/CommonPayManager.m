//
//  CommonPayManager.m
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import "CommonPayManager.h"

#import "CommonPayFactory.h"
#import <AlipaySDK/AlipaySDK.h>

#import "WXApi.h"

#import "CommonXMLParser.h"

typedef void(^CallBackBlock)();

@interface CommonPayManager () <WXApiDelegate>
{
    BOOL _bRegisiterWechat;
    
    PaySuccess _wechatPaySuccess;
    PayFail _wechatPayFail;
}

@end


@implementation CommonPayManager

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bRegisiterWechat = NO;
    }
    return self;
}

- (NSInteger)handleUrlInAppDelegate:(NSURL *)url
{
    [WXApi handleOpenURL:url delegate:self];
    
#warning --- todo
    
    return 1;
}



- (void)payInfo:(NSDictionary *)dicInfo payType:(PayType)payType success:(PaySuccess)paySuccess fail:(PayFail)payFail
{
    if (payType == PTAlipay) {
        [self alipayInfo:dicInfo success:paySuccess fail:payFail];
    }
    else if (payType == PTWechat) {
       
        if (!_bRegisiterWechat) {
            
            if (strWeixinAppid.length < 2) {
                payFail([CommonPayFactory GenErrorCode:PFCWechatAppidNil message:@"未设置微信支付appid"]);
                return;
            }
            NSString * strWechatAppid = [strWeixinAppid copy];
            _bRegisiterWechat = [WXApi registerApp:strWechatAppid withDescription:@"commonpay"];
        }
        
        if (![WXApi isWXAppInstalled]) {
//            <key>LSApplicationQueriesSchemes</key><array>    <string>weixin</string></array>
            payFail([CommonPayFactory GenErrorCode:PFCWechatNotInstalled message:@"未安装微信，无法使用微信支付"]);
            return;
        }
        
        if ([dicInfo objectForKey:strKeyWechatPrepayid]) {
            //做支付逻辑
            [self wechatPayForOrder:dicInfo success:paySuccess fail:payFail];
        }
        else {
            //做统一下单逻辑
            [self wechatPayMakeAnOrder:dicInfo success:^(BOOL bResult, NSDictionary *dicInfo) {
                
                
//                paySuccess()
            } fail:^(NSError *error) {
                payFail(error);
            }];
        }
    }
    else {
        payFail([CommonPayFactory GenErrorCode:PFCUnknowPayType message:@"未知支付类型"]);
    }
}


- (void)alipayInfo:(NSDictionary *)dicInfo success:(PaySuccess)paySuccess fail:(PayFail)payFail
{
    if (strSelfAppUrlScheme.length < 2) {
        payFail([CommonPayFactory GenErrorCode:PFCAppSchemeNil message:@"未设置呼叫app的scheme"]);
        return;
    }
    
    if (strAlipayPrivateKey.length < 2) {
        payFail([CommonPayFactory GenErrorCode:PFCPrivateKeyNil message:@"未设置阿里支付私钥"]);
        return;
    }
    
    
    id returnInfoSpec = [CommonPayFactory GenAlipayAllInfoStringFromInfo:dicInfo];
    
    if (nil == returnInfoSpec) {
        
        payFail([CommonPayFactory GenErrorCode:PFCGenAlipayInfoSpecNil message:@"生成订单信息参数字符串错误"]);
        return;
    }
    
    if ([returnInfoSpec isKindOfClass:[NSError class]]) {
        payFail((NSError *)returnInfoSpec);
        return;
    }
    else if (![returnInfoSpec isKindOfClass:[NSString class]])
    {
        payFail([CommonPayFactory GenErrorCode:PFCMakeOrderStringError message:@"生成支付数据错误"]);
        return;
    }
    
    NSString * strSigned = [CommonPayFactory GenAlipaySignInfoString:returnInfoSpec];
    
    if (nil == strSigned) {
        payFail([CommonPayFactory GenErrorCode:PFCGenSignStringNil message:@"生成阿里支付签名串错误"]);
        return;
    }
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       returnInfoSpec, strSigned, @"RSA"];
    
    NSString * strAppScheme = [strSelfAppUrlScheme copy];
    
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:strAppScheme callback:^(NSDictionary *resultDic) {
        NSLog(@"reslut = %@", resultDic);
        if (9000 == [resultDic[@"resultStatus"] integerValue]) {
            paySuccess(YES, resultDic);
        }
        else if ( 6001 == [resultDic[@"resultStatus"] integerValue]) {
            payFail([CommonPayFactory GenErrorCode:PFCReturnUserCancelPay message:@"用户取消支付"]);

        }
        else {
            NSString * strMessage = resultDic[@"memo"];
            if (nil == strMessage || 0 == strMessage.length) {
                strMessage = @"未知错误";
            }
            payFail([CommonPayFactory GenErrorCode:PFCReturnUnknow message:strMessage]);
        }
        
        /*
         {
         memo = "";
         result = "";
         resultStatus = 6001;
         }
         
         
         reslut = {
         memo = "";
         result = "partner=\"2088021469075741\"&seller_id=\"qichepay@sina.cn\"&out_trade_no=\"045U6F27L3IA9ND\"&subject=\"\U6d4b\U8bd5\U6807\U9898\"&body=\"\U6211\U662f\U6d4b\U8bd5\U6570\U636e\"&total_fee=\"0.01\"&notify_url=\"http://www.xxx.com\"&service=\"mobile.securitypay.pay\"&payment_type=\"1\"&_input_charset=\"utf-8\"&it_b_pay=\"30m\"&show_url=\"m.alipay.com\"&success=\"true\"&sign_type=\"RSA\"&sign=\"WrcfWe8nReFoY46Itg0D5aW98YZhryHPDFc6QSN34dfrldFmHkpo62UCEB87UROQoNmLe1BeGqmhXxGzwiAH/dR/7ugBLRRh4suGh0u8t66y/1zvmpR2ltXHCWWb8Kh2XZqbHcobBib9pX3RJT60M0IUbC5gqzHk7N1fs2odsnI=\"";
         resultStatus = 9000;
         }
         */
        
        
    }];
}


- (void)wechatPayMakeAnOrder:(NSDictionary *)dicInfo success:(PaySuccess)orderSuccess fail:(PayFail)orderFail
{
    id strGenOrderXML = [CommonPayFactory GenWechatPayOrderXMLFromInfo:dicInfo];
 
    if ([strGenOrderXML isKindOfClass:[NSError class]]) {
        orderFail((NSError *)strGenOrderXML);
        return;
    }
    else if (![strGenOrderXML isKindOfClass:[NSString class]]) {
        orderFail([CommonPayFactory GenErrorCode:PFCMakeOrderStringError message:@"生成订单xml数据错误"]);
        return;
    }
    
    NSString * strPostOrder = @"https://api.mch.weixin.qq.com/pay/unifiedorder";
    
    NSMutableURLRequest * muRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strPostOrder]];
    
    NSString * strContentLength = [NSString stringWithFormat:@"%lu", (unsigned long)[(NSString *)strGenOrderXML length]];
    
    [muRequest setHTTPMethod:@"POST"];
    //设置数据类型
    [muRequest addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    //设置编码
    [muRequest setValue:@"UTF-8" forHTTPHeaderField:@"charset"];
    [muRequest setValue:strContentLength forHTTPHeaderField:@"Content-length"];
    
    [muRequest setHTTPBody:[strGenOrderXML dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"post xml string is:%@", strGenOrderXML);
    [NSURLConnection sendAsynchronousRequest:muRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
//        NSLog(@"response is:%@", response);
        NSString * strReturn = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"will parser string is:%@", strReturn);
        
        [[CommonXMLParser paser] parserString:strReturn findkey:^(NSString *strKey, NSArray *keysPath) {
            
        } completion:^(BOOL bFinish, NSDictionary *dicResult) {
            if (bFinish) {
                NSLog(@"make order return obj is:%@", dicResult);
                
                if ([@"FAIL" isEqualToString:dicResult[@"return_code"]]) {
                    orderFail([CommonPayFactory GenErrorCode:PFCWechatOrderReturnError message:dicResult[@"return_msg"]]);
                }
                else if([@"SUCCESS" isEqualToString:dicResult[@"return_code"]]) {
                    [self wechatPayForOrder:@{strKeyWechatPrepayid : dicResult[@"prepay_id"]} success:orderSuccess fail:orderFail];
                }
                else {
                    orderFail([CommonPayFactory GenErrorCode:PFCWechatOrderReturnError message:@"未知返回错误"]);
                }
            }
        }];
    }];
}

- (void)wechatPayForOrder:(NSDictionary *)dicInfo success:(PaySuccess)paySuccess fail:(PayFail)payFail
{
    if (nil == dicInfo[strKeyWechatPrepayid]) {
        payFail([CommonPayFactory GenErrorCode:PFCWechatPrepayIdNil message:@"未找到prepayid"]);
        return;
    }
    
    
    NSDictionary * dicPayInfo = [CommonPayFactory GenWechatPayDictionFromInfo:dicInfo];
//    NSLog(@"pay info is:%@", dicPayInfo);
    //调起微信支付
    PayReq * req  = [[PayReq alloc] init];
    
    req.openID    = [dicPayInfo objectForKey:@"appid"];
    req.partnerId = [dicPayInfo objectForKey:@"partnerid"];
    req.prepayId  = [dicPayInfo objectForKey:@"prepayid"];
    req.nonceStr  = [dicPayInfo objectForKey:@"noncestr"];
    req.timeStamp = [[dicPayInfo objectForKey:@"timestamp"] intValue];
    req.package   = [dicPayInfo objectForKey:@"package"];
    req.sign      = [dicPayInfo objectForKey:@"sign"];
    
    [WXApi sendReq:req];
    
    _wechatPaySuccess = paySuccess;
    _wechatPayFail = payFail;
}


#pragma mark - WXApiDelegate
- (void)onReq:(BaseReq*)req
{
    
}

- (void)onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
        
        switch (resp.errCode) {
            case WXSuccess:
            {
                if (_wechatPaySuccess) {
                    _wechatPaySuccess(YES, @{@"code": @(resp.errCode)});
                }
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
            }
                break;
                
            default:
            {
//                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                if (_wechatPayFail) {
                    
                    switch (resp.errCode) {
                        case -2:
                            _wechatPayFail([CommonPayFactory GenErrorCode:PFCReturnUserCancelPay message:@"用户取消支付"]);
                            break;
                            
                        default:
                            break;
                    }
                    
                }
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode, resp.errStr);
            }
                break;
        }
    }
    
}


@end
