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

- (void)drawRect:(CGRect)rect
{
    UIColor *curColor = self.enabled ? self.color : [UIColor grayColor];
    
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

@end
