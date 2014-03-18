//
//  PTViewController.m
//  NSURLConnectionExample
//
//  Created by Haoran Chen on 6/25/13.
//  Copyright (c) 2013 KiloApp. All rights reserved.
//

#import "PTViewController.h"
#import "PTNormalDownloaler.h"
#import "PTThreadDownloader.h"
#import "PTOperationDownloader.h"
#import "WTThreadDownloader.h"

@interface PTViewController ()

@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
    button.frame = CGRectMake(100, 30, 100, 30);
    [button addTarget:self action:@selector(toggleButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 60, 320, 400)];
    imageView.tag = 123456;
    [self.view addSubview:imageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)toggleButton
{
    NSString *URLString = @"http://farm7.staticflickr.com/6191/6075294191_4c8ca20409.jpg";
       
    //Use PTNormalDownloaler 
//    PTNormalDownloaler *downloader = [PTNormalDownloaler
//                                      downloadWithURL:[NSURL URLWithString:URLString]
//                                      timeoutInterval:15
//                                              success:^(id responseData){
//                                                  NSLog(@"get data size: %d", [(NSData *)responseData length]);
//                                                  NSLog(@"success block in main thread?: %d", [NSThread isMainThread]);
//                                              }
//                                              failure:^(NSError *error){
//                                                  NSLog(@"failure block in main thread?: %d", [NSThread isMainThread]);
//                                              }];

    //Use PTThreadDownloaler
//    PTThreadDownloader *downloader = [PTThreadDownloader
//                                      downloadWithURL:[NSURL URLWithString:URLString]
//                                      timeoutInterval:15
//                                      success:^(id responseData){
//                                          NSLog(@"get data size: %d", [(NSData *)responseData length]);
//                                          NSLog(@"success block in main thread?: %d", [NSThread isMainThread]);
//                                      }
//                                      failure:^(NSError *error){
//                                          NSLog(@"failure block in main thread?: %d", [NSThread isMainThread]);
//                                      }];
    
    
    //Use PTOperationDownloader
//    PTOperationDownloader *downloader = [PTOperationDownloader
//                                        downloadWithURL:[NSURL URLWithString:URLString]
//                                        timeoutInterval:15
//                                        success:^(id responseData){
//                                            NSLog(@"get data size: %d", [(NSData *)responseData length]);
//                                            NSLog(@"success block in main thread?: %d", [NSThread isMainThread]);
//                                        }
//                                        failure:^(NSError *error){
//                                            NSLog(@"failure block in main thread?: %d", [NSThread isMainThread]);
//                                        }];
//    
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [queue addOperation:downloader];NSBlockOperation
    
    //Use WTThreadDownloader
    WTThreadDownloader *downloader = [WTThreadDownloader downloadWithURL:[NSURL URLWithString:URLString] timeoutInterval:15 success:^(id responseData)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            UIImageView *imageView = (UIImageView *)[self.view viewWithTag:123456];
            UIImage *image = [UIImage imageWithData:(NSData *)responseData];
            imageView.image = image;
        });
    }
    failure:^(NSError *error)
    {
        NSLog(@"Failed WTThreadDownloader: %@",error);
    }];
    
    NSLog(@"started downloader: %@", downloader.URL.absoluteString);
}

@end
