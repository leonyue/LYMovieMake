//
//  LYMovieTransitionFilterStack.h
//  LYMovieMake
//
//  Created by dj.yue on 16/7/7.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYMovieTransitionFilter.h"
@interface LYMovieTransitionFilterStack : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *filterArray;

+ (LYMovieTransitionFilterStack *)sharedTransitionFilterStack;
- (LYMovieTransitionFilter *)filterOfType:(TransitionFilterType)type;
- (LYMovieTransitionFilter *)defaultFilter;

@end
