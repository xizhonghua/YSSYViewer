//
//  XHHSettings.m
//  YSSYViewer
//
//  Created by Zhonghua Xi on 2/25/14.
//  Copyright (c) 2014 Zhonghua Xi. All rights reserved.
//

#import "XHHSettings.h"

@implementation XHHSettings

- (id) init {

    self = [super init];
    if (self) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
//            plistPath = [[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"];
//        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                              propertyListFromData:plistXML
                                              mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                              format:&format
                                              errorDescription:&errorDesc];
        if (!temp) {
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
        }
        self.isFirstTime = [temp objectForKey:@"IsFirstTime"];
    }
    return self;
}

-(void) save {

}

@end
