//
//  BCDownloadButton.h
//  Pods
//
//  Created by caiwb on 16/7/19.
//
//

#import <UIKit/UIKit.h>

@interface BCDownloadButton : UIButton

@property (nonatomic, assign) BOOL isPause;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor *color;

@end
