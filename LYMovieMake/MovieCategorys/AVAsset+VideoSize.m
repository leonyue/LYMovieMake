//
//  AVAsset+VideoSize.m
//  LYMovieMake
//
//  Created by dj.yue on 2017/3/17.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "AVAsset+VideoSize.h"

@implementation AVAsset (VideoSize)

- (CGSize)size {
    NSArray<AVAssetTrack *> *videoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        return CGSizeMake(0, 0);
    }
    AVAssetTrack *track = [videoTracks objectAtIndex:0];
    CGSize size = track.naturalSize;
    CGAffineTransform transform = track.preferredTransform;
    CGAffineTransform invertTrans = CGAffineTransformInvert(transform);
    size = CGSizeApplyAffineTransform(size, invertTrans);
    size.width = fabs(size.width);
    size.height = fabs(size.height);
    return size;
}

@end
