//
//  UIImage+Resize.h
//  LYMovieMake
//
//  Created by dj.yue on 5/30/16.
//  Copyright © 2016 dj.yue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)scaleImageToSize:(CGSize)size;
- (UIImage *)rotatedImageWithCroppedToRect:(CGRect)rect;
- (UIImage *)imageForRotation:(UIImageOrientation)orientation;

@end
