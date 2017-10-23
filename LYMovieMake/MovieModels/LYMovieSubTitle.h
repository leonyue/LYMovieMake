//
//  LYSubTitle.h
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/15.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LYMovieOverlay.h"

@interface LYMovieSubTitle : NSObject<LYMovieOverlay>

@property (nonatomic, assign          ) CGPoint     textPosition;
@property (nonatomic, copy            ) UIFont      *textFont;//字体,大小
@property (nonatomic, copy            ) UIColor     *textColor;
@property (nonatomic, copy            ) NSString    *text;
@property (nonatomic, assign          ) CGFloat     textAngle;//旋转
@property (nonatomic, assign          ) CMTimeRange textRange;//文字范围

- (CIImage *)applyTitle:(CIImage *)raw AtMovieTime:(CMTime)time;

@end
