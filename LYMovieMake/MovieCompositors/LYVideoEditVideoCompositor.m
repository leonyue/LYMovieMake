//
//  VideoEditVideoCompositor.m
//  LYMovieMake
//
//  Created by dj.yue on 16/8/5.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYVideoEditVideoCompositor.h"
#import "LYVideoEditOpenGLRenderer.h"
#import "LYVideoEditCompositionInstruction.h"
#import "LYMovieTransitionFilterStack.h"

#import <CoreVideo/CoreVideo.h>


@interface LYVideoEditVideoCompositor()
{
    BOOL								_shouldCancelAllRequests;
    dispatch_queue_t					_renderingQueue;
    dispatch_queue_t					_renderContextQueue;
    AVVideoCompositionRenderContext*	_renderContext;
}

@property (nonatomic, strong) LYVideoEditOpenGLRenderer *oglRenderer;

@end

@implementation LYVideoEditVideoCompositor

- (id)init
{
    self = [super init];
    
    if (self) {
        _renderingQueue = dispatch_queue_create("com.dj.yue.moviemake.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.dj.yue.moviemake.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        self.oglRenderer = [[LYVideoEditOpenGLRenderer alloc] init];
    }
    
    return self;
}

- (NSDictionary<NSString *,id> *)sourcePixelBufferAttributes {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary<NSString *,id> *)requiredPixelBufferAttributesForRenderContext {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    dispatch_sync(_renderContextQueue, ^() {
        _renderContext = newRenderContext;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)asyncVideoCompositionRequest {
    @autoreleasepool {
        dispatch_async(_renderingQueue,^() {
            
            // Check if all pending requests have been cancelled
            if (_shouldCancelAllRequests) {
                [asyncVideoCompositionRequest finishCancelledRequest];
            } else {
                NSError *err = nil;
                // Get the next rendererd pixel buffer
                CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:asyncVideoCompositionRequest error:&err];
                
                if (resultPixels) {
                    // The resulting pixelbuffer from OpenGL renderer is passed along to the request
                    [asyncVideoCompositionRequest finishWithComposedVideoFrame:resultPixels];
                    CFRelease(resultPixels);
                } else {
                    [asyncVideoCompositionRequest finishWithError:err];
                }
            }
        });
    }
}

- (void)cancelAllPendingVideoCompositionRequests
{
    // pending requests will call finishCancelledRequest, those already rendering will call finishWithComposedVideoFrame
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        // start accepting requests again
        _shouldCancelAllRequests = NO;
    });
}

#pragma mark - Utilities

static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}


- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    @autoreleasepool {
        CVPixelBufferRef dstPixels = nil;
        dstPixels = [_renderContext newPixelBuffer];
        LYVideoEditCompositionInstruction *instruction = request.videoCompositionInstruction;
        CVPixelBufferRef foregroundBuffer = [request sourceFrameByTrackID:instruction.foregroundTrackID];///<Get foreground
        CMTime compositionTime = request.compositionTime;
        
        
        
        __weak typeof(instruction) weakInstruction = instruction;
        if (instruction.hasTransition && CMTimeRangeContainsTime(instruction.transitionTimeRange, compositionTime)) { ///<transition time
            CVPixelBufferRef backgroundBuffer = [request sourceFrameByTrackID:instruction.backgroundTrackID];///<Get background
            float tweenFactor = factorForTimeInRange(compositionTime, instruction.transitionTimeRange);
            [_oglRenderer renderPixelBuffer:dstPixels usingForeGoundBuffer:foregroundBuffer backGroundBuffer:backgroundBuffer fgFilter:^CIImage *(CIImage *sourceImage) {
                return weakInstruction.fgPreConditionBlock(sourceImage);
            } bgFilter:^CIImage *(CIImage *sourceImage) {
                return weakInstruction.bgPreConditionBlock(sourceImage);
            } transitionFilter:^CIImage *(CIImage *foreGround, CIImage *backGround) {
                return weakInstruction.mainParseBlock(weakInstruction.tBlock(foreGround,backGround,tweenFactor),compositionTime);
            }];
            
        }else { ///<common
            [_oglRenderer renderPixelBuffer:dstPixels usingSourceBuffer:foregroundBuffer filter:^CIImage *(CIImage *sourceImage) {
                return weakInstruction.mainParseBlock(weakInstruction.fgPreConditionBlock(sourceImage),compositionTime);
            }];
        }
        

        return dstPixels;
        

    }

}

@end
