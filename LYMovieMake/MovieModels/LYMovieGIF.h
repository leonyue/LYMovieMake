//
//  LYMovieGIF.h
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/22.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LYMovieOverlay.h"

@interface LYMovieGIF : NSObject<LYMovieOverlay>

@property (nonatomic, strong          ) NSURL   *gifURL;
@property (nonatomic, assign          ) CGPoint gifPosition;
@property (nonatomic, assign          ) CGFloat gifAngle;//旋转
@property (nonatomic, assign          ) float   gifZoomLevel;
@property (nonatomic, assign          ) CMTime  gifBeginTime;

- (CIImage *)applyGIF:(CIImage *)raw AtMovieTime:(CMTime)time;;

@end
