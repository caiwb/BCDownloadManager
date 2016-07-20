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
#import "BCDownloadButton.h"

@interface BCViewController ()

@property (strong, nonatomic) NSString *targetPath;
@property (strong, nonatomic) BCDownloadOperation *downloadTask;
@property (strong, nonatomic) BCDownloadButton *downloadButton;
@property (strong, nonatomic) UIButton *deleteButton;

@end

@implementation BCViewController

- (NSString *)targetPath
{
    if (! _targetPath)
    {
        _targetPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"/BCDownloadFile"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_targetPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:_targetPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _targetPath;
}

- (BCDownloadOperation *)downloadTask
{
    if (! _downloadTask)
    {
        if ([[BCDownloadManager sharedManager] hasDownloaded:@"fileName.mp4"])
        {
            _downloadTask = [[BCDownloadManager sharedManager].hasDownloadedTasks firstObject];
        }
        else if ([[BCDownloadManager sharedManager] isDownloading:@"fileName.mp4"])
        {
            _downloadTask = [[BCDownloadManager sharedManager].downloadingTasks firstObject];
        }
        else
        {
            _downloadTask = [[BCDownloadOperation alloc] initWithRequest:[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://stream.youdao.com/private/xuetang/pushstation.1477_1_3_screen_2016_02_20_12_07_08.mp4"]]
                                                             HTTPHeaders:@{@"Referer": @"http://live.youdao.com"}
                                                              targetPath:[self.targetPath stringByAppendingString:@"/fileName.mp4"]
                                                            shouldResume:YES];
            _downloadTask.taskInfo = @{@"name": @"bocai"};
        }
    }
    
    return _downloadTask;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self generateButtons];
}

- (void)generateButtons
{
    _downloadButton = [BCDownloadButton new];
    [self.view addSubview:_downloadButton];
    _downloadButton.task = self.downloadTask;
    _downloadButton.color = [UIColor magentaColor];
    [_downloadButton addTarget:self action:@selector(downloadControl:) forControlEvents:UIControlEventTouchUpInside];
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_deleteButton];
    [_deleteButton setTitle:@"delete" forState:UIControlStateNormal];
    [_deleteButton setTitleColor:[UIColor magentaColor] forState:UIControlStateNormal];
    [_deleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _deleteButton.enabled = _downloadButton.task.isReady ? NO : YES;
    [_deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    
    _downloadButton.frame = CGRectMake(100, 350, 70, 70);
    _deleteButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 150, 340, 60, 50);
}

- (void)downloadControl:(BCDownloadButton *)button
{
    if ([self.downloadTask isReady])
    {
        button.task = self.downloadTask;
        [[BCDownloadManager sharedManager] addOperation:self.downloadTask];
        _deleteButton.enabled = YES;
    }
    else if ([self.downloadTask isExecuting])
    {
        [self.downloadTask pause];
    }
    else if ([self.downloadTask isPaused])
    {
        [self.downloadTask resume];
    }
}

- (void)delete:(id)sender
{
    [[BCDownloadManager sharedManager] deleteOperation:self.downloadTask];
    self.downloadTask = nil;
    _downloadButton.task = nil;
    _deleteButton.enabled = NO;
}

@end
