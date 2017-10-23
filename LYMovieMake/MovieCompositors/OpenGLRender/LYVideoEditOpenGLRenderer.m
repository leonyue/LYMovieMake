//
//  VideoEditOpenGLRenderer.m
//  LYMovieMake
//
//  Created by dj.yue on 16/8/4.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYVideoEditOpenGLRenderer.h"
//#import "utility.h"
@interface LYVideoEditOpenGLRenderer ()

@property (nonatomic, strong) EAGLContext  *currentContext;
@property (nonatomic, strong) CIContext    *ciContext;
@property (nonatomic, strong) NSDictionary *options;

@end

@implementation LYVideoEditOpenGLRenderer

- (id)init
{
    self = [super init];
    if(self) {
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _ciContext = [CIContext contextWithEAGLContext:_currentContext];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _options      = [NSDictionary dictionaryWithObject:(__bridge id)colorSpace forKey:kCIImageColorSpace];
        CGColorSpaceRelease(colorSpace);
    }
    
    return self;
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destination
        usingSourceBuffer:(CVPixelBufferRef)source
                   filter:(FilterOperationBlock)block {
    if (!source) {
        return;
    }
    @autoreleasepool {
        CIImage *inputImage        = [CIImage imageWithCVPixelBuffer:source options:_options];
        CIImage *outputImage       = block(inputImage);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        [self.ciContext render:outputImage
               toCVPixelBuffer:destination
                        bounds:[outputImage extent]
                    colorSpace:colorSpace
         ];
        CGColorSpaceRelease(colorSpace);
    }

}

- (void)renderPixelBuffer:(CVPixelBufferRef)destination
     usingForeGoundBuffer:(CVPixelBufferRef)foreGround
         backGroundBuffer:(CVPixelBufferRef)backGround
                 fgFilter:(FilterOperationBlock)fgBlock
                 bgFilter:(FilterOperationBlock)bgBlock
         transitionFilter:(TransitionOperationBlock)transitionBlock {
    if (!foreGround || !backGround) {
        return;
    }
    @autoreleasepool {
        CIImage *foreGroundImage   = [CIImage imageWithCVPixelBuffer:foreGround options:_options];
        CIImage *backGroundImage   = [CIImage imageWithCVPixelBuffer:backGround options:_options];
        foreGroundImage            = fgBlock(foreGroundImage);
        backGroundImage            = bgBlock(backGroundImage);
        CIImage *outputImage       = transitionBlock(foreGroundImage, backGroundImage);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        [self.ciContext render:outputImage
               toCVPixelBuffer:destination
                        bounds:[outputImage extent]
                    colorSpace:colorSpace
         ];
        CGColorSpaceRelease(colorSpace);
    }
}


@end
