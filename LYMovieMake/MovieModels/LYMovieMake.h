//
//  LYMovieMake.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/17.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LYMovieSlice.h"
#import "LYMovieOverlay.h"
#import "LYMovieSound.h"
#import "LYMovieFilter.h"
#import <MediaPlayer/MPMediaItem.h>

@class LYMovieMake;

@protocol LYMovieMakeDelegate <NSObject>


- (void)MovieMake:(LYMovieMake *)make didAddMovieSlice:(LYMovieSlice *)slice atIndex:(NSInteger)index;
- (void)MovieMake:(LYMovieMake *)make didRemoveMovieSliceFromIndex:(NSInteger)index;

- (void)MovieMake:(LYMovieMake *)make didPlayToTime:(CMTime)time;
- (void)MovieMake:(LYMovieMake *)make didPlayToItemIndex:(NSUInteger)index ItemTime:(CMTime)time;
- (void)MovieMake:(LYMovieMake *)make didChangeClipRangeOfSlice:(LYMovieSlice *)slice;
- (void)MovieMake:(LYMovieMake *)make didChangeRateOfSlice:(LYMovieSlice *)slice;

@end

extern NSString *const VEPlayerChangePlayStatusNotification;

@interface LYMovieMake : NSObject

//@property (nonatomic, strong) MPMediaItem *music;
@property (nonatomic, strong) AVPlayerItem *music;
@property (nonatomic, weak) id<LYMovieMakeDelegate> delegate;
@property (nonatomic, strong) LYMovieFilter *filter; //滤镜
@property (nonatomic, assign) float movieSoundVolume;
@property (nonatomic, assign) float musicSoundVolume;
@property (nonatomic, strong) NSArray<id<LYMovieOverlay>>  *overlays; //覆盖物
@property (nonatomic, strong, readonly) NSArray<LYMovieSlice *> *sliceArray; //视频片段 顺序拼接
@property (nonatomic, strong) NSArray<LYMovieSound *> *sounds; //MovieSound应该有时间范围
@property (nonatomic, assign, readonly) CMTime makeDuration;

@property (nonatomic, assign, readonly) NSArray<NSNumber*>* jointArray;///<总视频分隔点0～1的数组

//播放
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign, readonly) CMTime current;

- (void)addSlice:(LYMovieSlice *)slice;

- (void)removeSlice:(LYMovieSlice *)slice;

- (void)play;

- (void)seekToTime:(CMTime)time;
/**
 *  <#Description#>
 *
 *  @param index <#index description#>
 *  @param time  加上clipStartPercent 和rate的虚拟时间
 */
- (void)seekToItemIndex:(NSUInteger)index ItemTime:(CMTime)time;
/**
 *  <#Description#>
 *
 *  @param block time虚拟时间
 */
- (void)getCurrentItemIndexAndTime:(void(^)(NSUInteger index, CMTime time))block;
- (void)pause;
- (void)exportMovieToPath:(NSString *)path
             WithProgress:(void (^)(float))percentBlock
                     completion:(void (^)(BOOL, NSError *))complete;

/**
 *  立即更新playerItem （在改变顺序、剪辑范围、顺序  结束动作时调用）
 */
- (void)updatePlayerItem;

@end
