//
//  VideoEditOpenGLRenderer.h
//  LYMovieMake
//
//  Created by dj.yue on 16/8/4.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreImage/CoreImage.h>


typedef CIImage *(^FilterOperationBlock)(CIImage *);
typedef CIImage *(^TransitionOperationBlock)(CIImage *foreGround, CIImage *backGround);

@interface LYVideoEditOpenGLRenderer : NSObject


/**
 Normal

 @param destination dst
 @param source source
 @param block parse block
 */
- (void)renderPixelBuffer:(CVPixelBufferRef)destination
        usingSourceBuffer:(CVPixelBufferRef)source
                   filter:(FilterOperationBlock)block;

/**
 Transition,first filter,second transition

 @param destination dst
 @param foreGround fg
 @param backGround bg
 @param fgBlock foreground parse block
 @param bgBlock background parse block
 @param transitionBlock transition block
 */
- (void)renderPixelBuffer:(CVPixelBufferRef)destination
     usingForeGoundBuffer:(CVPixelBufferRef)foreGround
         backGroundBuffer:(CVPixelBufferRef)backGround
                 fgFilter:(FilterOperationBlock)fgBlock
                 bgFilter:(FilterOperationBlock)bgBlock
         transitionFilter:(TransitionOperationBlock)transitionBlock;
@end

