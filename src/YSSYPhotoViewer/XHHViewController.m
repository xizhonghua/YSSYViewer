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

@property NSTimer *timer;
@property int currentImage;
@property BOOL isLoading;
@property BOOL inAnimation;
//@property NSMutableArray *imageLoaded;

@end

@implementation XHHViewController

- (void) updateUISize {
    NSLog(@"XHHViewController bounds = %@", NSStringFromCGRect(self.view.bounds));
    [self.progressView setFrame:self.view.bounds];
    NSLog(@"XHHViewController progressView.frame = %@", NSStringFromCGRect(self.progressView.frame));
   // self.progressView.frame.size.width = self.view.bounds.size.width;
    [self.imgView setFrame:self.view.bounds];
    [self.imgView setCenter:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)];
    NSLog(@"XHHViewController imgView.frame = %@", NSStringFromCGRect(self.imgView.frame));
}



- (int) getBoundedImageIndex:(int)imageIndex {
    if(imageIndex >= (int)self.photos.count) return 0;
    if(imageIndex < 0) return (int)self.photos.count - 1;
    return imageIndex;
}

- (void) setImage : (UIImage*) image {
    self.inAnimation = TRUE;
    [UIView transitionWithView:self.imgView
                      duration:0.30f
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
            }
            NSLog(@"Load image from cache for key %@", imgKey);
        }
        else
        {
            NSLog(@"Can't get cache for key %@", imgKey);

            ii.loadingStarted = TRUE;
            ii.loaded = FALSE;

            [SDWebImageDownloader.sharedDownloader downloadImageWithURL:imageURL
                                                                options:0
                                                               progress:^(NSUInteger receivedSize, long long expectedSize)
             {
                 // progression tracking code
                 NSLog(@"%@ Loaded %d Expected %lld", imageURL, receivedSize, expectedSize);

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
                     if(imageIndex == self.currentImage)
                         [self setImage:image];

                     ii.loaded = TRUE;

                     // cache the image
                     [[SDImageCache sharedImageCache] storeImage:image forKey:imgKey];
                     NSLog(@"Cache the image with key %@", imgKey);


                 }

                 if(imageIndex == self.currentImage)
                 {
                     self.isLoading = false;
                     [self.progressView setHidden:TRUE];
                     [self.progressView setProgress:0.0];
                 }

             }];

            NSLog(@"Loading %@", imageURL);
        }
    }];

}

- (void) nextImage {
    if(self.photos.count == 0) return;
    int nextImageIndex = [self getBoundedImageIndex:((int)self.currentImage+1)];
    XHHImageInfo* ii = [self.photos objectAtIndex:nextImageIndex];
    if(self.isLoading) {
        if(!ii.loaded) return;
    }
    self.currentImage = nextImageIndex;
    [self loadImage:self.currentImage];
    [self loadImage:self.currentImage+1];
}

- (void) prevImage {
    if(self.photos.count == 0) return;
    int prevImageIndex = [self getBoundedImageIndex:((int)self.currentImage-1)];
    XHHImageInfo* ii = [self.photos objectAtIndex:prevImageIndex];
    if(self.isLoading) {
        if(!ii.loaded) return;
    }
    self.currentImage = prevImageIndex;
    [self loadImage:self.currentImage];
    [self loadImage:self.currentImage-1];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {

    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self nextImage];
    }

    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        //        NSLog(@"Right Swipe");
        //        [self performSegueWithIdentifier:@"toBoardViewSegue" sender:self];
        [self prevImage];
    }

    if(swipe.direction == UISwipeGestureRecognizerDirectionUp) {
        [self performSegueWithIdentifier:@"toBoardViewSegue" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //    XHHBoardViewController *vc = (XHHBoardViewController*)segue.destinationViewController;
    //    vc.photos = [[NSMutableArray alloc] init];
    //    for (NSString* photo in self.photos) {
    //        [vc.photos addObject:photo];
    //    }
    // [self.timer invalidate];
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];

    [self updateUISize];

    NSLog(@"photo.count = %d", self.photos.count);

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeUP = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [swipeUP setDirection:UISwipeGestureRecognizerDirectionUp];

    // Adding the swipe gesture on image view
    [self.imgView addGestureRecognizer:swipeLeft];
    [self.imgView addGestureRecognizer:swipeRight];
    [self.imgView addGestureRecognizer:swipeUP];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateUISize];

    self.currentImage = -1;
    [self nextImage];

    //[self loadImages];



    //    self.timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
    //                                                  target: self
    //                                                selector: @selector(handleTimer:)
    //                                                userInfo: nil
    //                                                 repeats: YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateUISize];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



- (BOOL)prefersStatusBarHidden {
    return YES;
}
@end
