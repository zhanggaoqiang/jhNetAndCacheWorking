//
//  JHNetWorkHelper.m
//  jhNetAndCacheWorking
//
//  Created by zih on 2018/3/20.
//  Copyright © 2018年 zih. All rights reserved.
//

#import "JHNetWorkHelper.h"
#import "AFNetworkActivityIndicatorManager.h"
#ifdef DEBUG
#define MLLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define MLLog(...)
#endif

@implementation JHNetWorkHelper

static BOOL _isOpenLog;  // 是否已开启日志打印
static NSMutableArray* _allSessionTask;
static AFHTTPSessionManager * _sessionManager;

#pragma mark - 开始监听网络
+(void)networkStatusWithBlock:(JHNetworkStatus)networkStatus
{
    [[AFNetworkReachabilityManager sharedManager]setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                networkStatus ? networkStatus(JHNetworkStatusUnknown):nil;
                if (_isOpenLog) MLLog(@"未知网络");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus ? networkStatus(JHNetworkStatusNotReachable):nil;
                if (_isOpenLog) MLLog(@"无网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus ? networkStatus(JHNetworkStatusReachableViaWWAN):nil;
                if (_isOpenLog) MLLog(@"手机自带网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus ? networkStatus(JHNetworkStatusReachableViaWIFI):nil;
                if (_isOpenLog) MLLog(@"WIFI");
                break;
            default:
                break;
        }
    }];
}
+(BOOL)isNetwork
{
   return [AFNetworkReachabilityManager sharedManager].reachable;
}
+(BOOL)isWWANNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}
+(BOOL)isWIFINetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}
+(void)openLog
{
    _isOpenLog = YES;
}
+(void)closeLog
{
    _isOpenLog = NO;
}
+(void)cancelAllRequset
{
    //锁操作
    @synchronized(self){
        [[self  allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask]removeAllObjects];
    }
}
+(void)cancelRequestWithURL:(NSString *)URL
{
    if (URL) {return;}
    @synchronized(self){
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask]removeObject:task];
                *stop = YES;
            }
        }];
    }
}
#pragma mark - GET请求无缓存
+(NSURLSessionTask *)GET:(NSString *)URL parameters:(id)parameters success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}
#pragma mark - POST请求无缓存
+(NSURLSessionTask *)POST:(NSString *)URL parameter:(id)parameters success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    return [self POST:URL parameter:parameters responseCache:nil success:success failure:failure];
}
#pragma mark - GET请求自动缓存
+(NSURLSessionTask *)GET:(NSString *)URL parameters:(id)parameters responseCache:(JHHttpRequestCache)responseCache success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    //读取缓存
    responseCache!=nil ? responseCache([JHNetWorkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
    NSURLSessionTask* sessionTask = [_sessionManager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (_isOpenLog) {MLLog(@"responseObject = %@",responseObject);}
        [[self allSessionTask]removeObject:task];
        success ? success(responseObject):nil;
        //对数据进行异步缓存
        responseCache!= nil ? [JHNetWorkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {MLLog(@"error = %@",error);}
        [[self allSessionTask]removeObject:task];
        failure ? failure(error) : nil;
    }];
    //添加sessionTask到session数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}
#pragma mark - POST请求自动缓存
+(NSURLSessionTask *)POST:(NSString *)URL parameter:(id)parameters responseCache:(JHHttpRequestCache)responseCache success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    //读取缓存
    responseCache!=nil ?responseCache([JHNetWorkCache httpCacheForURL:URL parameters:parameters]):nil;
    NSURLSessionTask* sessionTask = [_sessionManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (_isOpenLog) {MLLog(@"response = %@",responseObject);}
        [[self allSessionTask]removeObject:task];
        success?success(responseObject):nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {MLLog(@"error = %@",error);}
        [[self allSessionTask]removeObject:task];
        failure?failure(error):nil;
    }];
    //添加sessionTask到session数组
    sessionTask ? [[self allSessionTask]addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - 上传文件
+(NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameter:(id)parameters name:(NSString *)name filepath:(NSString *)filepath progress:(JHHttpProgress)progress success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    NSURLSessionTask* sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError* error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filepath] name:name error:&error];
        (failure && error)?failure(error): nil;
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress?progress(uploadProgress):nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (_isOpenLog) {MLLog(@"reponseObject = %@",responseObject);}
        [[self allSessionTask]removeObject:task];
        success?success(responseObject):nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {MLLog(@"error = %@",error);}
        [[self allSessionTask]removeObject:task];
        failure?failure(error):nil;
    }];
    //添加session到数组
    sessionTask ? [[self allSessionTask]addObject:sessionTask] :nil;
    
    return sessionTask;
}
#pragma mark - 上传图片
+(NSURLSessionTask *)uploadImageWithURL:(NSString *)URL parameters:(id)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageSize:(CGFloat)imageScale imageType:(NSString *)imageType progress:(JHHttpProgress)progress success:(JHHttpRequestSuccess)success failure:(JHHttpRequestFailed)failure
{
    NSURLSessionTask* sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i<images.count; i++) {
            //图片经过等比压缩的二进制文件
            NSData* imageData = UIImageJPEGRepresentation(images[i], imageScale?:1.f);
            //默认的图片文件名，若fileNames为nil就使用
            NSDateFormatter* formmatter = [[NSDateFormatter alloc]init];
            formmatter.dateFormat  = @"yyyyMMddHHmmss";
            NSString* str = [formmatter stringFromDate:[NSDate date]];
            NSString* imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            [formData appendPartWithFileData:imageData name:name fileName:fileNames?[NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"]:imageFileName mimeType:[NSString stringWithFormat:@"image/%@",imageType?:@"jpg"]];
        }
       
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress?progress(uploadProgress):nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (_isOpenLog) {MLLog(@"reponseObject = %@",responseObject);}
        [[self allSessionTask]removeObject:task];
        success?success(responseObject):nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {MLLog(@"error = %@",error);}
        [[self allSessionTask]removeObject:task];
        failure?failure(error):nil;
    }];
    sessionTask ? [[self allSessionTask]addObject:sessionTask] : nil;
    
    return sessionTask;
}
+(NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progress:(JHHttpProgress)progress success:(void (^)(NSString *))success failure:(JHHttpRequestFailed)failure
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask* downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress?progress(downloadProgress):nil;
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString* downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:fileDir?fileDir:@"Download"];
        //打开文件管理器
        NSFileManager* fileManager = [NSFileManager defaultManager];
        //创建download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString* filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask]removeObject:downloadTask];
        if (failure && error) {failure(error); return;}
        success?success(filePath.absoluteString /** NSURL->NSString*/):nil;
    }];
    //开始下载
    [downloadTask resume];
    //添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    
    return downloadTask;
}


/**
  存储着所有请求的task数组
 */
+(NSMutableArray*)allSessionTask
{
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc]init];
    }
    return _allSessionTask;
}
#pragma mark - 初始化AFHTTPSessionManager的相关属性

/**
 开始监测网络状态
 */
+(void)load{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 所有的HTTP请求共享一个AFHTTPSessionManager
 原理参考地址：http://www.jianshu.com/p/5969bbb4af9f
 */
+(void)initialize
{
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    //打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 重置AFHTTPSessionManager相关属性

+(void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager
{
    sessionManager ? sessionManager(_sessionManager) : nil;
}

+(void)setRequestSerializer:(JHRequestSerializer)requsetSerializer
{
    _sessionManager.requestSerializer = requsetSerializer == JHRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+(void)setResponseSerializer:(JHResponseSerializer)responseSerializer
{
    _sessionManager.responseSerializer = responseSerializer == JHRequestSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}
+(void)setRequsetTimeoutInterval:(NSTimeInterval)time
{
    _sessionManager.requestSerializer.timeoutInterval = time;
}
+(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}
+(void)openNetworkActivityIndicator:(BOOL)open
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}
+(void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName
{
    NSData* cerData = [NSData dataWithContentsOfFile:cerPath];
    //使用证书验证模式
    AFSecurityPolicy* securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    //如果需要验证自建证书（无效证书），需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    //是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc]initWithObjects:cerData, nil];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
}

@end
#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (ML)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (ML)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end
#endif
