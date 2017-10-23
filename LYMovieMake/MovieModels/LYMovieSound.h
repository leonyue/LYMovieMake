//
//  LYMovieSound.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/22.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LYMovieSound : NSObject

@property (nonatomic, strong          ) AVAsset      *audio;

- (instancetype)initWithURL:(NSURL *)url;

@end
