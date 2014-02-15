//
//  XHHImageInfo.h
//  YSSYViewer
//
//  Created by Zhonghua Xi on 2/15/14.
//  Copyright (c) 2014 Zhonghua Xi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XHHImageInfo : NSObject
@property NSString* imageUrl;
@property BOOL loadingStarted;
@property BOOL loaded;
@property int expectedSize;
@property int receivedSize;
@end
