//
//  LYMovieTransitionFilter.m
//  LYMovieMake
//
//  Created by dj.yue on 16/7/7.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieTransitionFilter.h"
//#import "CIFilter+FHAdditions.h"

@interface LYMovieTransitionFilter ()

@property (nonatomic, assign) TransitionFilterType type;
@property (nonatomic,strong) CIFilter *filter;
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, strong, readwrite) UIImage *highlightImage;
@property (nonatomic, strong, readwrite) NSString *title;

@end

@implementation LYMovieTransitionFilter


- (CIImage *)filtedImageWithRawImage:(CIImage *)rawImage andTransitionImage:(CIImage *)transImage andTransitionValue:(double)value {
    CIFilter *ff = self.filter;
    if (ff == nil) {
        return rawImage;
    }
    CGSize size = rawImage.extent.size;
    [ff setValue:transImage forKey:kCIInputImageKey];
    [ff setValue:rawImage forKey:kCIInputTargetImageKey];
    [ff setValue:@(value) forKey:kCIInputTimeKey];
    if ([ff.inputKeys containsObject:kCIInputExtentKey]) {
        [ff setValue:[CIVector vectorWithCGRect:CGRectMake(0, 0, size.width, size.height)] forKey:kCIInputExtentKey];
    }
    CIImage *outputImage = ff.outputImage;
    return outputImage;
}

- (id)initWithTransitionFilterType:(TransitionFilterType)type {
    self = [super init];
    if (self) {
        self.type = type;
        [self setUp];
    }
    return self;
}

- (void)setUp {
    NSString *filterName;
    if (self.type == TransitionFilterTypeSwipe) {
        filterName = @"CISwipeTransition";
    }else if (self.type == TransitionFilterTypeRipple) {
        filterName = @"CIRippleTransition";
    }else if (self.type == TransitionFilterTypeDissolve) {
        filterName = @"CIDissolveTransition";
    }
    self.title = [LYMovieTransitionFilter titleFromFilterType:self.type];
    self.image = [LYMovieTransitionFilter imageFromFilterType:self.type];
    self.highlightImage = [LYMovieTransitionFilter highlightImageFromFilterType:self.type];
    
    if (filterName!=nil) {
        self.filter = [CIFilter filterWithName:filterName];
    }
}

+ (NSString *)titleFromFilterType:(TransitionFilterType)type {
    if (type == TransitionFilterTypeSwipe) {
        return @"Swipe";
    }else if (type == TransitionFilterTypeDissolve) {
        return @"Dissolve";
    }
    return @"NA";
}
+ (UIImage *)imageFromFilterType:(TransitionFilterType)type {
    if (type == TransitionFilterTypeSwipe) {
        return [UIImage imageNamed:@"transition_swipe"];
    }else if (type == TransitionFilterTypeDissolve) {
        return [UIImage imageNamed:@"transition_dissolve"];
    }
    return [UIImage imageNamed:@"transition_NA"];
}

+ (UIImage *)highlightImageFromFilterType:(TransitionFilterType)type {
    if (type == TransitionFilterTypeSwipe) {
        return [UIImage imageNamed:@"transition_swipe_hl"];
    }else if (type == TransitionFilterTypeDissolve) {
        return [UIImage imageNamed:@"transition_dissolve_hl"];
    }
    return [UIImage imageNamed:@"transition_NA_hl"];
}

@end
