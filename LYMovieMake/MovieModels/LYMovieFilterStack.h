//
//  LYMovieFilterStack.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/30.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYMovieFilter.h"

@interface LYMovieFilterStack : NSObject


/**
 title:<>, image:<>
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *,NSArray *> *filterEffectDictionary;

- (id)initWithDemoImage:(UIImage *)demo;
- (LYMovieFilter *)filterAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfFilter:(LYMovieFilter *)filter;

@end
