//
//  LYMovieWaterPrint.h
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/16.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LYMovieOverlay.h"

typedef NS_OPTIONS(NSUInteger, WaterPrintAlignment) {
    AlignmentTop              = 1 << 0,
    AlignmentBottom           = 1 << 1,
    AlignmentVerticalCenter   = 1 << 2,
    AlignmentLeft             = 1 << 3,
    AlignmentRight             = 1 << 4,
    AlignmentHorizontalCenter = 1 << 5,
};

@interface LYMovieWaterPrint : NSObject<LYMovieOverlay>

@property (nonatomic, strong) CIImage             *waterPrint;
@property (nonatomic, assign) WaterPrintAlignment alignment;
@property (nonatomic, assign) float               zoomLevel;
@property (nonatomic, assign) CMTimeRange         waterPrintRange;

- (CIImage *)applyWaterPrint:(CIImage *)raw AtMovieTime:(CMTime)time;

@end
