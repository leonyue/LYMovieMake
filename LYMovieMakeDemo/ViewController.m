//
//  ViewController.m
//  LYMovieMake
//
//  Created by dj.yue on 2017/10/20.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <LYMovieMake/LYMovieMakeLib.h>
@interface ViewController ()

@property (nonatomic, strong) LYMovieMake *make;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)pickA:(id)sender {
    LYMovieMake *make = [[LYMovieMake alloc] init];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"mp4"];
    LYMovieSlice *slice = [[LYMovieSlice alloc] initWithURL:url];
    LYMovieSlice *slice2 = [[LYMovieSlice alloc] initWithURL:url];
    slice2.transitionFilter = [[LYMovieTransitionFilterStack sharedTransitionFilterStack] filterOfType:TransitionFilterTypeSwipe];
    [make addSlice:slice];
    [make addSlice:slice2];
    
    
    LYMovieFilterStack *filterStack = [[LYMovieFilterStack alloc] initWithDemoImage:[UIImage imageNamed:@"filter_raw"]];
    make.filter = [filterStack filterAtIndex:0];
    self.make = make;
    [self.view.layer addSublayer:make.playerLayer];
    make.playerLayer.frame = self.view.bounds;
    [make play];
}
- (IBAction)pickB:(id)sender {
    [self.make pause];
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingString:@"demo.mp4"];
    [self.make exportMovieToPath:outputPath WithProgress:^(float progress) {
        NSLog(@"progress:%f",progress);
    } completion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
