//
//  LYVideoFrameGenerator.h
//  LYMovieMake
//
//  Created by dj.yue on 16/5/31.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LYVideoFrameGenerator : NSObject
/**
 精确预览图数量
 */
@property (nonatomic, readonly) NSUInteger sampleCount;
@property (nonatomic, assign  ) double rate;
@property (nonatomic, assign  ) CGSize maximumSize;
@property (nonatomic, assign  )  float cutLocation;
+ (id)generatorWithVideo:(AVAsset *)video;
+ (id)generatorWithVideo:(AVAsset *)video rate:(double)rate;
- (id)initWithVideo:(AVAsset *)video rate:(double)rate;

/**
 4图预览
 
 @param completeBlock completeBlock description
 */
- (void)generateOverviewCompleted:(void (^)(UIImage *, NSError *, NSUInteger))completeBlock;


/**
 精确预览
 
 @param completeBlock completeBlock description
 */
- (void)generateAccurateOverviewCompleted:(void (^)(UIImage *image, NSUInteger accurateIndex, NSError *error))completeBlock;


/**
 取消图片生成
 */
- (void)cancelAllGeneration;

// MARK: abondon

/**
 abandon

 @param index index description
 @param completeBlock completeBlock description
 */
- (void)generateVideoFrameWithIndex:(NSUInteger)index
                              completed:(void (^)(UIImage *image, CMTime getTime, CMTime actualTime, NSError *error))completeBlock;

/**
 abandon

 @param completeBlock completeBlock description
 */
- (void)generatePreviewCompleted:(void (^)(UIImage *image, NSError *error))completeBlock;

/**
 abandon

 @param completeBlock completeBlock description
 */
- (void)generateVideoFrameCompleted:(void (^)(UIImage *image, NSError *error))completeBlock;



//- (CGSize)sizeOfFrameAtIndex:(NSUInteger)index;
//- (CGSize)sizeOfAllFramesAppended;

//- (double)offsetXFromSeconds:(double)seconds;
//- (double)secondsFromOffsetX:(double)offsetX;
//- (CGSize)sizeOfFrame;

@end
