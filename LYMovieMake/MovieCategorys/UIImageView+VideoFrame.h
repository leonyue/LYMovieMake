//
//  UIImageView+VideoFrame.h
//  LYMovieMake
//
//  Created by dj.yue on 16/5/31.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LYVideoFrameGenerator.h"

@interface UIImageView (VideoFrame)

- (void)ve_setImageWithGenerator:(LYVideoFrameGenerator *)generator
                           index:(NSUInteger)index
                placeholderImage:(UIImage *)placeholderImage
                       completed:(void(^)(UIImage * image, CMTime getTime, CMTime actualTime, NSError *error))completeBlock;
- (void)ve_setImageWithVideo:(NSString *)videoPath
            placeholderImage:(UIImage *)placeholderImage
                   completed:(void (^)(UIImage *, NSError *))completeBlock;

- (void)ve_setImageWithPath:(NSString *)path;

/** 获取本地一帧 **/
+ (UIImage *)getImageWithUrl:(AVAsset *)asset;
//- (void)ve_setImageWithGenerator:(BreezeVideoFrameGenerator *)generator
//                placeholderImage:(UIImage *)placeholderImage
//                       completed:(void(^)(UIImage * image, NSError *error))completeBlock;

@end
