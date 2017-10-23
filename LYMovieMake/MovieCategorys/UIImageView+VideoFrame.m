//
//  UIImageView+VideoFrame.m
//  LYMovieMake
//
//  Created by dj.yue on 16/5/31.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "UIImageView+VideoFrame.h"
#import "UIImage+Resize.h"
#import <objc/runtime.h>
#import "LYVideoFrameGenerator.h"
//#import "utility.h"

@implementation UIImageView (VideoFrame)

- (void)ve_setImageWithGenerator:(LYVideoFrameGenerator *)generator
                           index:(NSUInteger)index
                placeholderImage:(UIImage *)placeholderImage
                       completed:(void (^)(UIImage *, CMTime, CMTime, NSError *))completeBlock {
    if ([NSThread isMainThread]) {
        self.image = placeholderImage;
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = placeholderImage;
        });
    }
    [generator generateVideoFrameWithIndex:index completed:^(UIImage *image, CMTime getTime, CMTime actualTime, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                self.image = image;
            }
            if (completeBlock) completeBlock(image,getTime,actualTime,error);
        });
    }];
}

- (void)ve_setImageWithVideo:(NSString *)videoPath
            placeholderImage:(UIImage *)placeholderImage
                   completed:(void (^)(UIImage *, NSError *))completeBlock {
    NSString *previewImagePath = [[videoPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:previewImagePath]) {
        UIImage *preview = [UIImage imageWithContentsOfFile:previewImagePath];
        if ([NSThread isMainThread]) {
            self.image = preview;
            if (completeBlock) completeBlock(preview,nil);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = preview;
                if (completeBlock) completeBlock(preview,nil);
            });
        }
    }
    else {
        if ([NSThread isMainThread]) {
            self.image = placeholderImage;
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = placeholderImage;
            });
        }
        LYVideoFrameGenerator *generator = [LYVideoFrameGenerator generatorWithVideo:[AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]]];
        generator.maximumSize = CGSizeMake(640, 360);
        
        [generator generatePreviewCompleted:^(UIImage *image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    self.image = image;
                    [UIImageJPEGRepresentation(image, 0.6f) writeToFile:previewImagePath atomically:YES];
                }
                if (completeBlock) completeBlock(image,error);
            });
        }];
    }
}

- (void)ve_setImageWithPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image;
        });
        
    }
}


// 获取本地视频的第一帧的图片
+ (UIImage *)getImageWithUrl:(AVAsset *)asset
{
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}
//- (void)ve_setImageWithGenerator:(BreezeVideoFrameGenerator *)generator placeholderImage:(UIImage *)placeholderImage completed:(void (^)(UIImage *, NSError *))completeBlock {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.image = placeholderImage;
//    });
//    [generator generateVideoFrameCompleted:^(UIImage *image, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (image) {
//                self.image = image;
//            }
//            if (completeBlock) completeBlock(image,error);
//        });
//    }];
//}

@end
