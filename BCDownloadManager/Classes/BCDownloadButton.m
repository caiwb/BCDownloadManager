//
//  BCDownloadButton.m
//  Pods
//
//  Created by caiwb on 16/7/19.
//
//

#import "BCDownloadButton.h"

@implementation BCDownloadButton

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setIsPause:(BOOL)isPause
{
    _isPause = isPause;
    [self setNeedsDisplay];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    [self setNeedsDisplay];
}

- (void)setTask:(BCDownloadOperation *)task
{
    [_task removeObserver:self forKeyPath:@"downloadedBytes"];
    [_task removeObserver:self forKeyPath:@"isPaused"];
    
    _task = task;
    
    self.progress = (CGFloat)task.downloadedBytes/task.totalBytes;
    self.isPause = task ? (task.isReady ? NO : task.isPaused) : NO;
    
    [task addObserver:self forKeyPath:@"downloadedBytes" options:NSKeyValueObservingOptionNew context:nil];
    [task addObserver:self forKeyPath:@"isPaused" options:NSKeyValueObservingOptionNew context:nil];
}

- (UIColor *)disableColor
{
    return _disableColor ?: [UIColor lightGrayColor];
}

- (void)drawRect:(CGRect)rect
{
    UIColor *curColor = self.enabled ? self.color : self.disableColor;
    
    [super drawRect:rect];
    
    UIBezierPath *roundPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 12) radius:11 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    [curColor set];
    [roundPath stroke];
    
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 12) radius:9.75 startAngle:1.5 * M_PI endAngle:(1.5 + _progress * 2) * M_PI clockwise:YES];
    progressPath.lineWidth = 2.5;
    [curColor set];
    [progressPath stroke];
    
    if (_isPause)
    {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(9.5, 8)];
        [p addLineToPoint:CGPointMake(9.5, 16)];
        [p addLineToPoint:CGPointMake(16.5, 12)];
        [p closePath];
        [curColor setFill];
        [p fill];
    }
    else
    {
        UIBezierPath *p = [UIBezierPath bezierPathWithRect:CGRectMake(8, 8, 8, 8)];
        [curColor setFill];
        [p fill];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"downloadedBytes"])
    {
        self.progress = (CGFloat)self.task.downloadedBytes/self.task.totalBytes;
    }
    else if ([keyPath isEqualToString:@"isPaused"])
    {
        self.isPause = self.task.isPaused;
    }
}

- (void)dealloc
{
    [_task removeObserver:self forKeyPath:@"downloadedBytes"];
    [_task removeObserver:self forKeyPath:@"isPaused"];
}

@end
