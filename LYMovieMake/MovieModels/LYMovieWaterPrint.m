//
//  LYMovieWaterPrint.m
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/16.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import "LYMovieWaterPrint.h"

@interface LYMovieWaterPrint ()

@property (nonatomic, strong) CIFilter *filter;

@end

@implementation LYMovieWaterPrint

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefault];
    }
    return self;
}

- (void)setDefault {
    _alignment = (AlignmentVerticalCenter | AlignmentHorizontalCenter);
    _zoomLevel = 1.0f;
    _waterPrintRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
}

- (CIImage *)applyOverlay:(CIImage *)raw AtMovieTime:(CMTime)time {
    return [self applyWaterPrint:raw AtMovieTime:time];
}

- (CIImage *)applyWaterPrint:(CIImage *)raw AtMovieTime:(CMTime)time{
    if (!self.waterPrint || !CMTimeRangeContainsTime(self.waterPrintRange, time)) {
        return raw;
    }
    if (self.filter == nil) {
        self.filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    }
    CIImage *water = [self.waterPrint imageByApplyingTransform:CGAffineTransformMakeScale(self.zoomLevel, self.zoomLevel)];
    CGSize back = raw.extent.size;
    CGSize wp = water.extent.size;
    CGPoint wpPosition = CGPointZero;
    if (self.alignment & AlignmentLeft) {
        wpPosition.x = 0;
    }
    if (self.alignment & AlignmentRight) {
        wpPosition.x = back.width - wp.width;
    }
    if (self.alignment & AlignmentHorizontalCenter) {
        wpPosition.x = (back.width - wp.width) /2;
    }
    
    if (self.alignment & AlignmentBottom) {
        wpPosition.y = 0;
    }
    if (self.alignment & AlignmentTop) {
        wpPosition.y = back.height - wp.height;
    }
    if (self.alignment & AlignmentVerticalCenter) {
        wpPosition.y = (back.height - wp.height) /2;
    }
    ;
    [self.filter setValue:[[water imageByApplyingTransform:CGAffineTransformMakeTranslation(wpPosition.x, wpPosition.y)] imageByCroppingToRect:raw.extent] forKey:kCIInputImageKey];
    [self.filter setValue:raw forKey:kCIInputBackgroundImageKey];
    return self.filter.outputImage;
}

- (void)setAlignment:(WaterPrintAlignment)alignment {
    int verticalAlignCount = 0;
    WaterPrintAlignment verticalAlign = AlignmentVerticalCenter;
    
    if (alignment & AlignmentTop) {
        verticalAlign = AlignmentTop;
        verticalAlignCount++;
    }
    if (alignment & AlignmentBottom) {
        verticalAlign = AlignmentBottom;
        verticalAlignCount++;
    }
    if (alignment & AlignmentVerticalCenter) {
        verticalAlign = AlignmentVerticalCenter;
        verticalAlignCount++;
    }
    if (verticalAlignCount != 1) {
        verticalAlign = AlignmentVerticalCenter;
    }
    
    int horizontalAlignCount = 0;
    WaterPrintAlignment horizontalAlign = AlignmentHorizontalCenter;
    
    if (alignment & AlignmentLeft) {
        horizontalAlign = AlignmentLeft;
        horizontalAlignCount++;
    }
    if (alignment & AlignmentRight) {
        horizontalAlign = AlignmentRight;
        horizontalAlignCount++;
    }
    if (alignment & AlignmentHorizontalCenter) {
        horizontalAlign = AlignmentHorizontalCenter;
        horizontalAlignCount++;
    }
    if (horizontalAlignCount != 1) {
        horizontalAlign = AlignmentHorizontalCenter;
    }
    
    _alignment = (verticalAlign | horizontalAlign);
    
}

@end
