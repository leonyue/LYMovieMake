//
//  LYMovieTransitionFilter.h
//  LYMovieMake
//
//  Created by dj.yue on 16/7/7.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum : NSUInteger {
    TransitionFilterTypeNA,
    TransitionFilterTypeSwipe,
    TransitionFilterTypeDissolve,
    TransitionFilterTypeRipple,
    TransitionFilterTypePageCurl,
} TransitionFilterType;

@interface LYMovieTransitionFilter : NSObject

@property (nonatomic, assign, readonly) TransitionFilterType type;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, strong, readonly) UIImage *highlightImage;
@property (nonatomic, strong, readonly) NSString *title;

- (id)initWithTransitionFilterType:(TransitionFilterType)type;
- (CIImage *)filtedImageWithRawImage:(CIImage *)rawImage andTransitionImage:(CIImage *)transImage andTransitionValue:(double)value;

+ (UIImage *)imageFromFilterType:(TransitionFilterType)type;
+ (UIImage *)highlightImageFromFilterType:(TransitionFilterType)type;
+ (NSString *)titleFromFilterType:(TransitionFilterType)type;

@end
