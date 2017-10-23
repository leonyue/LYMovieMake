//
//  LYMovieFilter.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/13.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LYMovieFilter : NSObject


@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, strong, readonly) NSString *title;

- (id)initWithDemoImage:(CIImage *)demo andFilterName:(NSString *)name andTitle:(NSString *)title;
- (UIImage *)filteredImage:(UIImage*)image;
- (CIImage *)filtedImageWithRawImage:(CIImage *)rawImage;

@end
