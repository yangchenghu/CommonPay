//
//  CommonPayDefine.h
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#ifndef CommonPayDefine_h
#define CommonPayDefine_h

#import <Foundation/Foundation.h>

//---------- 接入说明 ----------


//---------- 支付宝支付 ------------

/* 1.引入框架 libz.tbd，libc++.tbd，CoreMotion.framework，CoreTelephony.framework，SystemConfiguration.framework
 * 2.引入支付宝sdk
 * 3.设置程序的url scheme，将该scheme放到下面的strSelfAppUrlScheme 中，方便支付宝回调呼起app
 * 4.填写partner，seller，和privatekey
 */

static const NSString * strAlipayPartner = @"";
static const NSString * strAlipaySeller = @"";
static const NSString * strAlipayPrivateKey = @"";

//需按自己app进行修改，支付完成后，支付宝呼起程序
static const NSString * strSelfAppUrlScheme = @"commonpayalipay";

//----------微信支付------------

/* 1.引入框架 libz.tbd，libsqlite3.0.tbd，SystemConfiguration.framework
 * 2.引入微信sdk
 * 3.填写appid，mchid和对应的key
 * 4.设置程序的url scheme为微信的appid，方便支付完成后呼起程序
 */

//微信appid
static const NSString * strWeixinAppid = @"";

//商户号，统一下单使用
static const NSString * strWeixinMchid = @"";

//加密签名的key
static const NSString * strWeixinApiKey = @"";

#endif /* CommonPayDefine_h */
