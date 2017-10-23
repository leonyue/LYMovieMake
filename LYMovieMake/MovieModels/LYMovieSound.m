//
//  LYMovieSound.m
//  LYMovieMake
//
//  Created by dj.yue on 16/6/22.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import "LYMovieSound.h"

@implementation LYMovieSound

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.audio = [AVAsset assetWithURL:url];
    }
    return self;
}

@end
