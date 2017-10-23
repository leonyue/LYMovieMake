//
//  LYVideoEditCompositionInstruction.m
//  LYMovieMake
//
//  Created by dj.yue on 16/8/5.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYVideoEditCompositionInstruction.h"

@implementation LYVideoEditCompositionInstruction

@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;


- (instancetype)initWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange precondition:(PreconditionBlock)precondition mainParse:(MainParseBlock)mainParse {
    self = [super init];
    if (self) {
        ///<property set
        self.foregroundTrackID = trackID;
        self.fgPreConditionBlock = precondition;
        self.mainParseBlock = mainParse;
        self.hasTransition = NO;
        
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _requiredSourceTrackIDs = nil;
        _timeRange = timeRange;
        _containsTweening = FALSE;
        _enablePostProcessing = FALSE;
    }
    return self;
}

@end
