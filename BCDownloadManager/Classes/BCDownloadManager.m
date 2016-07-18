//
//  BCDownloadManager.m
//  Pods
//
//  Created by caiwb on 16/7/16.
//
//

#import "BCDownloadManager.h"
#import "BCDownloadOperation.h"
#import <FMDB/FMDB.h>

@interface BCDownloadManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, strong) NSString *dbPath;

@end

@implementation BCDownloadManager
{
    BOOL dbSuc;
}

+ (BCDownloadManager *)sharedManager
{
    static BCDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BCDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.hasDownloadedTasks = [NSMutableArray new];
        self.downloadingTasks  = [NSMutableArray new];
        self.maxDownloadingOperation = self.maxDownloadingOperation ?: INT32_MAX;
        self.operationQueue.maxConcurrentOperationCount = self.operationQueue.maxConcurrentOperationCount ?: 5;
        
        __weak BCDownloadManager *weakSelf = self;
        
        FMResultSet *rs = [self.db executeQuery:@"select * from DownloadOperationList"];
        while ([rs next])
        {
            NSString *fileName          = [rs stringForColumn:@"fileName"];
            NSString *downloadUrl       = [rs stringForColumn:@"downloadUrl"];
            long long downloadedBytes   = [rs longLongIntForColumn:@"downloadedBytes"];
            long long totalBytes        = [rs longLongIntForColumn:@"totalBytes"];
            BOOL completed              = [rs boolForColumn:@"completed"];
            NSString *taskInfoString    = [rs stringForColumn:@"taskInfo"];
            
            BCDownloadOperation *downloadTask = [[BCDownloadOperation alloc] initWithRequest:[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadUrl]] HTTPHeaders:weakSelf.HTTPHeaders targetPath:[weakSelf.targetFolder stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]] shouldResume:YES];
            downloadTask.shouldOverwrite = YES;
            downloadTask.fileName        = fileName;
            downloadTask.downloadUrl     = downloadUrl;
            downloadTask.downloadedBytes = downloadedBytes;
            downloadTask.totalBytes      = totalBytes;
            downloadTask.completed       = completed;
            downloadTask.isPause         = NO;
            downloadTask.taskInfoString  = taskInfoString;
            
            if (completed)
            {
                [weakSelf.hasDownloadedTasks addObject:downloadTask];
            }
            else
            {
                [weakSelf updateDownloadDataWithTask:downloadTask];
                [weakSelf.downloadingTasks addObject:downloadTask];
                [weakSelf.operationQueue addOperation:downloadTask];
            }
        }
    }
    return self;
}

- (void)addOperation:(BCDownloadOperation *)task
{
    NSParameterAssert(task);
    
    [self updateDownloadDataWithTask:task];
    self.HTTPHeaders = self.HTTPHeaders ?: task.HTTPHeaders;
    
    NSMutableArray *pathArr = [[task.targetPath componentsSeparatedByString:@"/"] mutableCopy];
    [pathArr removeLastObject];
    self.targetFolder = self.targetFolder ?: [pathArr componentsJoinedByString:@"/"];
    self.tempFolder = self.tempFolder ?: [self.targetFolder stringByAppendingString:@"/temps"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.tempFolder])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.tempFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (self.HTTPHeaders && !task.HTTPHeaders)
    {
        task = [[BCDownloadOperation alloc] initWithRequest:task.request HTTPHeaders:self.HTTPHeaders targetPath:task.targetPath shouldResume:task.shouldResume];
    }

    [self.operationQueue addOperation:task];
    [self.downloadingTasks addObject:task];
}

- (void)deleteOperation:(BCDownloadOperation *)task
{
    [task cancel];
    BOOL suc;
    if (!task.completed)
    {
        [self.downloadingTasks removeObject:task];
        suc = [[NSFileManager defaultManager] removeItemAtPath:task.tempPath error:nil];
    }
    else
    {
        [self.hasDownloadedTasks removeObject:task];
        suc = [[NSFileManager defaultManager] removeItemAtPath:task.targetPath error:nil];
    }
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        dbSuc = [db executeUpdate:@"delete from DownloadOperationList where fileName = ?", task.fileName];
    }];
}



- (void)updateDownloadDataWithTask:(BCDownloadOperation *)downloadTask
{
    __weak BCDownloadOperation *weakTask = downloadTask;
    __weak BCDownloadManager *weakManager = self;
    
    downloadTask.shouldOverwrite = YES;
    
    __block CGFloat updateValue = 0.00;
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSString *downloadUrl = [db stringForQuery:@"select downloadUrl from DownloadOperationList where fileName = ?", weakTask.fileName];
        if (!downloadUrl)
        {
            dbSuc = [db executeUpdate:@"insert into DownloadOperationList (fileName, downloadUrl, downloadedBytes, totalBytes, completed, taskInfo) values (?, ?, 0, 0, 0, ?)", downloadTask.fileName, downloadTask.downloadUrl, downloadTask.taskInfoString];
        }
        
        [downloadTask setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
            
            CGFloat progress = (CGFloat)totalBytesReadForFile / totalBytesExpectedToReadForFile;
            NSLog(@"%f", progress);
            
            if (!updateValue)
            {
                dbSuc = [db executeUpdate:@"update DownloadOperationList set totalBytes = ? where fileName = ?", @(totalBytesExpectedToReadForFile), downloadTask.fileName];
                weakTask.totalBytes = totalBytesExpectedToReadForFile;
            }
            
            weakTask.downloadedBytes = totalBytesReadForFile;
            if (progress > updateValue)
            {
                updateValue = progress + 0.05;
                dbSuc = [db executeUpdate:@"update DownloadOperationList set downloadedBytes = ? where fileName = ?", @(totalBytesReadForFile), downloadTask.fileName];
            }
        }];
        
        [downloadTask setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            dbSuc = [db executeUpdate:@"update DownloadOperationList set completed = 1"];
            weakTask.completed = YES;
            
            [weakManager.downloadingTasks removeObject:weakTask];
            [weakManager.hasDownloadedTasks addObject:weakTask];
            
            [[NSFileManager defaultManager] removeItemAtPath:weakTask.tempPath error:nil];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }];
}

- (NSString *)dbPath
{
    if (!_dbPath)
    {
        NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _dbPath = [documentDirectory stringByAppendingString:@"/BCDownloadDataBase.sqlite"];
    }
    return _dbPath;
}

- (FMDatabaseQueue *)dbQueue
{
    if (!_dbQueue)
    {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:self.dbPath];
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [self createTablesIfNeeded:db];
        }];
    }
    return _dbQueue;
}

- (FMDatabase *)db
{
    if (!_db)
    {
        _db = [FMDatabase databaseWithPath:self.dbPath];
        
        if ([_db open])
        {
            [self createTablesIfNeeded:_db];
        }
    }
    return _db;
}


- (void)createTablesIfNeeded:(FMDatabase *)db
{
    if (![db tableExists:@"DownloadOperationList"])
    {
        [db executeStatements:@"create table DownloadOperationList (fileName text, downloadUrl text, downloadedBytes bigint, totalBytes bigint, completed integer, taskInfo text)"];
    }
}

- (NSString *)targetFolder
{
    if (!_targetFolder)
    {
        _targetFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"/BCDownloadFile"];
    }
    return _targetFolder;
}

- (BOOL)hasDownloaded:(NSString *)fileName
{
    for (BCDownloadOperation* task in self.hasDownloadedTasks)
    {
        if ([task.fileName isEqualToString:fileName]) return YES;
    }
    return NO;
}

- (BOOL)isDownloading:(NSString *)fileName
{
    for (BCDownloadOperation* task in self.downloadingTasks)
    {
        if ([task.fileName isEqualToString:fileName]) return YES;
    }
    return NO;
}

- (BCDownloadOperation *)resumeOperation:(BCDownloadOperation *)task
{
    [task cancel];
    
    NSString *fileName = task.fileName;
    
    __block BCDownloadOperation *downloadTask;
    
    __weak BCDownloadManager *weakSelf = self;
        
    FMResultSet *rs = [self.db executeQuery:@"select * from DownloadOperationList where name = ?", fileName];
    while([rs next])
    {
        NSString *fileName          = [rs stringForColumn:@"fileName"];
        NSString *downloadUrl       = [rs stringForColumn:@"downloadUrl"];
        long long downloadedBytes   = [rs longLongIntForColumn:@"downloadedBytes"];
        long long totalBytes        = [rs longLongIntForColumn:@"totalBytes"];
        BOOL completed              = [rs boolForColumn:@"completed"];
        NSString *taskInfoString    = [rs stringForColumn:@"taskInfo"];
        
        downloadTask = [[BCDownloadOperation alloc] initWithRequest:[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadUrl]] HTTPHeaders:weakSelf.HTTPHeaders targetPath:[weakSelf.targetFolder stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]] shouldResume:YES];
        downloadTask.shouldOverwrite    = YES;
        downloadTask.fileName           = fileName;
        downloadTask.downloadUrl        = downloadUrl;
        downloadTask.downloadedBytes    = downloadedBytes;
        downloadTask.totalBytes         = totalBytes;
        downloadTask.completed          = completed;
        downloadTask.taskInfoString     = taskInfoString;
        downloadTask.isPause            = NO;
        
        [weakSelf updateDownloadDataWithTask:downloadTask];
        [weakSelf.downloadingTasks addObject:downloadTask];
        [weakSelf.hasDownloadedTasks removeObject:task];
        [weakSelf.operationQueue addOperation:downloadTask];
    }
    return downloadTask;
}

- (BCDownloadOperation *)redownloadOperation:(BCDownloadOperation *)downloadTask
{
    [downloadTask cancel];
    
    BCDownloadOperation *newDownloadTask = [[BCDownloadOperation alloc] initWithRequest:[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadTask.downloadUrl]] targetPath:downloadTask.targetPath shouldResume:YES];
    
    newDownloadTask.name              = downloadTask.name;
    newDownloadTask.downloadUrl       = downloadTask.downloadUrl;
    newDownloadTask.downloadedBytes   = 0;
    newDownloadTask.totalBytes        = downloadTask.totalBytes;
    newDownloadTask.completed         = NO;
    newDownloadTask.taskInfoString    = downloadTask.taskInfoString;
    newDownloadTask.isPause           = downloadTask.isPause;
    
    [self updateDownloadDataWithTask:newDownloadTask];
    [self.downloadingTasks addObject:newDownloadTask];
    [self.downloadingTasks removeObject:downloadTask];
    [self.operationQueue addOperation:newDownloadTask];
    
    return newDownloadTask;
}

@end
