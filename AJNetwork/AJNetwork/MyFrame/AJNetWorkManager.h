//
//  AJNetWorkManager.h
//  AJNetwork
//
//  Created by Hello on 2019/1/23.
//  Copyright © 2019 LSJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"
#import "AJNetWorkCache.h"

// 网络请求类

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 枚举 宏定义

// 获得全局唯一的网络请求实例单例方法
#define AJNetManagerShare [AJNetWorkManager sharedNetManager]
// 弱引用
#define NetWeak(type)  __weak __typeof(self) weak##type = type

// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define NetLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define NetLog(s, ... )
#endif

#define IS_IOS9() ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)


/// 使用枚举NS_ENUM:区别可判断编译器是否支持新式枚举,支持就使用新的,否则使用旧的
typedef NS_ENUM(NSUInteger, NetworkStatus)
{
    /// 未知网络
    NetworkStatusUnknown           = 0,
    /// 没有网络
    NetworkStatusNotReachable,
    /// 手机 3G/4G 网络
    NetworkStatusReachableViaWWAN,
    /// wifi 网络
    NetworkStatusReachableViaWiFi
};

/// 定义请求类型的枚举
typedef NS_ENUM(NSUInteger, HttpRequestType)
{
    /// get请求
    HttpRequestTypeGet = 0,
    /// post请求
    HttpRequestTypePost,
    /// put请求
    HttpRequestTypePut,
    /// delete请求
    HttpRequestTypeDelete
};

/// 请求数据 格式
typedef NS_ENUM(NSUInteger, HttpRequestSerializer)
{
    /// 设置请求数据为JSON格式
    HttpRequestSerializerJSON,
    /// 设置请求数据为HTTP格式
    HttpRequestSerializerHTTP,
};

/// 相应数据格式
typedef NS_ENUM(NSUInteger, HttpResponseSerializer)
{
    /// 设置响应数据为JSON格式
    HttpResponseSerializerJSON,
    /// 设置响应数据为HTTP格式 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
    HttpResponseSerializerHTTP,
    /// XML
    HttpResponseSerializerXML,
};

/// 实时监测网络状态的 block
typedef void(^NetworkStatusBlock)(NetworkStatus status);

/// 定义上传进度 block
typedef void(^UploadProgressBlock)(int64_t bytesProgress,int64_t totalBytesProgress);

/// 定义下载进度 block
typedef void(^DownloadProgressBlock)(int64_t bytesProgress,int64_t totalBytesProgress);

/// 定义请求回调
typedef void(^ComplectionBlock)(id __nullable response, NSError * __nullable error);
/*!
 *  方便管理请求任务。执行取消，暂停，继续等任务.
 *  - (void)cancel，取消任务
 *  - (void)suspend，暂停任务
 *  - (void)resume，继续任务
 */
typedef NSURLSessionTask UrlSessionTask;

/**
 所有 task请求任务(除去视频上传)
 */
static NSMutableArray<AFHTTPSessionManager *> *tasks;

#pragma mark - 类始
@interface AJNetWorkManager : NSObject

@property(nonatomic, strong) AFHTTPSessionManager* afSessionManager;

/// 创建的请求的超时间隔（以秒为单位），此设置为全局统一设置一次即可，默认超时时间间隔为30秒。
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/// 设置网络请求参数的格式，此设置为全局统一设置一次即可，默认：HttpRequestSerializerJSON
@property (nonatomic, assign) HttpRequestSerializer requestSerializer;

/// 设置服务器响应数据格式，此设置为全局统一设置一次即可，默认：HttpResponseSerializerJSON
@property (nonatomic, assign) HttpResponseSerializer responseSerializer;

/// 自定义请求头：httpHeaderField
@property(nonatomic, strong) NSDictionary *httpHeaderFieldDictionary;

/// 所有公共请求错误码对照表
@property(nonatomic, strong) NSDictionary* errorCode;

/// baseUrl
@property(nonatomic, copy) NSString * baseUrl;

// 这些要请求前定义
/// 返回数据 code 对应的key
@property (nonatomic , copy) NSString * codeKey;
/// 返回数据 result 对应的key
@property (nonatomic , copy) NSString * resultKey;
/// 返回数据 meg 对应的key
@property (nonatomic , copy) NSString * megKey;
/// 定义错误 domain 对应的key
@property (nonatomic , copy) NSString * domainKey;


/// 单例
+ (instancetype)sharedNetManager;

#pragma mark - 自定义请求头
/**
 *  自定义请求头
 */
+ (void)setHttpHeaderValue:(NSString *)value
                    forKey:(NSString *)Key;

/**
 删除所有请求头
 */
+ (void)clearAuthorizationHeader;

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
+ (void)cancelAllRequest;

/*!
 *  取消指定 URL 的 Http 请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL;

/**
 清空缓存：此方法可能会阻止调用线程，直到文件删除完成。
 */
- (void)clearAllHttpCache;


/**
 所有 task请求任务(除去视频上传)
 */
+ (NSMutableArray *)tasks;


@end

NS_ASSUME_NONNULL_END
