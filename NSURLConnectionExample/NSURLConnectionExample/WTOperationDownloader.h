//
//  WTOperationDownloader.h
//  NSURLConnectionExample
//
//  Created by Joywii on 14-3-18.
//  Copyright (c) 2014年 KiloApp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^completionBlock)();

@interface WTOperationDownloader : NSOperation

@property (nonatomic, readwrite, retain) NSURL *URL;

+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
              failure:(void (^)(NSError *error))failure;

@end
