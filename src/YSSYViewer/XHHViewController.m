//
//  XHHViewController.m
//  YSSYPhotoViewer
//
//  Created by Zhonghua Xi on 2/13/14.
//  Copyright (c) 2014 Zhonghua Xi. All rights reserved.
//

#import "XHHViewController.h"
#import "XHHBoardViewController.h"
#import "XHHImageInfo.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface XHHViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *imgView;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *btnSave;
@property (weak, nonatomic) IBOutlet UIButton *btnShare;

@property NSTimer *timer;
@property int currentImage;
@property BOOL isLoading;
@property BOOL inAnimation;
@property BOOL inSlideShow;
@property NSTimeInterval timeInterval;
@property BOOL isReverseOrder;
@property BOOL isFirstTime;


@end

@implementation XHHViewController

- (NSString *)appNameAndVersionNumberDisplayString {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];

    return [NSString stringWithFormat:@"%@, Version %@ (%@)",
            appDisplayName, majorVersion, minorVersion];
}

-(void)awakeFromNib {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString* storedVersion = [defaults objectForKey:@"version"];

    NSString* currentVersion = [self appNameAndVersionNumberDisplayString];


    NSLog(@"awake stored version = %@, current version = %@",storedVersion, currentVersion);


    self.isFirstTime = (storedVersion == nil) || ![currentVersion isEqualToString:storedVersion];
}

- (void) updateUISize {
    [self.progressView setFrame:self.view.bounds];
    [self.imgView setFrame:self.view.bounds];
    [self.imgView setCenter:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)];

    CGRect rectSave = self.btnSave.frame;
    CGRect rectShare = self.btnShare.frame;
    int diff = rectShare.origin.x - rectSave.origin.x;

    rectShare.origin.y = rectSave.origin.y = self.view.bounds.size.height - 60;
    rectSave.origin.x = self.view.bounds.size.width - 80;
    rectShare.origin.x = rectSave.origin.x + diff;

    [self.btnShare setFrame:rectShare];
    [self.btnSave setFrame:rectSave];
}



- (int) getBoundedImageIndex:(int)imageIndex {
    if(imageIndex >= (int)self.photos.count) return 0;
    if(imageIndex < 0) return (int)self.photos.count - 1;
    return imageIndex;
}

- (void) setImage : (UIImage*) image {
    self.inAnimation = TRUE;
    [UIView transitionWithView:self.imgView
                      duration:self.inSlideShow ? 1.0f : 0.30f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.imgView.image = image;

                        //[self se]
                    } completion:^(BOOL finished) {
                        if (finished) {
                            self.inAnimation = FALSE;
                        }
                    }];
}

- (void) showButtons {
    NSLog(@"show");
    self.btnSave.hidden = FALSE;
    self.btnShare.hidden = FALSE;
    [self updateUISize];
}

- (void) hideButtons {
    NSLog(@"hide");
    self.btnSave.hidden = TRUE;
    self.btnShare.hidden = TRUE;
}

- (void) updateProgressView {
    [self.progressView setHidden:TRUE];
    if(self.photos.count == 0) {
        return;
    }

    XHHImageInfo* ii = [self.photos objectAtIndex:self.currentImage];
    if(!ii.loadingStarted || ii.expectedSize <= 0 || ii.loaded) return;

    [self.progressView setHidden:FALSE];

    float progress = ii.expectedSize < 0 ? 0 : (float)ii.receivedSize / ii.expectedSize;

    [self.progressView setProgress:progress];
}

- (void) loadImage : (int)imageIndex {

    if(self.photos.count == 0) return;

    imageIndex = [self getBoundedImageIndex:imageIndex];

    XHHImageInfo* ii = [self.photos objectAtIndex:imageIndex];

    NSURL *imageURL = [NSURL URLWithString:ii.imageUrl];

    NSLog(@"Loading index = %d url = %@", imageIndex, imageURL);

    NSString *imgKey = [imageURL absoluteString];

    if(imageIndex == self.currentImage)
    {
        self.isLoading = true;
        [self setImage:nil];
        [self hideButtons];
    }

    [self updateProgressView];

    [[SDImageCache sharedImageCache] queryDiskCacheForKey:imgKey done:^(UIImage *image, SDImageCacheType cacheType) {
        if(image != nil) {

            ii.loaded = TRUE;

            if(imageIndex == self.currentImage)
            {
                [self setImage:image];
                self.isLoading = FALSE;
                [self.progressView setHidden:true];
                [self showButtons];
            }
            NSLog(@"Load image from cache for key = '%@'", imgKey);
        }
        else
        {
            NSLog(@"Can't get cache for key = '%@'", imgKey);

            ii.loadingStarted = TRUE;
            ii.loaded = FALSE;

            [SDWebImageDownloader.sharedDownloader downloadImageWithURL:imageURL
                                                                options:0
                                                               progress:^(NSUInteger receivedSize, long long expectedSize)
             {
                 // progression tracking code
                 //NSLog(@"%@ Loaded %d Expected %lld", imageURL, receivedSize, expectedSize);

                 ii.receivedSize = receivedSize;
                 ii.expectedSize = expectedSize;

                 [self updateProgressView];

                 if(imageIndex == self.currentImage) {
                     self.isLoading = true;
                 }

             }
                                                              completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
             {
                 if (image && finished)
                 {
                     // update view
                     if(imageIndex == self.currentImage) {
                         [self setImage:image];
                         [self showButtons];
                     }

                     ii.loaded = TRUE;

                     // cache the image
                     [[SDImageCache sharedImageCache] storeImage:image forKey:imgKey];
                     NSLog(@"Cache the image with key = '%@'", imgKey);


                 }

                 if(imageIndex == self.currentImage)
                 {
                     self.isLoading = false;
                     [self.progressView setHidden:TRUE];
                     [self.progressView setProgress:0.0];
                 }

             }];

            NSLog(@"Loading %@...", imageURL);
        }
    }];

}

- (void) nextImage {
    if(self.photos.count == 0) return;
    [self hideButtons];
    int nextImageIndex = [self getBoundedImageIndex:((int)self.currentImage+1)];
    XHHImageInfo* ii = [self.photos objectAtIndex:nextImageIndex];
    if(self.isLoading) {
        if(!ii.loaded) return;
    }
    self.isReverseOrder = FALSE;
    self.currentImage = nextImageIndex;
    [self loadImage:self.currentImage];
    [self loadImage:self.currentImage+1];
}

- (void) prevImage {
    if(self.photos.count == 0) return;
    [self hideButtons];
    int prevImageIndex = [self getBoundedImageIndex:((int)self.currentImage-1)];
    XHHImageInfo* ii = [self.photos objectAtIndex:prevImageIndex];
    if(self.isLoading) {
        if(!ii.loaded) return;
    }
    self.isReverseOrder = TRUE;
    self.currentImage = prevImageIndex;
    [self loadImage:self.currentImage];
    [self loadImage:self.currentImage-1];
}

- (void) handleTimer: (NSTimer *) timer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                  target: self
                                                selector: @selector(handleTimer:)
                                                userInfo: nil
                                                 repeats: FALSE];
    if(self.photos.count == 0) return;
    XHHImageInfo* ii = [self.photos objectAtIndex:self.currentImage];
    if(!ii.loaded) return;
    if (self.isReverseOrder) {
        [self prevImage];
    }else {
        [self nextImage];
    }
}

- (void) startSlideShow {
    if(self.inSlideShow) return;
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                  target: self
                                                selector: @selector(handleTimer:)
                                                userInfo: nil
                                                 repeats: FALSE];
    self.inSlideShow = TRUE;
    self.view.backgroundColor = [UIColor blackColor];
    [self hideButtons];

    NSLog(@"slideshow started!");
}

-(void) stopSlideShow {
    if(self.timer == nil) return;
    self.view.backgroundColor = [UIColor darkGrayColor];
    [self.timer invalidate];
    self.inSlideShow = FALSE;
    [self showButtons];
    NSLog(@"slideshow stopped!");
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {

    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self nextImage];
        [self stopSlideShow];
    }

    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self prevImage];
        [self stopSlideShow];
    }

    if(swipe.direction == UISwipeGestureRecognizerDirectionDown) {
        [self startSlideShow];
    }

    if(swipe.direction == UISwipeGestureRecognizerDirectionUp) {
        if(self.inSlideShow)
            [self stopSlideShow];
        else
            [self performSegueWithIdentifier:@"toBoardViewSegue" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //return back to BoardView, do nothing...
}

-(BOOL)isFirsTime
{
    return self.isFirstTime;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

   // self.isFirstTime = TRUE;

    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];

    [self updateUISize];

    NSLog(@"photo.count = %d", self.photos.count);

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeUP = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [swipeUP setDirection:UISwipeGestureRecognizerDirectionUp];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];

    // Adding the swipe gesture on image view
    [self.imgView addGestureRecognizer:swipeLeft];
    [self.imgView addGestureRecognizer:swipeRight];
    [self.imgView addGestureRecognizer:swipeUP];
    [self.imgView addGestureRecognizer:swipeDown];

    [self.navigationController.navigationBar setHidden:YES];
    
    CALayer *btnLayer = [self.btnSave layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    btnLayer = [self.btnShare layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];


}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateUISize];

    self.currentImage = -1;
    [self nextImage];

    if([self isFirstTime])
    {
        self.isFirstTime = FALSE;

        // Store the data
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [defaults setObject:[self appNameAndVersionNumberDisplayString] forKey:@"version"];
        [defaults synchronize];

        [self performSegueWithIdentifier:@"ToGuideSegue" sender:self];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateUISize];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopSlideShow];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"callbacked!");
    switch (buttonIndex) {
        case 0:
            [self updateUISize];
            break;
    }
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        // Do anything needed to handle the error or display it to the user
    } else {
        // .... do anything you want here to handle
        // .... when the image has been saved in the photo album
        NSLog(@"saved!");

        //Create UIAlertView alert
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"Saved" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        //After some time
        [alert dismissWithClickedButtonIndex:0 animated:TRUE];
        [alert show];
        [self updateUISize];
    }
}

- (IBAction)btnSaveTouchDown:(id)sender {
    NSLog(@"SAVE TOUCHED!");

    UIImageWriteToSavedPhotosAlbum(self.imgView.image, self, @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), nil);
}
- (IBAction)btnShareTouchDown:(id)sender {

    NSLog(@"SHARE TOUCHED!");

    XHHImageInfo* ii = [self.photos objectAtIndex:self.currentImage];

    NSString * encodedImageUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(nil,
                                           (CFStringRef)ii.imageUrl, nil,
                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));

    NSString* url = @"http://service.weibo.com/share/share.php?title=share%20image&pic=";

    url = [url stringByAppendingString:encodedImageUrl];
    url = [url stringByAppendingString:@"&url="];
    url = [url stringByAppendingString:encodedImageUrl];

    NSLog(@"url = %@", url);

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
}
@end
