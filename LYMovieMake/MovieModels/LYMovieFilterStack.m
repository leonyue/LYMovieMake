//
//  LYMovieFilterStack.m
//  LYMovieMake
//
//  Created by dj.yue on 16/6/30.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieFilterStack.h"
//#import "utility.h"

@interface LYMovieFilterStack ()

@property (nonatomic, strong, readwrite) NSDictionary   *filterEffectDictionary;
@property (nonatomic, strong, readwrite) NSMutableArray *filterArray;
@property (nonatomic, strong, readwrite) CIImage        *demo;

@end

@implementation LYMovieFilterStack


- (id)initWithDemoImage:(UIImage *)demo {
    self = [super init];
    if (self) {
        self.demo = [[CIImage alloc] initWithImage:demo];
        NSAssert(self.demo, @"demo can not be nil");
        [self setUp];
    }
    return self;
}

- (void)setUp {
    NSArray *filterNameArray = @[@"None",@"CIVignetteEffect",@"CIPhotoEffectFade",@"CIPhotoEffectChrome",@"CIPhotoEffectProcess",@"CIPhotoEffectTransfer",@"CIPhotoEffectInstant",@"CISepiaTone",@"CIFalseColor",@"CIPhotoEffectMono",@"CIPhotoEffectTonal",@"CIPhotoEffectNoir"];
    NSArray *filterTitleArray;
    
    
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    BOOL isChinese = [currentLanguage isEqualToString:@"zh-Hans"];
    
    if (isChinese) {
        filterTitleArray = @[@"无",@"黯影",@"褪色",@"铬黄",@"冲印",@"岁月",@"怀旧",@"墨色",@"虚色",@"单色",@"色调",@"黑白"];
    }else {
        filterTitleArray  = @[@"None",@"Vignette",@"Fade",@"Chrome",@"Process",@"Transfer",@"Instant",@"Sepia",@"False",@"Mono",@"Tonal",@"Noir"];
    }
    self.filterArray = [[NSMutableArray alloc] init];
    NSAssert(filterNameArray.count == filterTitleArray.count, @"filter name count must equal to title count");
    for (NSInteger filterIndex = 0; filterIndex < filterNameArray.count; filterIndex++) {
        [self.filterArray addObject:[[LYMovieFilter alloc] initWithDemoImage:self.demo andFilterName:filterNameArray[filterIndex] andTitle:filterTitleArray[filterIndex]]];
    }
    NSMutableArray *titleArray = [NSMutableArray array];
    NSMutableArray *imageArray = [NSMutableArray array];
    for (LYMovieFilter *filter in self.filterArray) {
        [titleArray addObject:filter.title];
        [imageArray addObject:filter.image];
    }
    self.filterEffectDictionary = [NSDictionary dictionaryWithObjectsAndKeys:titleArray,@"title",imageArray,@"image", nil];
}

- (LYMovieFilter *)filterAtIndex:(NSUInteger)index {
    return [self.filterArray objectAtIndex:index];
}
- (NSUInteger)indexOfFilter:(LYMovieFilter *)filter {
    NSUInteger index = [self.filterArray indexOfObject:filter];
    if (index == NSNotFound) {
        index = 0;
    }
    return index;
}

@end
