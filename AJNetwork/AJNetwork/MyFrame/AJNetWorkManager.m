//
//  AJNetWorkManager.m
//  AJNetwork
//
//  Created by Hello on 2019/1/23.
//  Copyright © 2019 LSJ. All rights reserved.
//

#import "AJNetWorkManager.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation AJNetWorkManager
///单例
+ (instancetype)sharedNetManager
{
    static AJNetWorkManager *netWorkManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        netWorkManager = [[AJNetWorkManager alloc] init];
    });
    return netWorkManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self setupNetManager];
        //        [self composeErrors];
    }
    return self;
}

- (void)setupNetManager
{
    
    AJNetManagerShare.afSessionManager = [AFHTTPSessionManager manager];
    AJNetManagerShare.requestSerializer = HttpRequestSerializerJSON;
    AJNetManagerShare.responseSerializer = HttpResponseSerializerJSON;
    
    /// 设置请求超时时间，默认：30秒
    AJNetManagerShare.timeoutInterval = 30;
    /// 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    /// 设置响应数据的基本类型
    AJNetManagerShare.afSessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/css", @"text/xml", @"text/plain", @"application/javascript", @"image/*", nil];
    
    // 配置自建证书的Https请求
    [self ba_setupSecurityPolicy];
}

/// 配置自建证书的Https请求，只需要将CA证书文件放入根目录就行
- (void)ba_setupSecurityPolicy
{
    //    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
    
    if (cerSet.count == 0)
    {
        /// 采用默认的defaultPolicy就可以了. AFN默认的securityPolicy就是它, 不必另写代码. AFSecurityPolicy类中会调用苹果security.framework的机制去自行验证本次请求服务端放回的证书是否是经过正规签名.
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        AJNetManagerShare.afSessionManager.securityPolicy = securityPolicy;
    } else
    {
        /* 自定义的CA证书配置如下:
         自定义security policy, 先前确保你的自定义CA证书已放入工程Bundle
         https://api.github.com 网址的证书实际上是正规CADigiCert签发的, 这里把Charles的CA根证书导入系统并设为信任后, 把Charles设为该网址的SSL Proxy (相当于"中间人"), 这样通过代理访问服务器返回将是由Charles伪CA签发的证书.
         */
        // 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        // 如果需要验证自建证书(无效证书)，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        // 是否需要验证域名，默认为YES
        // securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
        
        AJNetManagerShare.afSessionManager.securityPolicy = securityPolicy;
        
        // 如果服务端使用的是正规CA签发的证书, 那么以下几行就可去掉:
        //  NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        //  AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        //  policy.allowInvalidCertificates = YES;
        //  AJNetManagerShare.afSessionManager.securityPolicy = policy;
    }
}

#pragma mark - setter / getter
/**
 存储着所有的请求task数组
 
 @return 存储着所有的请求task数组
 */
+ (NSMutableArray *)tasks
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NetLog(@"创建task数组");
        tasks = [NSMutableArray array];
    });
    return tasks;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _timeoutInterval = timeoutInterval;
    AJNetManagerShare.afSessionManager.requestSerializer.timeoutInterval = timeoutInterval;
}

- (void)setRequestSerializer:(HttpRequestSerializer)requestSerializer
{
    _requestSerializer = requestSerializer;
    switch (requestSerializer) {
        case HttpRequestSerializerJSON:
        {
            AJNetManagerShare.afSessionManager.requestSerializer = [AFJSONRequestSerializer serializer] ;
        }
            break;
        case HttpRequestSerializerHTTP:
        {
            AJNetManagerShare.afSessionManager.requestSerializer = [AFHTTPRequestSerializer serializer] ;
        }
            break;
        default:
            break;
    }
}

- (void)setResponseSerializer:(HttpResponseSerializer)responseSerializer
{
    _responseSerializer = responseSerializer;
    switch (responseSerializer) {
        case HttpResponseSerializerJSON:
        {
            AJNetManagerShare.afSessionManager.responseSerializer = [AFJSONResponseSerializer serializer] ;
        }
            break;
        case HttpResponseSerializerHTTP:
        {
            AJNetManagerShare.afSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer] ;
        }
            break;
        case HttpResponseSerializerXML:
        {
            AJNetManagerShare.afSessionManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
            
        default:
            break;
    }
}

- (void)setHttpHeaderDictionary:(NSDictionary *)httpHeaderFieldDictionary
{
    _httpHeaderFieldDictionary = httpHeaderFieldDictionary;
    
    if (![httpHeaderFieldDictionary isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"请求头数据有误，请检查！");
        return;
    }
    NSArray *keyArray = httpHeaderFieldDictionary.allKeys;
    
    if (keyArray.count <= 0)
    {
        NSLog(@"请求头数据有误，请检查！");
        return;
    }
    
    for (NSInteger i = 0; i < keyArray.count; i ++)
    {
        NSString *keyString = keyArray[i];
        NSString *valueString = httpHeaderFieldDictionary[keyString];
        
        [AJNetWorkManager setHttpHeaderValue:valueString forKey:keyString];
    }
}

/**
 *  自定义请求头
 */
+ (void)setHttpHeaderValue:(NSString *)value
                    forKey:(NSString *)Key
{
    [AJNetManagerShare.afSessionManager.requestSerializer setValue:value forHTTPHeaderField:Key];
}
/**
 删除所有请求头
 */
+ (void)clearAuthorizationHeader
{
    [AJNetManagerShare.afSessionManager.requestSerializer clearAuthorizationHeader];
}

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
+ (void)cancelAllRequest
{
    // 锁操作
    @synchronized(self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self tasks] removeAllObjects];
    }
}

/*!
 *  取消指定 URL 的 Http 请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL
{
    if (!URL)
    {
        return;
    }
    @synchronized (self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL])
            {
                [task cancel];
                [[self tasks] removeObject:task];
                *stop = YES;
            }
        }];
    }
}
/**
 清空缓存：此方法可能会阻止调用线程，直到文件删除完成。
 */
- (void)clearAllHttpCache
{
    [AJNetWorkCache clearAllHttpCache];
}


@end
