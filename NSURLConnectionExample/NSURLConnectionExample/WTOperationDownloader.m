//
//  WTOperationDownloader.m
//  NSURLConnectionExample
//
//  Created by Joywii on 14-3-18.
//  Copyright (c) 2014年 KiloApp. All rights reserved.
//

#import "WTOperationDownloader.h"

@interface WTOperationDownloader()

@property(nonatomic, readwrite, retain) NSURLConnection* connection;
@property(nonatomic, readwrite, retain) NSMutableData* responseData;
@property(nonatomic, readwrite, assign) NSTimeInterval timeoutInterval;
@property(nonatomic, readwrite, copy) completionBlock completionBlock;
@property(nonatomic, readwrite, retain) NSError *error;
@property(atomic, readwrite, assign) BOOL finished;
@property(atomic, readwrite, assign) BOOL executing;
@property(nonatomic, readwrite, strong) NSRecursiveLock *lock;

@end

@implementation WTOperationDownloader

- (id)init
{
    self = [super init];
    if (self)
    {
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = @"com.kiloapp.lock";
    }
    return self;
}
+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
              failure:(void (^)(NSError *error))failure
{
    NSLog(@"create downloader in main thread?: %d", [NSThread isMainThread]);
    WTOperationDownloader *downloader = [[WTOperationDownloader alloc] init];
    downloader.URL = URL;
    downloader.timeoutInterval = timeoutInterval;
    [downloader setCompletionBlockWithSuccess:success failure:failure];
    //[downloader start];
    return downloader;
}
- (void)setCompletionBlockWithSuccess:(void (^)(id responseData))success
                              failure:(void (^)(NSError *error))failure
{
    [self.lock lock];
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
    [self.lock unlock];
}
- (void)start
{
    [self.lock lock];
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    self.executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self.lock unlock];
    
    [self main];

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
        
        while (!self.isCancelled && !self.finished)
        {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        NSLog(@"Thread Finished");
    }
}
- (void)cancel
{
    [self.lock lock];
    [super cancel];
    if (self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
    [self.lock unlock];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return self.executing;
}

- (BOOL)isFinished
{
    return self.finished;
}
- (void)operationDidFinish
{
    [self.lock lock];
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self.executing = NO;
    self.finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    [self.lock unlock];
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
    //NSLog(@"receive data");
    NSLog(@"receive data in main thread?: %d", [NSThread isMainThread]);

    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    NSLog(@"FinishLoading in main thread?: %d", [NSThread isMainThread]);

    NSLog(@"FinishLoading");
    self.connection = nil;
    self.completionBlock();
    [self operationDidFinish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"FailedLoading in main thread?: %d", [NSThread isMainThread]);
    self.connection = nil;
    self.responseData = nil;
    self.error = error;
    self.completionBlock();
    [self operationDidFinish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

@end
