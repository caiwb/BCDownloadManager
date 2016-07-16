//
//  BCDownloadManager.h
//  Pods
//
//  Created by caiwb on 16/7/16.
//
//

#import <AFNetworking/AFNetworking.h>

@class BCDownloadOperation;

@interface BCDownloadManager : AFHTTPRequestOperationManager

@property (nonatomic, assign) NSUInteger maxDownloadingOperation;
@property (nonatomic, strong) NSMutableArray<BCDownloadOperation *> *hasDownloadedTasks;
@property (nonatomic, strong) NSMutableArray<BCDownloadOperation *> *downloadingTasks;
@property (nonatomic, copy) NSString *targetPath;
@property (nonatomic, copy) NSMutableDictionary *HTTPHeaders;

+ (BCDownloadManager *)sharedManager;

- (void)addOperation:(BCDownloadOperation *)task;
- (void)deleteOperation:(BCDownloadOperation *)task;

- (BOOL)hasDownloaded:(NSString *)fileName;
- (BOOL)isDownloading:(NSString *)fileName;

- (BCDownloadOperation *)resumeOperation:(BCDownloadOperation *)task;
- (BCDownloadOperation *)redownloadOperation:(BCDownloadOperation *)task;

@end
