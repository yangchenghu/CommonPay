//
//  CommonXMLParser.m
//  CommonPay
//
//  Created by yangchenghu on 16/1/5.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import "CommonXMLParser.h"

@interface CommonXMLParser ()
{
    NSXMLParser * _xmlParser;
    
    NSString * _strItemKey;
    
    NSMutableDictionary * _muDicReslut;
    
    NSMutableArray * _muArrContainerStack;//堆栈，找到父节点
    
    NSMutableDictionary * _mDicPointer;//指针
    
    NSMutableArray * _muArrKeysStack;
    
    FindKey _findKeyBlock;
    
    Completion _completionBlock;
}

@end

@implementation CommonXMLParser

+ (instancetype)paser
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (NSString *)GenStringFromObject:(NSDictionary *)dicObj order:(BOOL)order
{
    NSArray * arrKeys = [dicObj allKeys];
    if (order) {
        arrKeys = [arrKeys sortedArrayUsingSelector:@selector(compare:)];
    }
    
    NSMutableString * mString = [NSMutableString string];
    
    for (NSString * strKey in arrKeys) {
        
        if ([dicObj[strKey] isKindOfClass:[NSDictionary class]]) {
            [mString appendFormat:@"\n<%@>\n%@\n</%@>", strKey, [self GenStringFromObject:dicObj[strKey] order:order], strKey];
        }
        else {
            [mString appendFormat:@"<%@>%@</%@>", strKey, dicObj[strKey], strKey];
        }
    }
    
    return mString;
}


- (void)parserString:(NSString *)string findkey:(FindKey)findkeyblock completion:(Completion)completionblock
{
    if (nil == _muDicReslut) {
        _muDicReslut = [NSMutableDictionary dictionary];
    }
    
    if (nil == _muArrContainerStack) {
        _muArrContainerStack = [NSMutableArray array];
    }
    
    if (nil == _muArrKeysStack) {
        _muArrKeysStack = [NSMutableArray array];
    }
    
    if (nil != _xmlParser) {
        _xmlParser = nil;
    }
    
    _xmlParser = [[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_xmlParser setDelegate:self];
    
    _findKeyBlock = [findkeyblock copy];
    
    _completionBlock = [completionblock copy];
    
    [_xmlParser parse];
}


#pragma mark - NSXMLParserDelegate
- (void)parserDidStartDocument:(NSXMLParser *)parser{
    [_muDicReslut removeAllObjects];
    [_muArrContainerStack removeAllObjects];
    [_muArrKeysStack removeAllObjects];
    
    _mDicPointer = _muDicReslut;
    
    [_muArrContainerStack addObject:_mDicPointer];
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    if ([@"xml" isEqualToString:elementName]) {
        return;
    }
    
    _strItemKey = [elementName copy];
    
    if (0 !=  _muArrKeysStack.count) {
        if (nil == _mDicPointer[_muArrKeysStack.lastObject]) {
            NSMutableDictionary * muDicTemp = [NSMutableDictionary dictionary];
            _mDicPointer[_muArrKeysStack.lastObject] = muDicTemp;
            _mDicPointer = muDicTemp;
            [_muArrContainerStack addObject:_mDicPointer];
        }
        else {
            [_muArrContainerStack addObject:_mDicPointer];
            _mDicPointer = _mDicPointer[_muArrKeysStack.lastObject];
        }
    }
    
    [_muArrKeysStack addObject:_strItemKey];
    
    if (_findKeyBlock) {
        _findKeyBlock(_strItemKey, [_muArrKeysStack copy]);
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    
    if ([@"\n" isEqualToString:string] || [@"\r" isEqualToString:string]) {
        return;
    }
    
    NSInteger iSpaceCout = 0;
    for (NSInteger i = 0 ; i < string.length ; i ++) {
        NSString * strChart = [string substringWithRange:NSMakeRange(i, 1)];
        
        if (![@" " isEqualToString:strChart]) {
            string = [string substringFromIndex:i];
            break;
        }
        
        iSpaceCout++;
    }
    if (iSpaceCout != string.length) {
        [_mDicPointer setObject:string forKey:_strItemKey];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([@"xml" isEqualToString:elementName]) {
        return;
    }
    
    if (_muArrContainerStack.count != 0) {
        [_muArrContainerStack removeLastObject];
        _mDicPointer = [_muArrContainerStack lastObject];
        
        if (nil == _mDicPointer) {
            _mDicPointer = _muDicReslut;
        }
    }
    
    if (_muArrKeysStack.count != 0) {
        [_muArrKeysStack removeLastObject];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    if (0 != _muDicReslut.count) {
        _completionBlock(YES, [_muDicReslut copy]);
    }
    else {
        _completionBlock(NO, nil);
    }
    
    [_muDicReslut removeAllObjects];
    [_muArrContainerStack removeAllObjects];
    [_muArrKeysStack removeAllObjects];
}




@end
