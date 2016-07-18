//
//  BCViewController.m
//  BCDownloadManager
//
//  Created by caiwenbo on 07/16/2016.
//  Copyright (c) 2016 caiwenbo. All rights reserved.
//

#import "BCViewController.h"
#import "BCDownloadManager.h"
#import "BCDownloadOperation.h"

@interface BCViewController ()

@property (strong, nonatomic) BCDownloadOperation *downloadTask;

@end

@implementation BCViewController

static NSString *targetPath = nil;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    targetPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"/BCDownloadFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (![[BCDownloadManager sharedManager] isDownloading:@"fileName.mp4"])
    {
        _downloadTask = [[BCDownloadOperation alloc] initWithRequest:[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://stream.youdao.com/private/xuetang/pushstation.1477_1_3_screen_2016_02_20_12_07_08.mp4"]]
                                                         HTTPHeaders:@{@"Referer": @"http://live.youdao.com"}
                                                          targetPath:[targetPath stringByAppendingString:@"/fileName.mp4"]
                                                        shouldResume:YES];
        
        [[BCDownloadManager sharedManager] addOperation:_downloadTask];
    }
    [_downloadTask addObserver:self forKeyPath:@"downloadedBytes" options:0 context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    NSLog(@"%lld/%lld",_downloadTask.downloadedBytes, _downloadTask.totalBytes);
}

- (void)dealloc
{
    [_downloadTask removeObserver:self forKeyPath:@"downloadedBytes"];
}

@end
