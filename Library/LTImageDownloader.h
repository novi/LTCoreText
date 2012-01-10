//
//  LTImageDownloader.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/02.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import <Foundation/Foundation.h>

NSString* const LTImageDownloaderOptionBorderColor;
NSString* const LTImageDownloaderOptionBorderWidth;


typedef void (^LTImageDownloadCallback)(UIImage* image, NSError* error);

@interface LTImageDownloader : NSObject

+ (void)setOperationQueue:(NSOperationQueue*)queue;
+ (NSOperationQueue*)currentOperationQueue;

+(id)sharedInstance;
- (void)downloadImageWithURL:(NSURL*)url imageBounds:(CGSize)bounds options:(NSDictionary*)options completion:(LTImageDownloadCallback)comp;

@end
