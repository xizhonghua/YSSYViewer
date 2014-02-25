//
//  XHHGuideViewController.m
//  YSSYViewer
//
//  Created by Zhonghua Xi on 2/25/14.
//  Copyright (c) 2014 Zhonghua Xi. All rights reserved.
//

#import "XHHGuideViewController.h"

@interface XHHGuideViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgGuide;

@end

@implementation XHHGuideViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) updateUISize
{
    [self.imgGuide setFrame:self.view.bounds];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    if(swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionRight];

    // Adding the swipe gesture on image view
    [self.imgGuide addGestureRecognizer:swipeLeft];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateUISize];
}

@end
