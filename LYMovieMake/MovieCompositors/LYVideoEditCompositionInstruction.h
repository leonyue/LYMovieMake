//
//  LYVideoEditCompositionInstruction.h
//  LYMovieMake
//
//  Created by dj.yue on 16/8/5.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>



typedef CIImage *(^MainParseBlock)(CIImage *, CMTime);///<filter,waterprint

typedef CIImage *(^PreconditionBlock)(CIImage *);///<rotate,resize,crop

typedef CIImage *(^TransitionBlock)(CIImage *, CIImage *, float tweenFactor);///<transition

@interface LYVideoEditCompositionInstruction : NSObject<AVVideoCompositionInstruction>

@property (nonatomic, assign) CMPersistentTrackID foregroundTrackID;
@property (nonatomic, copy  ) PreconditionBlock   fgPreConditionBlock;
@property (nonatomic, copy  ) MainParseBlock      mainParseBlock;

@property (nonatomic, assign) BOOL                hasTransition;
@property (nonatomic, assign) CMPersistentTrackID backgroundTrackID;///<If contains transition, Need this
@property (nonatomic, assign) CMTimeRange         transitionTimeRange;///<If contains transition, Need this
@property (nonatomic, copy  ) PreconditionBlock   bgPreConditionBlock;///<If contains transition, Need this,Background parse
@property (nonatomic, copy  ) TransitionBlock     tBlock;///<If contains transition, Need this

/**
 Initialization,if transition set transition needed propertys too.

 @param trackID foregroundTrackID
 @param timeRange instruction time range
 @param precondition resize rotate block
 @param mainParse main parse block
 @return instance
 */
- (instancetype)initWithTrackID:(CMPersistentTrackID)trackID
                      timeRange:(CMTimeRange)timeRange
                   precondition:(PreconditionBlock)precondition
                      mainParse:(MainParseBlock)mainParse;

@end
