//
//  LTImageDownloader.h
//  LTCoreText
//
//  Created by ito on H.23/08/02.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* const LTImageDownloaderOptionBorderColor;
NSString* const LTImageDownloaderOptionBorderWidth;


typedef void (^LTImageDownloadCallback)(UIImage* image, NSError* error);

@interface LTImageDownloader : NSObject

+(id)sharedInstance;
- (void)downloadImageWithURL:(NSURL*)url imageBounds:(CGSize)bounds options:(NSDictionary*)options completion:(LTImageDownloadCallback)comp;

@end
