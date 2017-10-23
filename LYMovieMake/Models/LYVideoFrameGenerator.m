//
//  LYVideoFrameGenerator.m
//  LYMovieMake
//
//  Created by dj.yue on 16/5/31.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYVideoFrameGenerator.h"
//#import "UIImage+Resize.h"
#import <objc/runtime.h>
#import "LYMovieConstants.h"
#import "AVAsset+VideoSize.h"

@interface LYVideoFrameGenerator ()

@property (nonatomic, strong            ) dispatch_queue_t      generatorQueue;
@property (nonatomic, readwrite         ) NSUInteger            sampleCount;
@property (nonatomic, strong            ) AVAsset               * videoAsset;
@property (nonatomic, strong            ) AVAssetImageGenerator *generator;

@end

@implementation LYVideoFrameGenerator

@synthesize maximumSize = _maximumSize;

+ (id)generatorWithVideo:(AVAsset *)video {
    return [[self alloc] initWithVideo:video rate:1.0f];
}
+ (id)generatorWithVideo:(AVAsset *)video rate:(double)rate{
    return [[self alloc] initWithVideo:video rate:rate];
}

- (instancetype)initWithVideo:(AVAsset *)video rate:(double)rate{
    self = [super init];
    if (self) {
        self.videoAsset = video;
        self.rate = rate;
        self.generatorQueue = dispatch_queue_create("com.dj.yue.videoframegenerator", DISPATCH_QUEUE_SERIAL);
        self.generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:video];
        self.generator.appliesPreferredTrackTransform = YES;
        self.generator.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(0.2, 60);
        self.generator.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(0.2, 60);
        CGSize size = [video size];
        self.generator.maximumSize = CGSizeMake(sampleWidth, sampleWidth * size.height / size.width);
    }
    return self;
}

#pragma mark - public

- (double)offsetXFromSeconds:(double)seconds {
    return seconds / samplePerSeconds * sampleWidth;
}

- (double)secondsFromOffsetX:(double)offsetX {
    return offsetX / sampleWidth * samplePerSeconds;
}

- (NSUInteger)sampleCount {
    double seconds = CMTimeGetSeconds(self.videoAsset.duration);
    double sampleCountRaw = seconds / samplePerSeconds;
    NSUInteger sampleCountInt = (NSUInteger)sampleCountRaw;
    NSUInteger sampleCount = sampleCountRaw > (double)sampleCountInt ? sampleCountInt + 1 : sampleCountInt;
    if (sampleCount < 6) {
        sampleCount = 6;
    }
    return sampleCount;
}

- (CMTime)timeOfSample:(NSUInteger)index {
    NSUInteger sampleCount = self.sampleCount;
    return CMTimeMultiplyByRatio(self.videoAsset.duration, (int32_t)index, (int32_t)sampleCount);
}

- (CGSize)sizeOfFrameAtIndex:(NSUInteger)index {
    if (index != self.sampleCount - 1) {   //普通尺寸
        return CGSizeMake(sampleWidth, sampleHeight);
    }
    //最后一个
    CMTime timeOfSample = [self timeOfSample:index];
    CMTime total = self.videoAsset.duration;
    CMTime lastSampleDuration = CMTimeSubtract(total, timeOfSample);
    return CGSizeMake(sampleWidth * CMTimeGetSeconds(lastSampleDuration) / samplePerSeconds / self.rate, sampleHeight);
}

- (CGSize)sizeOfAllFramesAppended {
    CMTime total = self.videoAsset.duration;
    return CGSizeMake(sampleWidth * CMTimeGetSeconds(total) / samplePerSeconds / self.rate, sampleHeight);
}

- (CGSize)sizeOfFrame {
    CGSize totalSize = CGSizeMake(sampleWidth, sampleHeight);
    for (NSUInteger i = 0; i < self.sampleCount; i++) {
        totalSize.width += [self sizeOfFrameAtIndex:i].width;
    }
    return totalSize;
}

- (void)generateVideoFrameWithIndex:(NSUInteger)index
                          completed:(void (^)(UIImage *, CMTime, CMTime, NSError *))completeBlock {
//    dispatch_async(self.generatorQueue, ^{
        CMTime time = [self timeOfSample:index];
        [self.generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:time]]
                                             completionHandler:^(CMTime requestedTime,
                                                                 CGImageRef  _Nullable image,
                                                                 CMTime actualTime,
                                                                 AVAssetImageGeneratorResult result,
                                                                 NSError * _Nullable error) {
            
            UIImage *imageSample = nil;
            if (error == nil) {
                CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image, [self rectFromCutLocation]);
                imageSample = [[UIImage alloc] initWithCGImage:croppedImageRef];
                CGImageRelease(croppedImageRef);
                completeBlock(imageSample,time,actualTime,nil);
            }else {
                completeBlock(nil,time,actualTime,error);
            }
        }];
}

- (void)generatePreviewCompleted:(void (^)(UIImage *, NSError *))completeBlock {
    dispatch_async(self.generatorQueue, ^{
        CMTime time = kCMTimeZero;
        CMTime actualTime;
        NSError *error;
        CGImageRef cgImage = [self.generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        if (error == nil) {
            UIImage *imageSample = [[UIImage alloc] initWithCGImage:cgImage];
            CGImageRelease(cgImage);
            completeBlock(imageSample,nil);
        }
        else {
            completeBlock(nil,error);
        }
        
    });
}
- (void)generateVideoFrameCompleted:(void (^)(UIImage *, NSError *))completeBlock {
    dispatch_group_t group = dispatch_group_create();
    UIGraphicsBeginImageContext([self sizeOfFrame]);
    __block CGFloat addedWidth = 0.0;
    __block NSError *addedError = nil;
    for (NSUInteger i = 0; i < self.sampleCount; i++) {
        dispatch_group_enter(group);
        [self generateVideoFrameWithIndex:i
                                completed:^(UIImage *image,
                                            CMTime getTime,
                                            CMTime actualTime,
                                            NSError *error) {
            if (error == nil) {
                CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
                rect.origin.x += addedWidth;
                addedWidth += image.size.width;
                [image drawInRect:rect];
            }
            else {
                addedError = error;
            }
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (addedError == nil) {
        completeBlock(newImage,nil);
    }
    else {
        completeBlock(nil,addedError);
    }
    
}

- (void)generateOverviewCompleted:(void (^)(UIImage *, NSError *, NSUInteger))completeBlock {
    [self cancelAllGeneration];
    NSArray *times = [self timesOfOverview];
    [self.generator generateCGImagesAsynchronouslyForTimes:times
                                         completionHandler:^(CMTime requestedTime,
                                                             CGImageRef  _Nullable image,
                                                             CMTime actualTime,
                                                             AVAssetImageGeneratorResult result,
                                                             NSError * _Nullable error) {
        UIImage *imageSample = nil;
        if (error == nil) {
            CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image, [self rectFromCutLocation]);
            imageSample = [[UIImage alloc] initWithCGImage:croppedImageRef];
            CGImageRelease(croppedImageRef);
        }
        [times enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CMTime time = [obj CMTimeValue];
            if (CMTimeCompare(time, requestedTime) == 0) {
                completeBlock(imageSample,error,idx);
                *stop = YES;
            }
        }];
    }];
}

- (void)generateAccurateOverviewCompleted:(void (^)(UIImage *, NSUInteger, NSError *))completeBlock {
    //    dispatch_async(self.generatorQueue, ^{
    NSMutableArray *times = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < self.sampleCount; i++) {
        CMTime time = [self timeOfSample:i];
        [times addObject:[NSValue valueWithCMTime:time]];
    }
    
    [self.generator generateCGImagesAsynchronouslyForTimes:times
                                         completionHandler:^(CMTime requestedTime,
                                                             CGImageRef  _Nullable image,
                                                             CMTime actualTime,
                                                             AVAssetImageGeneratorResult result,
                                                             NSError * _Nullable error) {
        
        UIImage *imageSample = nil;
        
        __block NSUInteger accureIndex = -1;
        [times enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CMTime objTime = [obj CMTimeValue];
            if (CMTimeCompare(objTime, requestedTime) == 0) {
                accureIndex = idx;
                *stop = YES;
            }
        }];
        if (accureIndex == -1) {
            return;
        }
        
        if (error == nil) {
            CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image, [self rectFromCutLocation]);
            imageSample = [[UIImage alloc] initWithCGImage:croppedImageRef];
            CGImageRelease(croppedImageRef);
            completeBlock(imageSample,accureIndex,nil);
        }else {
            completeBlock(imageSample,accureIndex,error);
        }
    }];
}

// MARK: private

- (CGRect)rectFromCutLocation {
    CGRect rect = CGRectMake(0, 0, sampleWidth, sampleHeight);
    CGFloat height = self.maximumSize.height;
    rect.origin.y = height * (1 - self.cutLocation) - sampleHeight;
    if (rect.origin.y < 0) {
        rect.origin.y = 0;
    }
    return rect;
}

/**
 4个sample的时间点

 @return <#return value description#>
 */
- (NSArray *)timesOfOverview{
    CMTime total = self.videoAsset.duration;
    NSMutableArray *times = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        [times addObject:[NSValue valueWithCMTime:CMTimeMultiplyByRatio(total, i, 4)]];
    }
    return times;
}

- (void)cancelAllGeneration {
    [self.generator cancelAllCGImageGeneration];
}

- (CGSize)maximumSize {
    return self.generator.maximumSize;
}
- (void)setMaximumSize:(CGSize)maximumSize {
    if (!CGSizeEqualToSize(_maximumSize, maximumSize)) {
        _maximumSize = maximumSize;
        self.generator.maximumSize = maximumSize;
    }
    
}

@end
