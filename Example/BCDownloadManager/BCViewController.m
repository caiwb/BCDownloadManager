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

#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width


@interface BCViewController ()

@property (strong, nonatomic) BCDownloadOperation *downloadTask;
@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) BCDownloadButton *downloadButton;
@property (strong, nonatomic) UILabel *progressLabel;

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

    _downloadButton = [BCDownloadButton new];
    [self.view addSubview:_downloadButton];
    _downloadButton.progress = 0;
    _downloadButton.isPause = YES;
    _downloadButton.color = [UIColor cyanColor];
    [_downloadButton addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    _progressLabel = [UILabel new];
    [self.view addSubview:_progressLabel];
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_deleteButton];
    [_deleteButton setTitle:@"delete" forState:UIControlStateNormal];
    [_deleteButton setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
    
    BOOL hasDownloaded = [[BCDownloadManager sharedManager] hasDownloaded:@"fileName.mp4"];
    _deleteButton.enabled = hasDownloaded;
    _downloadButton.enabled = !hasDownloaded;
    
    [_progressLabel setFrame:CGRectMake((SCREEN_WIDTH - 100)/ 2, 250, 100, 50)];
    [_downloadButton setFrame:CGRectMake(100, 350, 40, 40)];
    [_deleteButton setFrame:CGRectMake(SCREEN_WIDTH - 100, 350, 60, 40)];
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
                                                              targetPath:[targetPath stringByAppendingString:@"/fileName.mp4"]
                                                            shouldResume:YES];
            _downloadTask.taskInfo = @{@"name": @"bocai"};
            
            [[BCDownloadManager sharedManager] addOperation:_downloadTask];
        }
        [_downloadTask resume];
        [_downloadTask addObserver:self forKeyPath:@"downloadedBytes" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return _downloadTask;
}

- (void)download
{
    [_downloadTask resume];
}

- (void)delete
{
    [[BCDownloadManager sharedManager] deleteOperation:_downloadTask];
    
    _downloadButton.enabled = YES;
    _deleteButton.enabled = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"downloadedBytes"] && [object isKindOfClass:[BCDownloadOperation class]])
    {
        _progressLabel.text = [NSString stringWithFormat:@"%lld/%lld",_downloadTask.downloadedBytes, _downloadTask.totalBytes];
        [_progressLabel sizeToFit];
    }
}

- (void)dealloc
{
    [_downloadTask removeObserver:self forKeyPath:@"downloadedBytes"];
}

@end
