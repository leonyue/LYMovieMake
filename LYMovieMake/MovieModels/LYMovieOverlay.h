//
//  LYMovieOverlay.h
//  LYMovieMake
//
//  Created by dj.yue on 16/6/22.
//  Copyright © 2016年 dj.yue. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LYMovieOverlay <NSObject>
@required
- (CIImage *)applyOverlay:(CIImage *)raw AtMovieTime:(CMTime)time;

@end
