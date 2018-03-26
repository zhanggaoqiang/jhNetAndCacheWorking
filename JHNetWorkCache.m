//
//  JHNetWorkCache.m
//  jhNetAndCacheWorking
//
//  Created by zih on 2018/3/20.
//  Copyright © 2018年 zih. All rights reserved.
//

#import "JHNetWorkCache.h"
#import "YYCache.h"

static NSString* const kJHNetworkResponseCache = @"kJHNetworkResponseCache";

@implementation JHNetWorkCache

static YYCache* _dataCache;

+(void)initialize{
    _dataCache = [YYCache cacheWithName:kJHNetworkResponseCache];
}
+(void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(id)parameters
{
    NSString* cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    //异步缓存，不会阻塞主线程
    [_dataCache setObject:httpData forKey:cacheKey withBlock:nil];
}
+(id)httpCacheForURL:(NSString *)URL parameters:(id)parameters
{
    NSString* cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    return [_dataCache objectForKey:cacheKey];
}
+(NSInteger)getAllHttpCacheSize
{
    return [_dataCache.diskCache totalCost];
}
+(void)removeAllHttpCache
{
    [_dataCache.diskCache removeAllObjects];
}
+(NSString*)cacheKeyWithURL:(NSString*)URL parameters:(NSDictionary*)parameters{
    if (!parameters || parameters.count == 0) {
        return URL;
    }
    //将参数字典转化成字符串
    NSData* stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString* paraString = [[NSString alloc]initWithData:stringData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@%@",URL,paraString];
}
@end
