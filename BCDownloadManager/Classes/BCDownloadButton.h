//
//  BCDownloadButton.h
//  Pods
//
//  Created by caiwb on 16/7/19.
//
//

#import <UIKit/UIKit.h>
#import "BCDownloadOperation.h"

@interface BCDownloadButton : UIButton

@property (nonatomic, assign) BOOL isPause;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *disableColor;

@property (nonatomic, strong) BCDownloadOperation *task;

@end
