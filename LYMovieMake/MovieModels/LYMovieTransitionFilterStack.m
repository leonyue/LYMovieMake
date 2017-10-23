//
//  LYMovieTransitionFilterStack.m
//  LYMovieMake
//
//  Created by dj.yue on 16/7/7.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieTransitionFilterStack.h"

@interface LYMovieTransitionFilterStack ()
@property (nonatomic, strong, readwrite) NSMutableArray *filterArray;
@end

static LYMovieTransitionFilterStack *sharedStack;

@implementation LYMovieTransitionFilterStack

+ (id)sharedTransitionFilterStack {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStack = [[LYMovieTransitionFilterStack alloc] init];
    });
    return sharedStack;
}


- (LYMovieTransitionFilter *)filterOfType:(TransitionFilterType)type {
    return self.filterArray[type];
}

- (LYMovieTransitionFilter *)defaultFilter {
    return [self.filterArray objectAtIndex:0];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    self.filterArray = [[NSMutableArray alloc] init];
    [self.filterArray addObject:[[LYMovieTransitionFilter alloc] initWithTransitionFilterType:TransitionFilterTypeNA]];
    [self.filterArray addObject:[[LYMovieTransitionFilter alloc] initWithTransitionFilterType:TransitionFilterTypeSwipe]];
    [self.filterArray addObject:[[LYMovieTransitionFilter alloc] initWithTransitionFilterType:TransitionFilterTypeDissolve]];
}

@end
