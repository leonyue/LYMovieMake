//
//  LYSubTitle.m
//  LYMovieMake
//
//  Created by YC-JG-YXKF-PC35 on 16/6/15.
//  Copyright © 2016年 yuneec. All rights reserved.
//

#import "LYMovieSubTitle.h"

@interface LYMovieSubTitle ()

@property (nonatomic, strong) CIImage *titleImage;
@property (nonatomic, strong) CIFilter *filter;

@end

@implementation LYMovieSubTitle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefault];
    }
    return self;
}

- (CIImage *)applyOverlay:(CIImage *)raw AtMovieTime:(CMTime)time {
    return [self applyTitle:raw AtMovieTime:time];
}

- (CIImage *)applyTitle:(CIImage *)raw AtMovieTime:(CMTime)time{
    if (self.titleImage == nil || !CGSizeEqualToSize(self.titleImage.extent.size, raw.extent.size)) {
        [self createTitleImageWithSize:raw.extent.size];
    }
    if (!CMTimeRangeContainsTime(self.textRange, time)) {
        return raw;
    }
    if (self.filter == nil) {
        self.filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    }
    [self.filter setValue:self.titleImage forKey:kCIInputImageKey];
    [self.filter setValue:raw forKey:kCIInputBackgroundImageKey];
    return self.filter.outputImage;
}

- (void)setDefault {
    _textPosition       = CGPointMake(0, 0);
    _textFont       = [UIFont systemFontOfSize:80];
    _textColor      = [UIColor whiteColor];
    _textAngle          = M_PI_2;
    _textRange     = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
}

- (void)createTitleImageWithSize:(CGSize)titleSize {
    if (!self.text || [self.text isEqualToString:@""] || CMTIMERANGE_IS_EMPTY(self.textRange)) {
        return;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    CGSize size = [self.text boundingRectWithSize:titleSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.textFont, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;
    
    UIGraphicsBeginImageContext(titleSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint textCenter = self.textPosition;
    textCenter.x += size.width / 2;
    textCenter.y += size.height / 2;
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(textCenter.x, textCenter.y));
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(self.textAngle));
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-textCenter.x, -textCenter.y));
    [self.text drawInRect:CGRectMake(self.textPosition.x,
                                     self.textPosition.y,
                                     size.width,
                                     size.height)
           withAttributes:@{
                            NSFontAttributeName : self.textFont,
                            NSParagraphStyleAttributeName : paragraphStyle,
                            NSForegroundColorAttributeName : self.textColor
                            }];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.titleImage = [CIImage imageWithCGImage:image.CGImage];
}

- (void)setTextPosition:(CGPoint)textPosition {
    _textPosition = textPosition;
    self.titleImage = nil;
//    [self createTitleImage];
}
- (void)setText:(NSString *)text {
    _text = [text copy];
        self.titleImage = nil;
//    [self createTitleImage];
}
- (void)setTextFont:(UIFont *)textFont {
    _textFont = [textFont copy];
        self.titleImage = nil;
//    [self createTitleImage];
}
- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
        self.titleImage = nil;
//    [self createTitleImage];
}
- (void)setTextAngle:(CGFloat)textAngle {
    _textAngle = textAngle;
        self.titleImage = nil;
//    [self createTitleImage];
}
- (void)setTextRange:(CMTimeRange)textRange {
    _textRange = textRange;
        self.titleImage = nil;
//    [self createTitleImage];
}

//- (CIImage *)waterPrintedImage:(CIImage *)rawImage {
//    //    return [CIImage imageWithCGImage:[self textImage].CGImage];
//    CGSize back = rawImage.extent.size;
//    CGSize wp = self.waterPrint.extent.size;
//    
//    CIFilter *_filter = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
//                         kCIInputImageKey, [self.waterPrint imageByApplyingTransform:CGAffineTransformMakeTranslation(back.width - wp.width, 0.0)], kCIInputBackgroundImageKey, rawImage,
//                         nil];
//    return _filter.outputImage;
//}
@end
