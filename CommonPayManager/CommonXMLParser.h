//
//  CommonXMLParser.h
//  CommonPay
//
//  Created by yangchenghu on 16/1/5.
//  Version:0.1
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Completion)(BOOL bFinish, NSDictionary * dicResult);

typedef void(^FindKey)(NSString * strKey, NSArray * keysPath);

@interface CommonXMLParser : NSObject <NSXMLParserDelegate>

/**
 * @description 初始化
 * @param
 * @return
 */
+ (instancetype)paser;

/**
 * @description 将xml的string处理成对象
 * @param string xml的字符串
 * @param fliterkeyblock 关键词过滤器
 * @param completionblock 完成时的回调
 * @return
 */
- (void)parserString:(NSString *)string findkey:(FindKey)findkeyblock completion:(Completion)completionblock;

/**
 * @description 将对象序列化成xml字符串
 * @param dicObj 传入的对象
 * @param order 是否按照key的字母顺序排序
 * @return NSString 返回xml的字符串
 */
+ (NSString *)GenStringFromObject:(NSDictionary *)dicObj order:(BOOL)order;

@end
