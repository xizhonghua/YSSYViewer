//
//  XHHPhotoListViewController.m
//  YSSYPhotoViewer
//
//  Created by Zhonghua Xi on 2/14/14.
//  Copyright (c) 2014 Zhonghua Xi. All rights reserved.
//

#import "XHHPhotoListViewController.h"
#import "XHHViewController.h"
#import "XHHImageInfo.h"
#import <iAd/iAd.h>

@interface XHHPhotoListViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet ADBannerView *adBannerView;
@property NSMutableData* _responseData;
@property NSString* startId;
@property int pageFatched;
@end

@implementation XHHPhotoListViewController

-(void) updateUISize
{
    CGPoint center = CGPointMake(self.view.bounds.size.width / 2,self.view.bounds.size.height/ 2);

    [self.labelInfo setCenter:center];
    center.y -= 60;
    [self.activityView setCenter:center];
    center.y = self.view.bounds.size.height - self.adBannerView.frame.size.height/2;
    [self.adBannerView setFrame:self.view.bounds];
    [self.adBannerView setCenter:center];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUISize];


    self.pageFatched = 0;
    self.startId = nil;
    self.labelInfo.text = [@"Fetching image list of " stringByAppendingString:self.board];

    self.photos = [[NSMutableArray alloc] init];

    [self fetchImgList];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateUISize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateUISize];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateUISize];
}

-(void) fetchImgList
{
    NSString *pageURL = [@"https://bbs.sjtu.edu.cn/bbsfdoc2?board=" stringByAppendingString:self.board ];

    if(self.startId != nil) {
        pageURL = [NSString stringWithFormat:@"%@&start=%@", pageURL, self.startId];
    }

    // Create the request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:pageURL]];
    if(self.startId != nil) {
        [request  setCachePolicy:  NSURLRequestReturnCacheDataElseLoad];
    }

    // Create url connection and fire request
    [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"toImageViewSegue"]) {

      [self.photos sortUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
          return [obj2 compare:obj1
                  ];
      }];


      XHHViewController *vc = (XHHViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
    vc.photos = [[NSMutableArray alloc] init];
    for (NSString* photo in self.photos) {

        XHHImageInfo *ii = [[XHHImageInfo alloc] init];
        [ii setImageUrl:photo];
        [vc.photos addObject:ii];
    }
  }
}

-(void) onDownloaded:(NSString*)rawHTML {
    self.pageFatched ++;
    [self extractImages:rawHTML];
    [self extractPreviousStartId:rawHTML];
    self.labelInfo.text = [self.labelInfo.text stringByAppendingString: @"."];

    if(self.pageFatched < 5 && self.startId != nil) {
        [self fetchImgList];
    } else {
        [self performSegueWithIdentifier:@"toImageViewSegue" sender:self] ;
    }
}

-(void) extractImages:(NSString*)rawHTML
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<a href=(.*?(jpg|gif|png)) target)+?"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSArray *matches = [regex matchesInString:rawHTML
                                      options:0
                                        range:NSMakeRange(0, [rawHTML length])];

    NSLog(@"total matches %d",[matches count]);

    for (NSTextCheckingResult *match in matches) {
        NSString *img = [rawHTML substringWithRange:[match rangeAtIndex:2]] ;
       // NSLog(@"%@",img);
        // add image to the array
        [self.photos addObject:img];
    }
}

-(void) extractPreviousStartId:(NSString*)rawHTML
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"start=([^>]+)>上一页</a>"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSArray *matches = [regex matchesInString:rawHTML
                                      options:0
                                        range:NSMakeRange(0, [rawHTML length])];

    self.startId = nil;
    for (NSTextCheckingResult *match in matches) {
        self.startId  = [rawHTML substringWithRange:[match rangeAtIndex:1]];
    }
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self._responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self._responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    // Cache pages only with start parameter
    NSString* url = [connection.currentRequest.URL absoluteString];
    if ( [url rangeOfString:@"start="].location == NSNotFound)
        return nil;
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *rawHTML = [[NSString alloc]initWithData:self._responseData encoding:enc];
    [self onDownloaded:rawHTML];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

@end
