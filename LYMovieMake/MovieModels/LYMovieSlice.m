//
//  LYMovieSlice.m
//  LYMovieMake
//
//  Created by dj.yue on 16/6/17.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieSlice.h"
#import "LYMovieTransitionFilterStack.h"
#import "LYMovieConstants.h"
//#import "utility.h"



NSString *const MovieSliceDidChangeRateNotification = @"MovieSliceDidChangeRateNotification";
NSString *const MovieSliceDidChangeClipStartPercentNotification = @"MovieSliceDidChangeClipStartPercentNotification";
NSString *const MovieSliceDidChangeClipEndPercentNotification = @"MovieSliceDidChangeClipEndPercentNotification";
NSString *const MovieSliceDidChangeSliceDurationNotification = @"MovieSliceDidChangeSliceDurationNotification";
NSString *const MovieSliceDidChangeSliceTransitionTimeNotification = @"MovieSliceDidChangeSliceTransitionTimeNotification";

@interface LYMovieSlice ()
@property (nonatomic, strong           ) AVPlayerItem            *playerItem;
@property (nonatomic, strong           ) AVPlayerItemVideoOutput *videoOutput;
@property (nonatomic, strong           ) AVPlayer                *player;

@property (nonatomic, assign           ) CMTime                  rawDuration;

@property (nonatomic, strong           ) id                      timerObserver;

@property (nonatomic, assign, readwrite) double                  totalSeconds;

@property (nonatomic, strong, readwrite) CIImage                 *previewImage;
@property (nonatomic, assign, readwrite) CMTime                  previewTime;
//@property (nonatomic, strong           ) AVAssetImageGenerator   *lastFrameGenerator;
@property (nonatomic, assign          ) double       rate;//播放速度
@property (nonatomic, assign          ) double       clipStartPecent;
@property (nonatomic, assign          ) double       clipEndPecent;

@end

@implementation LYMovieSlice

#pragma mark - initialization

- (instancetype)initWithURL:(NSURL *)url {
    AVAsset *asset = [AVAsset assetWithURL:url];
    return [self initWithAsset:asset];

}

- (instancetype)initWithAsset:(AVAsset *)asset {
    self = [super init];
    if (self) {
        self.rawDuration = asset.duration;
        self.video = asset;
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        self.videoTransform = videoTrack.preferredTransform;
        [self setUp];
    }
    return self;
}

+ (id)SliceWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}

+ (id)SliceWithAsset:(AVAsset *)asset {
    return [[self alloc] initWithAsset:asset];
}

- (void)resetSliceDuration {
    CMTime rawDuration = self.rawDuration;
    CMTime clipedDuration = CMTimeMultiplyByFloat64(rawDuration, self.clipEndPecent - self.clipStartPecent);
    CMTime ratedDuration = CMTimeMultiplyByFloat64(clipedDuration, 1.0f / self.rate);
    self.sliceDuration = ratedDuration;
    [self resetMaxRateAndMinClip];
}
- (void)resetClipRange {
    CMTime begin = kCMTimeZero;
    CMTime end   = self.rawDuration;
    if (self.clipStartPecent > 0.0001) {
        begin = CMTimeMultiplyByFloat64(self.rawDuration, self.clipStartPecent);
    }
    if (self.clipEndPecent < 0.9999) {
        end = CMTimeMultiplyByFloat64(self.rawDuration, self.clipEndPecent);
    }
    self.clipRange = CMTimeRangeMake(begin, CMTimeSubtract(end, begin));
}

- (void)setUp {
    _rate = 1.f;
//    _transitionFilter = [CIFilter filterWithName:@"CISwipeTransition"];
    _transitionFilter = [[LYMovieTransitionFilterStack sharedTransitionFilterStack] defaultFilter];
    _transitionTime = kCMTimeZero;
    _clipStartPecent = 0.f;
    
    double clipEndPecent = 1.f;
    _clipEndPecent = clipEndPecent;
    [self resetSliceDuration];
    [self resetClipRange];
//    [self resetFirstAndLastFrame];
}

- (double)getMovedPercentBySeconds:(double)seconds {
    return seconds / (CMTimeGetSeconds(self.rawDuration) / self.rate);
}


- (BOOL)canStartIncrease {
    return self.clipEndPecent - minDuration * self.rate / CMTimeGetSeconds(self.rawDuration) > self.clipStartPecent;
}
- (BOOL)canStartDecrease {
    return self.clipStartPecent > 0.f;
}

- (BOOL)canEndIncrease {
    return self.clipEndPecent < 1.f;
}

- (BOOL)canEndDecrease {
    return self.clipStartPecent + minDuration * self.rate / CMTimeGetSeconds(self.rawDuration) < self.clipEndPecent;
}

// MARK: private
- (void)resetMaxRateAndMinClip {
    float maxRate = CMTimeGetSeconds(self.sliceDuration) * self.rate / minDuration;
    maxRate = (float)((int)(maxRate * 10)) / 10.f;
    self.maxRate = maxRate;
    float minClip = minDuration / (CMTimeGetSeconds(self.sliceDuration) / (self.clipEndPecent - self.clipStartPecent));
    self.minClipDurationPercent = minClip;
}

#pragma mark - public setter methods
- (void)setClipStartPecent:(double)clipStartPecent withCompletion:(void (^)(double, NSString *))completeBlock {
    NSString *errorInfo = nil;
    if (clipStartPecent < 0.f) {
        clipStartPecent = 0.f;
    }
    
    double maxStartPercent = self.clipEndPecent - (double)minDuration / (CMTimeGetSeconds(self.rawDuration)/self.rate);
    if (maxStartPercent < 0) {
        maxStartPercent = 0;
    }
    if (clipStartPecent > maxStartPercent) {
        clipStartPecent = maxStartPercent;
        errorInfo = @"VideoLimitToast";
    }
    
    CMTime rawDuration = self.rawDuration;
    CMTime clipedDuration = CMTimeMultiplyByFloat64(rawDuration, self.clipEndPecent - self.clipStartPecent);
    CMTime ratedDuration = CMTimeMultiplyByFloat64(clipedDuration, 1.0f / self.rate);
    self.sliceDuration = ratedDuration;
    
    
    if (_clipStartPecent != clipStartPecent) {
        CMTime movedTime = CMTimeMultiplyByFloat64(self.rawDuration, 1.f / self.rate * (clipStartPecent - _clipStartPecent));
        NSDictionary *postDict = @{@"new":@(clipStartPecent),@"old":@(_clipStartPecent),@"movedTime":[NSValue valueWithCMTime:movedTime]};
        _clipStartPecent = clipStartPecent;
        [self resetSliceDuration];
        [self resetClipRange];
//        [self resetFirstAndLastFrame];
        [[NSNotificationCenter defaultCenter] postNotificationName:MovieSliceDidChangeClipStartPercentNotification object:self userInfo:postDict];
    }
    completeBlock(clipStartPecent,errorInfo);
}

- (void)setClipEndPecent:(double)clipEndPecent withCompletion:(void (^)(double, NSString *))completeBlock {
    NSString *errorInfo = nil;
    if (clipEndPecent > 1.f) {
        clipEndPecent = 1.f;
    }
    
    double minEndPercent = self.clipStartPecent + (double)minDuration / (CMTimeGetSeconds(self.rawDuration) / self.rate);
    if (minEndPercent > 1.f) {
        minEndPercent = 1.f;
    }
    if (clipEndPecent < minEndPercent) {
        clipEndPecent = minEndPercent;
        errorInfo = @"VideoLimitToast";
    }
    
    else if (clipEndPecent < self.clipStartPecent) {
        clipEndPecent = self.clipStartPecent;
    }
    if (_clipEndPecent != clipEndPecent) {
        CMTime movedTime = CMTimeMultiplyByFloat64(self.rawDuration, 1.f / self.rate * (clipEndPecent - _clipEndPecent));
        NSDictionary *postDict = @{@"new":@(clipEndPecent),@"old":@(_clipEndPecent),@"movedTime":[NSValue valueWithCMTime:movedTime]};
        _clipEndPecent = clipEndPecent;
        [self resetSliceDuration];
        [self resetClipRange];
//        [self resetFirstAndLastFrame];
        [[NSNotificationCenter defaultCenter] postNotificationName:MovieSliceDidChangeClipEndPercentNotification object:self userInfo:postDict];
    }
    completeBlock(clipEndPecent,errorInfo);
}

- (BOOL)setRate:(double)rate withCompletion:(void (^)(double, NSString *))completeBlock {
    NSString *errorInfo = nil;
    double maxRate = (self.clipEndPecent - self.clipStartPecent) * CMTimeGetSeconds(self.rawDuration) / minDuration;
    maxRate = (double)((int)(maxRate * 10)) / 10.f;
    if (rate > maxRate) {
        rate = maxRate;
        errorInfo = @"VideoLimitToast";
    }
    BOOL success = NO;
    if (_rate != rate) {
        success = YES;
        NSAssert(rate > 0, @"播放速度必须大于0");
        NSDictionary *postDict = @{@"new":@(rate),@"old":@(_rate)};
        _rate = rate;
        self.generator.rate = rate;
        [self resetSliceDuration];
        [[NSNotificationCenter defaultCenter] postNotificationName:MovieSliceDidChangeRateNotification object:self userInfo:postDict];
    }
    
    completeBlock(rate,errorInfo);
    return success;
}

#pragma mark - setter

- (void)setTransitionTime:(CMTime)transitionTime {
    if (CMTimeCompare(_transitionTime, transitionTime) != 0) {
        NSDictionary *postDict = @{@"new":[NSValue valueWithCMTime:transitionTime],@"old":[NSValue valueWithCMTime:_transitionTime]};
        _transitionTime = transitionTime;
        [[NSNotificationCenter defaultCenter] postNotificationName:MovieSliceDidChangeSliceTransitionTimeNotification object:self userInfo:postDict];
    }
}

- (void)setSliceDuration:(CMTime)sliceDuration {
    if (CMTimeCompare(_sliceDuration, sliceDuration) != 0) {
        _sliceDuration = sliceDuration;
        [[NSNotificationCenter defaultCenter] postNotificationName:MovieSliceDidChangeSliceDurationNotification object:self userInfo:@{@"sliceDuration":[NSValue valueWithCMTime:sliceDuration]}];
    }
}

#pragma mark - getter

- (LYVideoFrameGenerator *)generator {
    if (!_generator) {
        _generator = [LYVideoFrameGenerator generatorWithVideo:self.video rate:self.rate];
        _generator.cutLocation = self.cutLocation;
    }
    return _generator;
}

- (NSMutableDictionary<NSNumber *,UIImage *> *)overviewFrames {
    if (_overviewFrames == nil) {
        _overviewFrames = [NSMutableDictionary new];
    }
    return _overviewFrames;
}


@end
