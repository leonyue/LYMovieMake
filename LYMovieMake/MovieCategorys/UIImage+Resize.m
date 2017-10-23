//
//  UIImage+Resize.m
//  LYMovieMake
//
//  Created by dj.yue on 5/30/16.
//  Copyright © 2016 dj.yue. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)imageByScalingToSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    //   CGSize imageSize = sourceImage.size;
    //   CGFloat width = imageSize.width;
    //   CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    //   CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage ;
}

- (UIImage *)scaleImageToSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 1.0f);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)rotatedImageWithCroppedToRect:(CGRect)rect
{
    CGFloat scale = self.scale;
    CGRect cropRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
    
    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage *image = [UIImage imageWithCGImage:croppedImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(croppedImage);
    
    return image;
}

- (UIImage *)imageForRotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), self.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    //CGContextRelease(context);
    
    return newPic;
}

- (UIImage *)scaleAndClipToFillSize:(CGSize)destSize
{
    CGFloat showWidth = destSize.width;
    CGFloat showHeight = destSize.height;
    CGFloat scaleHeight = showHeight;
    
    CGFloat scaleWidth = ceilf(scaleHeight / self.size.height * self.size.width);
    if (scaleWidth < destSize.width) {
        scaleWidth = destSize.width;
        scaleHeight = ceilf(scaleWidth / self.size.width * self.size.height);
    }
    
    //scale
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaleWidth, scaleHeight), NO, 0.0f);
    [self drawInRect:CGRectMake(0, 0, scaleWidth, scaleHeight)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //clip
    CGFloat originX = ceilf((scaleWidth - showWidth) / 2);
    CGFloat originY = ceilf((scaleHeight - showHeight) / 2);
    
    
    CGRect cropRect = CGRectMake(ceilf(originX * scaledImage.scale),
                                 ceilf(originY * scaledImage.scale),
                                 ceilf(showWidth * scaledImage.scale),
                                 ceilf(showHeight * scaledImage.scale));
    return [scaledImage cropImageInRect:cropRect];
}

- (UIImage *)cropImageInRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *cropImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropImage;
}



- (UIImage *)gaussianBlurWithRadius:(CGFloat)radius
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

- (UIImage *)ellipseImageWithDefaultSetting
{
    return [self ellipseImage:self withInset:0 borderWidth:0 borderColor:[UIColor clearColor]];
}

- (UIImage *)ellipseImage:(UIImage *)image
                withInset:(CGFloat)inset
              borderWidth:(CGFloat)width
              borderColor:(UIColor *)color
{
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(inset,
                             inset,
                             image.size.width - inset * 2.0f,
                             image.size.height - inset * 2.0f);
    
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    [image drawInRect:rect];
    
    if (width > 0) {
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextSetLineCap(context, kCGLineCapButt);
        CGContextSetLineWidth(context, width);
        CGContextAddEllipseInRect(context, CGRectMake(inset + width / 2,
                                                      inset +  width / 2,
                                                      image.size.width - width - inset * 2.0f,
                                                      image.size.height - width - inset * 2.0f));
        
        CGContextStrokePath(context);
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageCropForRect:(CGRect)targetRect
{
    targetRect.origin.x*=self.scale;
    targetRect.origin.y*=self.scale;
    targetRect.size.width*=self.scale;
    targetRect.size.height*=self.scale;
    
    if (targetRect.origin.x<0) {
        targetRect.origin.x = 0;
    }
    if (targetRect.origin.y<0) {
        targetRect.origin.y = 0;
    }
    
    //宽度高度过界就删去
    CGFloat cgWidth = CGImageGetWidth(self.CGImage);
    CGFloat cgHeight = CGImageGetHeight(self.CGImage);
    if (CGRectGetMaxX(targetRect)>cgWidth) {
        targetRect.size.width = cgWidth-targetRect.origin.x;
    }
    if (CGRectGetMaxY(targetRect)>cgHeight) {
        targetRect.size.height = cgHeight-targetRect.origin.y;
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, targetRect);
    UIImage *resultImage=[UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    //修正回原scale和方向
    resultImage = [UIImage imageWithCGImage:resultImage.CGImage scale:self.scale orientation:self.imageOrientation];
    
    return resultImage;
}



@end
