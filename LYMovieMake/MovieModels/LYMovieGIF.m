//
//  LYMovieGIF.m
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/22.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import "LYMovieGIF.h"
#import <ImageIO/ImageIO.h>

@interface LYMovieGIF ()

@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic, strong) NSMutableArray *gifFrames;
@property (nonatomic, strong) NSMutableArray *framesDelayTime;
//@property (nonatomic, assign) CMTime totalDelay;

@end

@implementation LYMovieGIF

- (instancetype)init {
    self = [super init];
    if (self) {
        self.gifFrames = [[NSMutableArray alloc] init];
        self.framesDelayTime = [[NSMutableArray alloc] init];
        [self setDefault];
    }
    return self;
}

- (void)setDefault {
    _gifPosition = CGPointMake(100, 100);
    _gifAngle = M_PI_2;
    _gifZoomLevel = 0.5;
    _gifBeginTime = kCMTimeZero;
}

- (CIImage *)applyOverlay:(CIImage *)raw AtMovieTime:(CMTime)time {
    return [self applyGIF:raw AtMovieTime:time];
}

- (CIImage *)applyGIF:(CIImage *)raw AtMovieTime:(CMTime)time {
    if (self.gifFrames.count == 0) {
        [self readGifFrames];
    }
    if (self.filter == nil) {
        self.filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    }
    for (NSUInteger i = 0; i < self.framesDelayTime.count; i++) {
        CMTimeRange range = CMTimeRangeMake(self.gifBeginTime, [self.framesDelayTime[i] CMTimeValue]);
        if (CMTimeRangeContainsTime(range, time)) {
            CIImage *imageForThisFrame = self.gifFrames[i];
            [self.filter setValue:imageForThisFrame forKey:kCIInputImageKey];
            [self.filter setValue:raw forKey:kCIInputBackgroundImageKey];
            return self.filter.outputImage;
        }
    }
    return raw;
}

- (void)readGifFrames {
    [self.gifFrames removeAllObjects];
    [self.framesDelayTime removeAllObjects];
    CMTime totalDelay = kCMTimeZero;
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)self.gifURL.absoluteString, kCFURLPOSIXPathStyle, 0);
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL(url, NULL);
    CFRelease(url);
    size_t frameCount = CGImageSourceGetCount(gifSource);
    for (size_t i = 0; i < frameCount; ++i) {
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [self.gifFrames addObject:[CIImage imageWithCGImage:frame]];
        CGImageRelease(frame);
        
        // get gif info with each frame
        NSDictionary *dict = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL));
        NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
        id  delay = [gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime];
        CMTime cmTimeDelay = CMTimeMakeWithSeconds([delay floatValue], 60);
        totalDelay = CMTimeAdd(totalDelay, cmTimeDelay);
        [self.framesDelayTime addObject:[NSValue valueWithCMTime:totalDelay]];
    }
//    self.totalDelay = totalDelay;
    CFRelease(gifSource);
}

@end
