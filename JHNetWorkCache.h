//
//  JHNetWorkCache.h
//  jhNetAndCacheWorking
//
//  Created by zih on 2018/3/20.
//  Copyright © 2018年 zih. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma mark - 网络数据缓存类
@interface JHNetWorkCache : NSObject

/**
 异步缓存网络数据，根据请求的URL和parameters
 做key数据存储，这样就能缓存多级页面的数据

 @param httpData 服务器返回的数据
 @param URL 请求的URL地址
 @param parameters 请求的参数
 */
+(void)setHttpCache:(id)httpData URL:(NSString*)URL parameters:(id)parameters;

/**
 根据请求的URL和parameters同步取出缓存数据

 @param URL 请求的URL
 @param parameters 请求的参数
 @return 缓存的服务器数据
 */
+(id)httpCacheForURL:(NSString*)URL parameters:(id)parameters;

// 获取网络缓存的总大小 bytes(字节)
+(NSInteger)getAllHttpCacheSize;

// 删除所有网络缓存
+(void)removeAllHttpCache;
@end
