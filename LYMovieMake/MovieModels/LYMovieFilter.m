//
//  LYMovieFilter.m
//  LYMovieMake
//
//  Created by dj.yue on 16/6/13.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieFilter.h"
#import "CIFilter+FHAdditions.h"

@interface LYMovieFilter ()

@property (nonatomic,strong) CIFilter *filter;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *title;
@end

@implementation LYMovieFilter

- (CIImage *)filtedImageWithRawImage:(CIImage *)rawImage {
    CIFilter *ff = self.filter;
    if (ff == nil) {
        return rawImage;
    }
    CIImage *outputImage = rawImage;
    for (NSString *attrName in [ff imageInputAttributeKeys])
    {
        CIImage *top = outputImage;
        if (top) {
            [ff setValue:top forKey:attrName];
        }
    }
    if([ff.name isEqualToString:@"CIVignetteEffect"]){
        // parameters for CIVignetteEffect
        CGRect imgRect =  rawImage.extent;
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat R = MIN(imgRect.size.width, imgRect.size.height) * scale;
        CIVector *vct = [[CIVector alloc] initWithX:imgRect.size.width * scale / 2 Y:imgRect.size.height * scale / 2];
        [ff setValue:vct forKey:@"inputCenter"];
        [ff setValue:[NSNumber numberWithFloat:0.9] forKey:@"inputIntensity"];
        [ff setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    }
    outputImage = ff.outputImage;
    return outputImage;
}

- (UIImage *)filteredImage:(UIImage*)image
{
    CIFilter *filter = self.filter;
    if (filter == nil) {
        return image;
    }
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    for (NSString *attrName in [filter imageInputAttributeKeys])
    {
        CIImage *top = ciImage;
        if (top) {
            [filter setValue:top forKey:attrName];
        }
    }
    
    [filter setDefaults];
    
    if([filter.name isEqualToString:@"CIVignetteEffect"]){
        
        // parameters for CIVignetteEffect
        CGFloat R = MIN(image.size.width, image.size.height) * image.scale / 2;
        CIVector *vct = [[CIVector alloc] initWithX:image.size.width*image.scale/2 Y:image.size.height*image.scale/2];
        [filter setValue:vct forKey:@"inputCenter"];
        [filter setValue:[NSNumber numberWithFloat:0.9] forKey:@"inputIntensity"];
        [filter setValue:[NSNumber numberWithFloat:R] forKey:@"inputRadius"];
    }
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return result;
}

- (id)initWithDemoImage:(CIImage *)demo andFilterName:(NSString *)name andTitle:(NSString *)title{
    self = [super init];
    if (self) {
        self.filter = [CIFilter filterWithName:name];
        self.title = title;
        self.image = [UIImage imageWithCIImage:[self filtedImageWithRawImage:demo]];
    }
    return self;
}



@end
