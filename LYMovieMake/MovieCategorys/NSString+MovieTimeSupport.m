//
//  NSString+MovieTimeSupport.m
//  LYMovieMake
//
//  Created by dj.yue on 2017/3/10.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "NSString+MovieTimeSupport.h"

@implementation NSString (MovieTimeSupport)

+ (instancetype)stringWithCMTime:(CMTime)time {
    Float64 seconds = CMTimeGetSeconds(time);
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    if (CMTimeGetSeconds(time) >= 3600) {
        [dateFormatter setDateFormat:@"HH:mm:ss"];
    }
    else {
        [dateFormatter setDateFormat:@"mm:ss"];
    }
    return [dateFormatter stringFromDate:date];
}

@end
