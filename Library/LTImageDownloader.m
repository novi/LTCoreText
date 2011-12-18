//
//  LTImageDownloader.m
//  LTCoreText
//
//  Created by ito on H.23/08/02.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTImageDownloader.h"
#import "CGUtils.h"


@interface LTImageDownloader()
{
	NSOperationQueue* _downloadQueue;
	NSCache* _imageCache;
	dispatch_queue_t _queue;
}

@property (nonatomic, retain) NSOperationQueue* downloadQueue;

@end

@implementation LTImageDownloader

@synthesize downloadQueue = _downloadQueue;

NSString* const LTImageDownloaderOptionBorderColor = @"border_color";
NSString* const LTImageDownloaderOptionBorderWidth = @"border_width";


+(id)sharedInstance
{
	static dispatch_once_t pred;
	static id sharedDownloader = nil;
	
	dispatch_once(&pred, ^{ sharedDownloader = [[self alloc] init]; });
	return sharedDownloader;
	
}

+(void)setOperationQueue:(NSOperationQueue *)queue
{
    if (queue) {
        LTImageDownloader* li = [self sharedInstance];
        li.downloadQueue = queue;
    }
}

+(NSOperationQueue *)currentOperationQueue
{
    LTImageDownloader* li = [self sharedInstance];
    return li.downloadQueue;
}

- (id)init
{
    self = [super init];
    if (self) {
		_queue = dispatch_queue_create("lt.coretext.imagedownloader", 0);
		self.downloadQueue = [[[NSOperationQueue alloc] init] autorelease];
		_downloadQueue.maxConcurrentOperationCount = 3;
		_imageCache = [[NSCache alloc] init];
    }
    
    return self;
}

- (UIImage*)_resizeImage:(UIImage*)image bounds:(CGSize)bounds options:(NSDictionary*)options
{
	if (CGSizeEqualToSize(bounds, CGSizeZero)) {
		return image;
	}
	
	CGSize targetSize;
	if (bounds.width > 0) {
		targetSize = sizeThatFitsKeepingAspectRatio(image.size, CGSizeMake(bounds.width, bounds.width));
	} else {
		targetSize = sizeThatFitsKeepingAspectRatio(image.size, CGSizeMake(bounds.height, bounds.height));
	}
	
	CGFloat borderWidth = 0;
	if ([options objectForKey:LTImageDownloaderOptionBorderWidth]) {
		borderWidth = ceilf([[options objectForKey:LTImageDownloaderOptionBorderWidth] floatValue]);
	}
	if (borderWidth >= 1.0) {
		// Use border
		targetSize.height += borderWidth*2;
		targetSize.width += borderWidth*2;
	}
	
	UIGraphicsBeginImageContext(targetSize);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetRGBFillColor(context, 0, 0, 0, 0);
	CGContextFillRect(context, CGRectMake(0, 0, targetSize.width, targetSize.height));
	
	if ([options objectForKey:LTImageDownloaderOptionBorderColor]) {
		CGContextSetStrokeColorWithColor(context, [[options objectForKey:LTImageDownloaderOptionBorderColor] CGColor]);
	} else {
		CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
	}
	CGContextStrokeRectWithWidth(context, CGRectInset(CGRectMake(0, 0, targetSize.width, targetSize.height), 
													  0.5, 0.5), borderWidth);
	
	[image drawInRect:CGRectMake(borderWidth, borderWidth, targetSize.width-borderWidth*2.0, targetSize.height-borderWidth*2.0)];
	
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return newImage;
}

-(void)downloadImageWithURL:(NSURL *)url imageBounds:(CGSize)bounds options:(NSDictionary *)options completion:(LTImageDownloadCallback)comp
{
	NSLog(@"%s, %@", __func__, [url absoluteString]);
	
	dispatch_async(_queue, ^(void) {
		NSString* cacheKey = [NSString stringWithFormat:@"%@", [url absoluteString]];
		NSData* data = [_imageCache objectForKey:cacheKey];
		if (data) {
			UIImage* srcImage = [UIImage imageWithData:data];
			UIImage* image = [self _resizeImage:srcImage bounds:bounds options:options];
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				comp(image, nil);
			});
			return;
		}
		
        
        NSURLRequest* req = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:req
                                           queue:_downloadQueue
                               completionHandler:^(NSURLResponse * res, NSData * data, NSError * error) {
                                   if (data.length && !error) {
                                       dispatch_async(_queue, ^(void) {
                                           [_imageCache setObject:data forKey:cacheKey];
                                           
                                           UIImage* srcImage = [UIImage imageWithData:data];
                                           UIImage* image = [self _resizeImage:srcImage bounds:bounds options:options];
                                           dispatch_async(dispatch_get_main_queue(), ^(void) {
                                               comp(image, nil);
                                           });
                                       });
                                   } else {
                                       // Request failed
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           comp(nil, error); 
                                       });
                                   }
                               }];
	});
}


@end
