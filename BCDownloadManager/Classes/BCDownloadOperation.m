//
//  BCDownloadOperation.m
//  Pods
//
//  Created by caiwb on 16/7/16.
//
//

#import "BCDownloadOperation.h"

@implementation BCDownloadOperation

- (instancetype)initWithRequest:(NSMutableURLRequest *)urlRequest HTTPHeaders:(NSDictionary *)HTTPHeaders targetPath:(NSString *)targetPath shouldResume:(BOOL)shouldResume
{
    if (HTTPHeaders)
    {
        for (NSString *key in HTTPHeaders.allKeys)
        {
            [urlRequest setValue:HTTPHeaders[key] forHTTPHeaderField:key];
        }
    }
    return [super initWithRequest:urlRequest targetPath:targetPath shouldResume:shouldResume];
}

- (NSString *)tempPath
{
    NSMutableArray *arr = [[self.targetPath componentsSeparatedByString:@"/"] mutableCopy];
    [arr insertObject:@"temps" atIndex:arr.count - 2];
    return [arr componentsJoinedByString:@"/"];
}

- (NSMutableDictionary *)taskInfo
{
    if (!_taskInfo && self.taskInfoString && ![self.taskInfoString isEqualToString:@""])
    {
        NSData *data = [self.taskInfoString dataUsingEncoding:NSUTF8StringEncoding];
        if (data)
        {
            _taskInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
    }
    return _taskInfo;
}

- (NSString *)taskInfoString
{
    if (!_taskInfoString && self.taskInfo)
    {
        _taskInfoString = @"";
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.taskInfo options:0 error:nil];
        if (data)
        {
            _taskInfoString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return _taskInfoString;
}

@end
