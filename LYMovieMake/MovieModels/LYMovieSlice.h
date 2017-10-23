//
//  LYMovieSlice.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/17.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "LYVideoFrameGenerator.h"
#import "LYMovieTransitionFilter.h"

typedef NS_ENUM(NSUInteger, JoinTransition) {
    JoinTransitionNone,
    JoinTransitionBlack,
};

extern NSString *const MovieSliceDidChangeRateNotification;
extern NSString *const MovieSliceDidChangeClipStartPercentNotification;
extern NSString *const MovieSliceDidChangeClipEndPercentNotification;

extern NSString *const MovieSliceDidChangeSliceDurationNotification;

extern NSString *const MovieSliceDidChangeSliceTransitionTimeNotification;

@interface LYMovieSlice : NSObject

@property (nonatomic, assign, readonly) double                    rate;//播放速度
@property (nonatomic, assign, readonly) double                    clipStartPecent;
@property (nonatomic, assign, readonly) double                    clipEndPecent;
@property (nonatomic, strong          ) LYMovieTransitionFilter     *transitionFilter;
@property (nonatomic, assign          ) CMTime                    transitionTime;

@property (nonatomic, strong          ) AVAsset                   *video;
@property (nonatomic, strong          ) LYVideoFrameGenerator       *generator;
@property (nonatomic, assign          ) CMTimeRange               clipRange; //未适配播放速度
@property (nonatomic, assign          ) CMTime                    sliceDuration; ///<适配了剪辑 + 播放速度后的时间


@property (nonatomic, assign) float maxRate;
@property (nonatomic, assign) float minClipDurationPercent;

//@property (nonatomic, strong          ) CIImage      *lastFrame;
//@property (nonatomic, strong          ) CIImage      *firstFrame;

// MARK: 旋转
@property (nonatomic, assign) CGAffineTransform videoTransform;

// MARK: 裁剪
@property (nonatomic, assign) BOOL needCut;///是否要裁剪
@property (nonatomic, assign) float cutLocation; ///<16:9从哪里剪,图像坐标系在左下角，从下往上裁剪


//4 preview frame
@property (nonatomic, strong) NSMutableDictionary<NSNumber *,UIImage *> *overviewFrames;

+ (id)SliceWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url;
+ (id)SliceWithAsset:(AVAsset *)asset;

- (void)setClipStartPecent:(double)clipStartPecent
            withCompletion:(void(^)(double actuallyStartPercent, NSString *errorInfo))completeBlock;
- (void)setClipEndPecent:(double)clipEndPecent
          withCompletion:(void(^)(double actuallyEndPercent, NSString *errorInfo))completeBlock;
- (BOOL)setRate:(double)rate
 withCompletion:(void(^)(double actuallyRate, NSString *errorInfo))completeBlock;

- (double)getMovedPercentBySeconds:(double)seconds;

- (BOOL)canStartIncrease;
- (BOOL)canStartDecrease;
- (BOOL)canEndIncrease;
- (BOOL)canEndDecrease;

@end
