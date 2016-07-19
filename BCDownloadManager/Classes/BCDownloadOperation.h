//
//  BCDownloadOperation.h
//  Pods
//
//  Created by caiwb on 16/7/16.
//
//

#import <AFDownloadRequestOperation/AFDownloadRequestOperation.h>

@interface BCDownloadOperation : AFDownloadRequestOperation

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *downloadUrl;

@property (nonatomic, assign) long long downloadedBytes;
@property (nonatomic, assign) long long totalBytes;

@property (nonatomic, assign) BOOL completed;
@property (nonatomic, assign) BOOL isPause;

@property (nonatomic, strong) NSDictionary *HTTPHeaders;
@property (nonatomic, strong) NSDictionary *taskInfo;
@property (nonatomic, copy) NSString *taskInfoString;

- (instancetype)initWithRequest:(NSMutableURLRequest *)urlRequest HTTPHeaders:(NSDictionary *)HTTPHeaders targetPath:(NSString *)targetPath shouldResume:(BOOL)shouldResume;

@end
