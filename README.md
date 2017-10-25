# LYMovieMake

## CocoaPods
pod 'LYMovieMake', '~> 0.0.3a'

## Demo codes for transition,filter,video join,
```
LYMovieMake *make = [[LYMovieMake alloc] init];

//a demo video
NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"mp4"];

// add two slice and transition between them
LYMovieSlice *slice = [[LYMovieSlice alloc] initWithURL:url];
LYMovieSlice *slice2 = [[LYMovieSlice alloc] initWithURL:url];
slice2.transitionFilter = [[LYMovieTransitionFilterStack sharedTransitionFilterStack] filterOfType:TransitionFilterTypeSwipe];
[make addSlice:slice];
[make addSlice:slice2];

// set the movie filter
LYMovieFilterStack *filterStack = [[LYMovieFilterStack alloc] initWithDemoImage:[UIImage imageNamed:@"filter_raw"]];
make.filter = [filterStack filterAtIndex:0];

// retain make
self.make = make;

// add preview
[self.view.layer addSublayer:make.playerLayer];
make.playerLayer.frame = self.view.bounds;

// start play movie
[make play];
```

## Demo Codes for export
```
// pause movie playing then export
[self.make pause];
NSString *outputPath = [NSTemporaryDirectory() stringByAppendingString:@"demo.mp4"];
[self.make exportMovieToPath:outputPath WithProgress:^(float progress) {
        NSLog(@"progress:%f",progress);
} completion:^(BOOL success, NSError *error) {
        
}];
```

## More function

refer to LYMovieMake and LYMovieSlice;
