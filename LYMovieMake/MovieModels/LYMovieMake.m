//
//  LYMovieMake.m
//  LYMovieMake
//
//  Created by dj.yue on 16/6/17.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieMake.h"
#import <objc/runtime.h>

#import "LYVideoEditCompositionInstruction.h"
#import "LYVideoEditVideoCompositor.h"


//#import "utility.h"
//typedef enum : NSUInteger {
//    RangeRelationBefore, //剪辑前部分
//    RangeRelationBegin, //剪辑开始
//    RangeRelationMiddle, //剪辑中
//    RangeRelationEnd, //剪辑末尾
//    RangeRelationAfter, //剪辑后部分
//    RangeRelationError
//} RangeRelation;

NSString *const VEPlayerChangePlayStatusNotification = @"VEPlayerChangePlayStatusNotification";

@interface LYMovieMake (){
    AVMutableCompositionTrack *_compositionAudioTracks[3];
}


@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;
@property (nonatomic, strong) AVPlayerItem     *playerItem;
@property (nonatomic, strong) id               timerObserver;
@property (nonatomic, strong) AVPlayer         *player;


//@property (nonatomic, strong) NSMutableArray      *previewRanges;
//@property (nonatomic, strong) NSMutableArray      *totalRanges;
@property (nonatomic, strong) dispatch_queue_t operationQueue;

@property (nonatomic, strong) NSMutableArray   *sliceTimeRanges;
@property (nonatomic, strong) NSMutableArray   *transitionTimeRanges;
@property (nonatomic, strong) NSMutableArray   *passThroughTimeRanges;
@property (nonatomic, strong) NSLock           *timeRangesLock;
@property (atomic, assign   ) BOOL             needUpdatePlayerItem;

@property (nonatomic, strong, readwrite) NSMutableArray<LYMovieSlice *> *sliceArray; //视频片段 顺序拼接

//@property (nonatomic, assign) CMTime           targetTime; //更新playerItem时的时间线
//@property (nonatomic, assign) NSInteger        targetIndex; //更新playerItem时的slice索引
@end

@implementation LYMovieMake

- (void)dealloc {
    NSLog(@"make dealloc");
    [self removePlayerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerLayer removeFromSuperlayer];
}

#pragma mark - public

- (void)addSlice:(LYMovieSlice *)slice {
    [[self mutableArrayValueForKey:@"sliceArray"] addObject:slice];
}

- (void)removeSlice:(LYMovieSlice *)slice {
    [[self mutableArrayValueForKey:@"sliceArray"] removeObject:slice];
}

- (void)play {
    [self addPlayerObserver];
    if (self.player.rate == 0.f) {
        [self updatePlayerItem];
        [self.player play];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VEPlayerChangePlayStatusNotification object:self userInfo:@{@"playing":@(YES)}];
}

- (void)pause {
    [self.player pause];
    [self removePlayerObserver];
    [[NSNotificationCenter defaultCenter] postNotificationName:VEPlayerChangePlayStatusNotification object:self userInfo:@{@"playing":@(NO)}];
}

- (void)updatePlayerItem {
    if (self.needUpdatePlayerItem) {
        self.playerItem = nil;
//        DNSLog(@"update player item");
//        BOOL isPlaying = self.player.rate != 0;
        [self.player pause];
        [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player play];
//        [self seekToItemIndex:self.targetIndex ItemTime:self.targetTime];
        self.needUpdatePlayerItem = NO;
    }
}


- (void)getCurrentItemIndexAndTime:(void (^)(NSUInteger, CMTime))block {
    CMTime current = [self getCurrentPlayerTime];
    [self getSliceIndexOfTime:current result:^(NSInteger sliceIndex, CMTime sliceTime, BOOL isConnectionPoint) {
        block(sliceIndex,sliceTime);
    }];
}

- (void)seekToTime:(CMTime)time {
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)seekToItemIndex:(NSUInteger)index ItemTime:(CMTime)time {
//    DNSLog(@"debug seek to index:%ld",index);
//    CMTimeShow(time);
    if (index == -1 || index == NSNotFound) {
        [self seekToItemIndex:0 ItemTime:kCMTimeZero];
        return;
    }
    NSArray *sliceRanges = self.sliceTimeRanges;
    if (sliceRanges.count == 0) {
        return;
    }
    CMTimeRange sliceRange = [sliceRanges[index] CMTimeRangeValue];
    CMTime targetTime = kCMTimeZero;
    int32_t compareResult = CMTimeCompare(time, kCMTimeZero);
    ///seek的范围调整到slice的范围
    if ( compareResult <= 0) {
        if (index == 0) {
            time = kCMTimeZero;
        }
        else {
            time = CMTimeAdd(kCMTimeZero, CMTimeMakeWithSeconds(0.01, 600));
        }
    }
    else if (CMTimeCompare(time, sliceRange.duration) >= 0) {
        time = CMTimeSubtract(sliceRange.duration, CMTimeMakeWithSeconds(0.01, 600));
    }
    
    targetTime = CMTimeAdd(sliceRange.start, time);
//    DNSLog(@"seek to true time");
//    CMTimeShow(targetTime);
    [self.player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];



    
}

- (BOOL)isPlaying {
    return self.player.rate != 0.f;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.needUpdatePlayerItem = NO;
        self.timeRangesLock = [[NSLock alloc] init];
//        self.targetTime = kCMTimeZero;
//        self.targetIndex = 0;
        _movieSoundVolume = 1.f;
        _musicSoundVolume = 1.f;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipStartChange:) name:MovieSliceDidChangeClipStartPercentNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipEndChange:) name:MovieSliceDidChangeClipEndPercentNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rateChange:) name:MovieSliceDidChangeRateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transitionTimeChange:) name:MovieSliceDidChangeSliceTransitionTimeNotification object:nil];
    }
    return self;
}


#pragma mark - MovieSlice notifications

- (void)transitionTimeChange:(NSNotification *)notif {
    LYMovieSlice *slice = notif.object;
    if (![self.sliceArray containsObject:slice]) {
        return;
    }
    self.needUpdatePlayerItem = YES;
    [self resetSliceRange];
    [self updatePlayerItem];
}

- (void)rateChange:(NSNotification *)notif {
    LYMovieSlice *slice = notif.object;
    if (![self.sliceArray containsObject:slice]) {
        return;
    }
//    NSInteger setSliceIndex = [self.sliceArray indexOfObject:slice];
//
//    __block NSInteger targetIndex;
//    __block CMTime    targetTime;
//    if (self.needUpdatePlayerItem) { //not first time
//        targetIndex = self.targetIndex;
//        targetTime = self.targetTime;
//    }
//    else {
//        CMTime currentTime = [self getCurrentPlayerTime];
//        [self getSliceIndexOfTime:currentTime result:^(NSInteger sliceIndex, CMTime sliceTime, BOOL isConnectionPoint) {
//            if (isConnectionPoint && sliceIndex == setSliceIndex -1) {
//                targetIndex = sliceIndex;
//                targetTime  = kCMTimeZero;
//            }
//            else {
//                targetTime = sliceTime;
//                targetIndex = sliceIndex;
//            
//            }
//        }];
//    }
    self.needUpdatePlayerItem = YES;
    [self resetSliceRange];
    [self updatePlayerItem];
//    if (targetIndex == setSliceIndex) {  //修改的播放位置的slice
//        NSDictionary *userInfo = notif.userInfo;
//        double preRate = [userInfo[@"old"] doubleValue];
//        double currentRate = [userInfo[@"new"] doubleValue];
//        targetTime = CMTimeMultiplyByFloat64(targetTime, preRate / currentRate);
//        
//    }
//    else {
////        DNSLog(@"not here");
//    }
//    
//    self.targetTime = targetTime;
//    self.targetIndex = targetIndex;
////    DNSLog(@"target time after rating and index:%ld",targetIndex);
////    CMTimeShow(targetTime);
//    [self.delegate MovieMake:self didChangeRateOfSlice:slice];
//    [self.delegate MovieMake:self didPlayToItemIndex:targetIndex ItemTime:targetTime];
    
}

- (void)clipStartChange:(NSNotification *)notif {
    LYMovieSlice *slice = notif.object;
    if (![self.sliceArray containsObject:slice]) {
        return;
    }
    
//    NSInteger setSliceIndex = [self.sliceArray indexOfObject:slice];
//    __block NSInteger targetIndex;
//    __block CMTime    targetTime;
//    if (self.needUpdatePlayerItem) { //not first time
//        targetIndex = self.targetIndex;
//        targetTime = self.targetTime;
//    }
//    else {
//        CMTime currentTime = [self getCurrentPlayerTime];
//        [self getSliceIndexOfTime:currentTime result:^(NSInteger sliceIndex, CMTime sliceTime, BOOL isConnectionPoint) {
//            if (isConnectionPoint && sliceIndex == setSliceIndex -1) {
//                targetIndex = sliceIndex;
//                targetTime  = kCMTimeZero;
//            }
//            else {
//                targetTime = sliceTime;
//                targetIndex = sliceIndex;
//                
//            }
//
//        }];
//    }
    self.needUpdatePlayerItem = YES;
    [self resetSliceRange];
    [self updatePlayerItem];
//    if (targetIndex == setSliceIndex) {  //修改的播放位置的slice
//        CMTime movedTime = [notif.userInfo[@"movedTime"] CMTimeValue];
//        targetTime = CMTimeSubtract(targetTime, movedTime);
//    }
//
//    
//    if (CMTimeCompare(targetTime, kCMTimeZero) < 0) {
//        targetTime = kCMTimeZero;
//        //                [self seekToItemIndex:sliceIndex ItemTime:kCMTimeZero];
//    }
//    self.targetTime = targetTime;
//    self.targetIndex = targetIndex;
//    DNSLog(@"Save pre time and index:%ld",targetIndex);
    
    [self.delegate MovieMake:self didChangeClipRangeOfSlice:slice];
//    [self.delegate MovieMake:self didPlayToItemIndex:targetIndex ItemTime:targetTime];
    
}

- (void)clipEndChange:(NSNotification *)notif {
    LYMovieSlice *slice = notif.object;
    if (![self.sliceArray containsObject:slice]) {
        return;
    }
//    NSInteger setSliceIndex = [self.sliceArray indexOfObject:slice];
//    __block NSInteger targetIndex;
//    __block CMTime    targetTime;
//    if (self.needUpdatePlayerItem) { //not first time
//        targetIndex = self.targetIndex;
//        targetTime = self.targetTime;
//    }
//    else {
//        CMTime currentTime = [self getCurrentPlayerTime];
//        [self getSliceIndexOfTime:currentTime result:^(NSInteger sliceIndex, CMTime sliceTime, BOOL isConnectionPoint) {
//            if (isConnectionPoint && sliceIndex == setSliceIndex -1) {
//                targetIndex = sliceIndex;
//                targetTime  = kCMTimeZero;
//            }
//            else {
//                targetTime = sliceTime;
//                targetIndex = sliceIndex;
//                
//            }
//            
//        }];
//    }
    self.needUpdatePlayerItem = YES;
    [self resetSliceRange];
    [self updatePlayerItem];
//    if (targetIndex == setSliceIndex) {  //修改的播放位置的slice
//        CMTimeRange range = [self.sliceTimeRanges[targetIndex] CMTimeRangeValue];
//        //            CMTime movedTime = [notif.userInfo[@"movedTime"] CMTimeValue];
//        if (CMTimeCompare(targetTime, range.duration) >= 0) {
//            targetTime = CMTimeSubtract(range.duration, CMTimeMakeWithSeconds(0.01, 600));
//        }
////        CMTime movedTime = [notif.userInfo[@"movedTime"] CMTimeValue];
////        targetTime = CMTimeSubtract(targetTime, movedTime);
//    }
    
//    self.targetTime = targetTime;
//    self.targetIndex = targetIndex;
//    DNSLog(@"Save pre time and index:%ld",targetIndex);
    
    [self.delegate MovieMake:self didChangeClipRangeOfSlice:slice];
//    [self.delegate MovieMake:self didPlayToItemIndex:targetIndex ItemTime:targetTime];
    
}

- (void)getSliceIndexOfTime:(CMTime)time result:(void(^)(NSInteger sliceIndex,CMTime sliceTime,BOOL isConnectionPoint))resultBlock {
//    DNSLog(@"getsliceIndex");
    NSArray *sliceRanges = self.sliceTimeRanges;
    for (NSInteger i = 0; i < sliceRanges.count ; i++) {
        CMTimeRange range = [sliceRanges[i] CMTimeRangeValue];
        if (CMTimeRangeContainsTime(range, time)) {
            if (CMTimeCompare(time, CMTimeAdd(range.start, range.duration)) == 0) {
                resultBlock(i, CMTimeSubtract(time, range.start), YES);
//                DNSLog(@"连接点");
            }
            else {
                resultBlock(i, CMTimeSubtract(time, range.start), NO);
            }
            
            return;
        }
    }
    resultBlock(-1 , kCMTimeInvalid, NO);
}

#pragma mark - private methods

- (CMTime)getCurrentPlayerTime {
//    [self.playerLock lock];
//    while (YES) {
//        if (self.isSeeking) {
//            continue;
//        }
//        break;
//    }
    CMTime time = self.player.currentTime;
//    [self.playerLock unlock];
    return time;
}

- (void)addPlayerObserver {
    __weak typeof(self) weakSelf = self;
    if (!self.timerObserver) {
        self.timerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.005, 6000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf.delegate MovieMake:weakSelf didPlayToTime:time];
            [weakSelf playToTime:time];
        }];
    }
    
}

- (void)removePlayerObserver {
    if (self.timerObserver) {
        [self.player removeTimeObserver:self.timerObserver];
        self.timerObserver = nil;
    }
}

- (void)playToTime:(CMTime)time {
    [self getSliceIndexOfTime:time result:^(NSInteger sliceIndex, CMTime sliceTime, BOOL isConnectionPoint) {
        if (self.delegate) {
            [self.delegate MovieMake:self didPlayToItemIndex:sliceIndex ItemTime:sliceTime];
        }
    }];
}

// MARK: lazy

- (NSMutableArray *)sliceTimeRanges {
    if (_sliceTimeRanges == nil) {
        _sliceTimeRanges = [NSMutableArray new];
    }
    return _sliceTimeRanges;
}

- (NSMutableArray *)transitionTimeRanges {
    if (_transitionTimeRanges == nil) {
        _transitionTimeRanges = [NSMutableArray new];
    }
    return _transitionTimeRanges;
}

- (NSMutableArray *)passThroughTimeRanges {
    if (_passThroughTimeRanges == nil) {
        _passThroughTimeRanges = [NSMutableArray new];
    }
    return _passThroughTimeRanges;
}

- (void)resetSliceRange {
    [self.timeRangesLock lock];
    
    [self.sliceTimeRanges removeAllObjects];
    [self.transitionTimeRanges removeAllObjects];
    [self.passThroughTimeRanges removeAllObjects];
    CMTime insertTime = kCMTimeZero; // 视频插入的开始时间
    
    for (NSUInteger i = 0; i < self.sliceArray.count; i++) {
        LYMovieSlice *slice = self.sliceArray[i];
        LYMovieSlice *nextSlice = nil;
        if (i + 1 < self.sliceArray.count) {
            nextSlice = self.sliceArray[i + 1];
        }
        CMTimeRange insertRange = CMTimeRangeMake(insertTime, slice.sliceDuration);
        [self.sliceTimeRanges addObject:[NSValue valueWithCMTimeRange:insertRange]];
        CMTimeRange passThrough = insertRange;
        
        CMTime transitionHead = kCMTimeZero;
        if (i != 0) { //不是第一个
            transitionHead = slice.transitionTime;
        }
        CMTime transitionTail = kCMTimeZero;
        if (nextSlice != nil) {//不是最后一个
            transitionTail = nextSlice.transitionTime;
        }
        
        passThrough = CMTimeRangeMake(CMTimeAdd(passThrough.start, transitionHead), CMTimeSubtract(passThrough.duration, transitionHead));
        passThrough = CMTimeRangeMake(passThrough.start, CMTimeSubtract(passThrough.duration, transitionTail));
        
        
        [self.passThroughTimeRanges addObject:[NSValue valueWithCMTimeRange:passThrough]];
        if (nextSlice != nil) {
            [self.transitionTimeRanges addObject:[NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeAdd(passThrough.start, passThrough.duration), transitionTail)]];
        }
        
        insertTime = CMTimeAdd(insertTime, insertRange.duration);
        insertTime = CMTimeSubtract(insertTime, transitionTail);
    }
    [self.timeRangesLock unlock];
}


- (NSArray<NSNumber *> *)jointArray {
    NSMutableArray *joint = [[NSMutableArray alloc] init];
    if (self.sliceArray.count < 2) {
        return joint;
    }
    CMTime total = self.makeDuration;
    Float64 totalSeconds = CMTimeGetSeconds(total);
    
    for (NSUInteger i = 0; i < self.transitionTimeRanges.count; i ++) {
        CMTimeRange transitionTimeRange = [self.transitionTimeRanges[i] CMTimeRangeValue];
        CMTime middle = CMTimeAdd(transitionTimeRange.start, CMTimeMultiplyByRatio(transitionTimeRange.duration, 1, 2));
        [joint addObject:@(CMTimeGetSeconds(middle) / totalSeconds)];
    }
    
    return joint;
}

#pragma mark - player notification
- (void)moviePlayEnd:(NSNotification *)notification {
    [self seekToItemIndex:0 ItemTime:kCMTimeZero];
    [self play];
}


#pragma mark - setter & getter

- (NSMutableArray<LYMovieSlice *> *)sliceArray {
    if (_sliceArray == nil) {
        _sliceArray = [[NSMutableArray alloc] init];
    }
    return _sliceArray;
}

- (void)removeObjectFromSliceArrayAtIndex:(NSUInteger)index {
    self.needUpdatePlayerItem = YES;
    [_sliceArray removeObjectAtIndex:index];
    [self resetSliceRange];
    if (self.delegate) {
        [self.delegate MovieMake:self didRemoveMovieSliceFromIndex:index];
    }
}


- (void)insertObject:(LYMovieSlice *)object inSliceArrayAtIndex:(NSUInteger)index{
    self.needUpdatePlayerItem = YES;
    [_sliceArray insertObject:object atIndex:index];
    [self resetSliceRange];
    if (self.delegate) {
        [self.delegate MovieMake:self didAddMovieSlice:object atIndex:index];
    }
}


- (void)setSlices:(NSMutableArray<LYMovieSlice *> *)slices {
    NSAssert(NO, @"Donot use this to set MovieMake slices");
}

//- (void)setSlices:(NSArray<MovieSlice *> *)slices {
//    if (_slices) {
//        self.needUpdatePlayerItem = YES;
//    }
//    _slices = slices;
//    
//    [self resetSliceRange];
//}

- (void)setSounds:(NSArray<LYMovieSound *> *)sounds {
    self.needUpdatePlayerItem = YES;
    _sounds =sounds;
}

- (void)setMusic:(AVPlayerItem *)music {
    if (_music != music) {
        _music = music;
        self.needUpdatePlayerItem = YES;
        [self updatePlayerItem];
    }
}

- (void)setMovieSoundVolume:(float)movieSoundVolume {
    if (_movieSoundVolume != movieSoundVolume) {
        _movieSoundVolume = movieSoundVolume;
        [self buildAudioMix];
        self.playerItem.audioMix = self.audioMix;
    }
}

- (void)setMusicSoundVolume:(float)musicSoundVolume {
    if (_musicSoundVolume != musicSoundVolume) {
        _musicSoundVolume = musicSoundVolume;
        [self buildAudioMix];
        self.playerItem.audioMix = self.audioMix;
    }
}

- (AVPlayerItem *)playerItem {
    if (!_playerItem) {
        if (self.sliceArray.count == 0) {
            return nil;
        }
        [self buildComposition];
        _playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        _playerItem.videoComposition = self.videoComposition;
        _playerItem.audioMix = self.audioMix;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    }
    return _playerItem;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self seekToItemIndex:0 ItemTime:kCMTimeZero];
    }
    return _player;
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    }
    return _playerLayer;
}



- (CMTime)makeDuration {
    CMTimeRange lastSliceTimeRange = [[self.sliceTimeRanges lastObject] CMTimeRangeValue];
    return CMTimeAdd(lastSliceTimeRange.start, lastSliceTimeRange.duration);
}

- (dispatch_queue_t)operationQueue {
    if (!_operationQueue) {
        _operationQueue = dispatch_queue_create("com.dj.yueusa.videoParsingOperation", DISPATCH_QUEUE_CONCURRENT);
    }
    return _operationQueue;
}

- (CMTime)current {
    return [self.player currentTime];
}

#pragma mark - preview & export


- (void)buildComposition{

    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    //    CMTime insertTime = kCMTimeZero; // 视频插入的开始时间
    
    CGSize targetSize = CGSizeMake(800.f, 450.f);
    
    // Add two video tracks.
    AVMutableCompositionTrack *compositionVideoTracks[2];
    compositionVideoTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    compositionVideoTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // Add two audio tracks
    AVMutableCompositionTrack *compositionAudioTracks[2];
    compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *musicCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    _compositionAudioTracks[0] = compositionAudioTracks[0];
    _compositionAudioTracks[1] = compositionAudioTracks[1];
    _compositionAudioTracks[2] = musicCompositionTrack;
    
    NSArray *sliceTimeRanges = [self.sliceTimeRanges copy];
    NSArray *transitionTimeRanges = [self.transitionTimeRanges copy];
    NSArray *passThroughTimeRanges = [self.passThroughTimeRanges copy];
    
//    audioTrackIDs[0] = compositionAudioTracks[0].trackID;
    
    
    ///<insert video
    for (NSUInteger i = 0; i < self.sliceArray.count; i++) {
        NSInteger alternatingIndex = i % 2;
        ///<Get source track
        LYMovieSlice *slice = self.sliceArray[i];
        AVAsset *asset = slice.video;
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        AVAssetTrack *audioTrack = nil;
        if (audioTracks.count != 0) {
            audioTrack = audioTracks[0];
        }
        CMTimeRange sliceRange = [sliceTimeRanges[i] CMTimeRangeValue];
        
        [compositionVideoTracks[alternatingIndex] insertTimeRange:slice.clipRange ofTrack:videoTrack atTime:sliceRange.start error:nil];
        [compositionVideoTracks[alternatingIndex] scaleTimeRange:CMTimeRangeMake(sliceRange.start, slice.clipRange.duration) toDuration:slice.sliceDuration];
        
        if (audioTrack != nil) {
            [compositionAudioTracks[alternatingIndex] insertTimeRange:slice.clipRange ofTrack:audioTrack atTime:sliceRange.start error:nil];
            [compositionAudioTracks[alternatingIndex] scaleTimeRange:CMTimeRangeMake(sliceRange.start, slice.clipRange.duration) toDuration:slice.sliceDuration];
        }
        
    }
    
    ///<insert music
    if (self.music != nil) {
//        NSURL *musicUrl = self.music.assetURL;
//        AVAsset *music = [AVAsset assetWithURL:musicUrl];
        NSURL *url = [NSURL fileURLWithPath:(NSString *)self.music];
        AVAsset *music = [AVURLAsset URLAssetWithURL:url options:nil];
        NSArray *musicAudioTracks = [music tracksWithMediaType:AVMediaTypeAudio];
        if (musicAudioTracks.count != 0) {
            AVAssetTrack *musicAudioTrack = musicAudioTracks[0];
            CMTime musicDuration = musicAudioTrack.timeRange.duration;
            //get video total
            CMTimeRange videoLast = [[sliceTimeRanges lastObject] CMTimeRangeValue];
            CMTimeRange videoTotal = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(videoLast.start, videoLast.duration));
            
            CMTime musicInsertTime = kCMTimeZero;
            CMTime insertDuration  = musicDuration;
            CMTime leftDuration    = videoTotal.duration;
            BOOL toEnd = NO;
            while (!toEnd) {
                if (CMTimeCompare(insertDuration, leftDuration) >= 0) {
                    insertDuration = leftDuration;
                    toEnd = YES;
                }
                [musicCompositionTrack insertTimeRange:CMTimeRangeMake(musicInsertTime, insertDuration) ofTrack:musicAudioTrack atTime:kCMTimeZero error:nil];
                musicInsertTime = CMTimeAdd(musicInsertTime, insertDuration);
                leftDuration = CMTimeSubtract(videoTotal.duration, insertDuration);
            }
            
        }
    }
    
    __weak typeof(self) weakSelf = self;
//    NSArray *sliceRanges = [self.sliceTimeRanges copy];
    
    CIImage *(^precondition)(CIImage *,LYMovieSlice *) = ^CIImage *(CIImage *sourceImage,LYMovieSlice *slice) {
        @autoreleasepool {
            CIImage *output = sourceImage;
            //transform
            CGAffineTransform transform = slice.videoTransform;
            CGAffineTransform invert = CGAffineTransformInvert(transform);
            output = [output imageByApplyingTransform:invert];
            output = [output imageByApplyingTransform:CGAffineTransformMakeTranslation(-output.extent.origin.x, -output.extent.origin.y)];
            //crop
            if (slice.needCut) {
                CGRect rect = output.extent;
                rect.origin.y = CGRectGetHeight(rect) * slice.cutLocation;
                rect.size.height = CGRectGetWidth(rect) * 9.f / 16.f;
                output = [output imageByCroppingToRect:rect];
                output = [output imageByApplyingTransform:CGAffineTransformMakeTranslation(-output.extent.origin.x, -output.extent.origin.y)];
            }
            //resize
            if (!CGSizeEqualToSize(output.extent.size, targetSize)) {
                output = [output imageByApplyingTransform:CGAffineTransformMakeScale(targetSize.width / output.extent.size.width, targetSize.height / output.extent.size.height)];
            }
            return output;
        }
    };
    
    ///滤镜，转场，覆盖物等
    MainParseBlock mainParse = ^CIImage *(CIImage *sourceImage, CMTime compositionTime) {
        @autoreleasepool {
            CIImage *output = sourceImage;
            //filter
            if (weakSelf.filter) {
                output = [weakSelf.filter filtedImageWithRawImage:output];
            }
            
            //overlay
            for (id<LYMovieOverlay> overlay in weakSelf.overlays) {
                output = [overlay applyOverlay:output AtMovieTime:compositionTime];
            }
            return output;
            
        }
    };
    
    ///<使用兼容9.0以下版本方法
    videoComposition =  [AVMutableVideoComposition videoComposition];
    videoComposition.customVideoCompositorClass = [LYVideoEditVideoCompositor class];
    NSMutableArray *instructions = [NSMutableArray array];
    

    for (NSUInteger i = 0; i < self.sliceArray.count; i++) {
        NSInteger alternatingIndex = i % 2;
        LYMovieSlice *slice = self.sliceArray[i];
        __weak typeof(slice) weakSlice = slice;
        CMTimeRange passThroughTimeRange = [passThroughTimeRanges[i] CMTimeRangeValue];
        LYVideoEditCompositionInstruction *videoInstruction = nil;
        if (i == 0) { ///<slice first
            videoInstruction = [[LYVideoEditCompositionInstruction alloc]
                                initWithTrackID:compositionVideoTracks[alternatingIndex].trackID
                                timeRange:passThroughTimeRange
                                precondition:^CIImage *(CIImage *image) {
                                    return precondition(image,weakSlice);
                                }
                                mainParse:mainParse];
        }else {
             CMTimeRange transitionTimeRange = [transitionTimeRanges[i - 1] CMTimeRangeValue];
            if (transitionTimeRange.duration.value != 0) {
                LYMovieSlice *preSlice = self.sliceArray[i - 1];
                __weak typeof(preSlice) weakPreSlice = preSlice;
//                CMTimeRange preTransitionTimeRange = [transitionTimeRanges[i - 1] CMTimeRangeValue];
                
                CMTimeRange instructionRange = CMTimeRangeMake(transitionTimeRange.start, CMTimeAdd(transitionTimeRange.duration, passThroughTimeRange.duration));
                
                
                videoInstruction = [[LYVideoEditCompositionInstruction alloc]
                                    initWithTrackID:compositionVideoTracks[alternatingIndex].trackID
                                    timeRange:instructionRange
                                    precondition:^CIImage *(CIImage *image) {
                                        return precondition(image,weakSlice);
                                    }
                                    mainParse:mainParse];
                videoInstruction.hasTransition = YES;
                videoInstruction.backgroundTrackID = compositionVideoTracks[1 - alternatingIndex].trackID;
                videoInstruction.transitionTimeRange = transitionTimeRange;
                videoInstruction.tBlock = ^CIImage *(CIImage *f, CIImage *b, float tf) {
                    return [weakSlice.transitionFilter filtedImageWithRawImage:f andTransitionImage:b andTransitionValue:tf];
                };
                
                videoInstruction.bgPreConditionBlock = ^CIImage *(CIImage *image) {
                    return precondition(image,weakPreSlice);
                };
            }else {
                videoInstruction = [[LYVideoEditCompositionInstruction alloc]
                                    initWithTrackID:compositionVideoTracks[alternatingIndex].trackID
                                    timeRange:passThroughTimeRange
                                    precondition:^CIImage *(CIImage *image) {
                                        return precondition(image,weakSlice);
                                    }
                                    mainParse:mainParse];
            }

        }
        [instructions addObject:videoInstruction];
    }
    
    videoComposition.instructions = instructions;
    
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.renderSize = targetSize;
    self.composition = composition;
    self.videoComposition = videoComposition;
    [self buildAudioMix];
}

- (void)buildAudioMix {
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *exportAudioMixInputParameters[3];
    exportAudioMixInputParameters[0] = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_compositionAudioTracks[0]];
    exportAudioMixInputParameters[1] = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_compositionAudioTracks[1]];
    exportAudioMixInputParameters[2] = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_compositionAudioTracks[2]];
    
    
    ///raw sound parameter
    float targetMovieVolumn = self.movieSoundVolume;
    for (NSUInteger i = 0; i < self.passThroughTimeRanges.count; i++) {
        NSInteger alternatingIndex = i % 2;
        CMTimeRange passThroughTimeRange = [self.passThroughTimeRanges[i] CMTimeRangeValue];
        [exportAudioMixInputParameters[alternatingIndex] setVolume:targetMovieVolumn atTime:passThroughTimeRange.start];
        if (i + 1 <= self.transitionTimeRanges.count) {
            CMTimeRange transitionTimeRange = [self.transitionTimeRanges[i] CMTimeRangeValue];
            if (transitionTimeRange.duration.value != 0) {
                [exportAudioMixInputParameters[alternatingIndex] setVolumeRampFromStartVolume:targetMovieVolumn toEndVolume:0.f timeRange:transitionTimeRange];
                [exportAudioMixInputParameters[1 - alternatingIndex] setVolumeRampFromStartVolume:0.f toEndVolume:targetMovieVolumn timeRange:transitionTimeRange];
            }
        }
    }
    ///movie sound parameter
    float targetMusicVolumn = self.musicSoundVolume;
    [exportAudioMixInputParameters[2] setVolume:targetMusicVolumn atTime:kCMTimeZero];
    
    
    audioMix.inputParameters = @[exportAudioMixInputParameters[0],exportAudioMixInputParameters[1],exportAudioMixInputParameters[2]];
    self.audioMix = audioMix;
}

- (void)exportMovieToPath:(NSString *)path WithProgress:(void (^)(float))percentBlock completion:(void (^)(BOOL, NSError *))complete {
    AVMutableComposition *composition = self.composition;
    AVMutableVideoComposition *videoCompostion = self.videoComposition;
    AVMutableAudioMix   *audioMix = self.audioMix;
    
    //    exportSession.videoComposition = videoComposition;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp_movie_file.mp4"];
    if ([fm fileExistsAtPath:tmpPath]) {
        [fm removeItemAtPath:tmpPath error:&error];
    }
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.videoComposition = videoCompostion;
    exportSession.audioMix = audioMix;
    [exportSession setOutputURL:[NSURL fileURLWithPath:tmpPath]];
    [exportSession setOutputFileType:AVFileTypeMPEG4];
    [exportSession setShouldOptimizeForNetworkUse:YES];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusFailed) {
            NSLog(@"failed");
        } else if(exportSession.status == AVAssetExportSessionStatusCompleted){
            NSLog(@"completed!");
            // here you can get the output url.
        }
    }];
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.operationQueue);
    
    objc_setAssociatedObject(self, (__bridge const void *)(exportSession), timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0.001 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        AVAssetExportSessionStatus status = exportSession.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            dispatch_source_cancel(timer);
            objc_setAssociatedObject(self, (__bridge const void *)(exportSession), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:path error:&error];
            if (complete) dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    complete(NO,error);
                }
                else {
                    complete(YES,nil);
                }
            });
        }
        else if (status == AVAssetExportSessionStatusWaiting) {
        }
        else if (status == AVAssetExportSessionStatusExporting) {
            //                complete(YES,nil);
            if (percentBlock) dispatch_async(dispatch_get_main_queue(), ^{
                if (percentBlock) percentBlock(exportSession.progress);
            });
        }else if (status == AVAssetExportSessionStatusUnknown) {
            
        }
        else {
            dispatch_source_cancel(timer);
            objc_setAssociatedObject(self, (__bridge const void *)(exportSession), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (complete) dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"exportSessionStatus:%ld",(long)status);
                if (complete) complete(NO,exportSession.error);
            });
        }
    });
    dispatch_resume(timer);
    
}


@end
