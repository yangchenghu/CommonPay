//
//  ViewController.m
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import "ViewController.h"

#import "CommonPayManager.h"



#import "CommonPayFactory.h"

#import "CommonXMLParser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    NSString * strXml = @"<xml>\
//    <notify_url>http://www.xxx.com</notify_url>\
//    <spbill_create_ip>10.209.64.246</spbill_create_ip>\
//    <mch_id>1244424302</mch_id>\
//    <trade_type>APP</trade_type>\
//    <nonce_str>1853822458</nonce_str>\
//    <out_trade_no>OW0D03FBBICJ16K</out_trade_no>\
//    <total_fee>1</total_fee>\
//    <test>\
//    <appid>wxe8c622ad7ec409b7</appid>\
//    <body>测试标题</body>\
//    </test>\
//    <sign>BFFC3B91DC04E7123661E6565873109F</sign>\
//    </xml>";
//    
//    [[CommonXMLParser paser] parserString:strXml findkey:^(NSString *strKey, NSArray *keysPath) {
//        
//    } completion:^(BOOL bFinish, NSDictionary *dicResult) {
//        NSLog(@"result is;%@", dicResult);
//        NSLog(@"-----");
//        
//    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)payAction:(id)sender
{
    
    NSString * strOrder = [self generateTradeNO];

    NSDictionary * dicOrder = @{strKeyTradeNumber   : strOrder,
                                strKeyTradeInfo     : @"测试标题",
                                strKeyTradeDetail   : @"我是测试数据",
                                strKeyTradeCost     : @"0.01",
                                strKeyTradeNotifyUrl : @"http://www.xxx.com",
                               };
    
    if (_segmenteedControl.selectedSegmentIndex == 0) {
        [[CommonPayManager sharedInstance] payInfo:dicOrder payType:PTAlipay success:^(BOOL bResult, NSDictionary * dicInfo){
            
        } fail:^(NSError *error) {
            NSLog(@"error is:%@", error);
        }];
        
    }
    else {
//        [[CommonPayManager sharedInstance] payInfo:@{strKeyWechatPrepayid : @"wx20160203140344614ae43b930874823604"} payType:PTWechat success:^(BOOL bResult, NSDictionary * dicInfo){
//            
//        } fail:^(NSError *error) {
//            NSLog(@"error is:%@", error);
//        }];
        
        [[CommonPayManager sharedInstance] payInfo:dicOrder payType:PTWechat success:^(BOOL bResult, NSDictionary * dicInfo){
            
        } fail:^(NSError *error) {
            NSLog(@"error is:%@", error);
        }];

    }
    
}

- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned int)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

- (void)rsaTest
{
    NSString * strInput = @"0123456789abc";
    
    NSString * strOutput = [CommonPayFactory GenAlipaySignInfoString:strInput];
    
    NSLog(@"out put is:%@", strOutput);
}


@end
