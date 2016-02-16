//
//  CommonPayManager.h
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, PayType)
{
    PTAlipay = 0,
    PTWechat = 1,
};

typedef NS_ENUM(NSInteger, PayFailCode)
{
    PFCUnknowPayType            = 100,
    PFCAliPartnerOrSellerNil    = 101,
    PFCPrivateKeyNil            = 102,
    PFCAppSchemeNil             = 103,
    PFCGenOrderStringnil        = 104,
    PFCLackTradeArguments       = 110,
    PFCGenSignStringNil         = 120,
    
    PFCGenAlipayInfoSpecNil     = 130,

    PFCMakeOrderStringError     = 140,
    
    PFCWechatAppidNil           = 150,
    PFCWechatPrepayIdNil        = 154,
    PFCWechatPayInfoError       = 156,
    PFCWechatOrderReturnError   = 159,
    
    PFCWechatNotInstalled       = 190,
    
    PFCReturnUserCancelPay      = 205,
    
    PFCReturnUnknow             = 220,
};


static const NSString * strKeyTradeNumber = @"cp.tradeno";//订单号，必填项

static const NSString * strKeyTradeInfo = @"cp.info";//商品描述，必填项

static const NSString * strKeyTradeCost = @"cp.cost";//商品价格，必填项

static const NSString * strKeyTradeNotifyUrl = @"cp.notifyurl";//通知的url，必填项

static const NSString * strKeyTradeDetail = @"cp.detail";//商品详情

static const NSString * strKeyTradeOtherInfo = @"cp.otherinfo";//其他信息，字典类型

static const NSString * strKeyWechatPrepayid = @"cp.prepayid";//微信的prepayid，如果服务端做了统一下单，可以直接传这个id来支付。如果没有该字段，则客户端做统一下单。

typedef void(^PaySuccess)(BOOL bResult, NSDictionary * dicInfo);

typedef void(^PayFail)(NSError * error);


@interface CommonPayManager : NSObject


/**
 * @description 统一支付的单例对象
 * @param
 * @return
 */

+ (instancetype)sharedInstance;


/**
 * @description 通过url回调回来的url处理
 * @param url 传入url
 * @return NSInteger 返回 0 - NO, 1 - YES , -1 - 由其他程序处理
 */
- (NSInteger)handleUrlInAppDelegate:(NSURL *)url;


/**
 * @description 支付调用
 * @param dicInfo 支付信息
 * @param paytype 支付类型
 * @param paySuccess 支付成功的回调
 * @param payFail 支付失败的回调
 * @return
 */
- (void)payInfo:(NSDictionary *)dicInfo payType:(PayType)payType success:(PaySuccess)paySuccess fail:(PayFail)payFail;



/** Toto list
 *  1.支付宝成功和失败的回调没有加
 *  2.微信支付的统一下单没有appid，没有测试
 *  3.微信支付整个流程需要等appid来了统一跑一下
 *  4.把微信和支付宝的返回码做一下转码
 *
 *
 */





@end
