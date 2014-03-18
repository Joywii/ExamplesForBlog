//
//  WTThreadDownloader.m
//  NSURLConnectionExample
//
//  Created by Joywii on 14-3-18.
//  Copyright (c) 2014年 KiloApp. All rights reserved.
//

#import "WTThreadDownloader.h"

@interface WTThreadDownloader()

@property(nonatomic, readwrite, retain) NSURLConnection* connection;
@property(nonatomic, readwrite, retain) NSMutableData* responseData;
@property(nonatomic, readwrite, assign) NSTimeInterval timeoutInterval;
@property(nonatomic, readwrite, copy) completionBlock completionBlock;
@property(nonatomic, readwrite, retain) NSError *error;
@property(nonatomic, readwrite, assign) BOOL finish;


@end

@implementation WTThreadDownloader

+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
              failure:(void (^)(NSError *error))failure
{
    WTThreadDownloader *downloader = [[WTThreadDownloader alloc] init];
    downloader.URL = URL;
    downloader.timeoutInterval = timeoutInterval;
    [downloader setCompletionBlockWithSuccess:success failure:failure];
    [downloader start];
    return downloader;
}
- (void)setCompletionBlockWithSuccess:(void (^)(id responseData))success
                              failure:(void (^)(NSError *error))failure
{
    __weak typeof(self) weakSelf = self;
    self.completionBlock = ^
    {
        if (weakSelf.error)
        {
            if (failure)
            {
                failure(weakSelf.error);
                
            }
        }
        else
        {
            if (success)
            {
                success(weakSelf.responseData);
            }
        }
    };
}
- (void)main
{
    @autoreleasepool
    {
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:self.URL
                                                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                                timeoutInterval:10.0f];
        [request setHTTPMethod: @"GET"];
        
        self.connection =[[NSURLConnection alloc] initWithRequest:request
                                                         delegate:self
                                                 startImmediately:NO];
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.connection start];
        
        while (!self.isCancelled && !self.finish)
        {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        NSLog(@"Thread Finished");
    }
}
#pragma mark - NSURLConnection Delegate.
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"BeginLoading");
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse *)response) statusCode] < 400)
    {
        NSUInteger expectedSize = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.responseData = [[NSMutableData alloc] initWithCapacity:expectedSize];
    }
    else
    {
        [aConnection cancel];
        
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                    code:[((NSHTTPURLResponse *)response) statusCode]
                                                userInfo:nil];
        self.error = error;
        self.connection = nil;
        self.responseData = nil;
        self.completionBlock();
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    NSLog(@"receive data");
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    NSLog(@"FinishLoading");
    self.connection = nil;
    self.finish = YES;
    self.completionBlock();
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"FailedLoading");
    self.connection = nil;
    self.responseData = nil;
    self.finish = YES;
    self.error = error;
    self.completionBlock();
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

@end
