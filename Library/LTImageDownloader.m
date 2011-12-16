//
//  LTImageDownloader.m
//  LTCoreText
//
//  Created by ito on H.23/08/02.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTImageDownloader.h"
#import "CGUtils.h"
#import "ASIHTTPRequest.h"

@interface LTImageDownloader()
{
	NSOperationQueue* _downloadQueue;
	NSCache* _imageCache;
	dispatch_queue_t _queue;
}

@end

@implementation LTImageDownloader

NSString* const LTImageDownloaderOptionBorderColor = @"border_color";
NSString* const LTImageDownloaderOptionBorderWidth = @"border_width";

+(id)sharedInstance
{
	static dispatch_once_t pred;
	static id sharedDownloader = nil;
	
	dispatch_once(&pred, ^{ sharedDownloader = [[self alloc] init]; });
	return sharedDownloader;
	
}

- (id)init
{
    self = [super init];
    if (self) {
		_queue = dispatch_queue_create("lt.coretext.imagedownloader", 0);
		_downloadQueue = [[NSOperationQueue alloc] init];
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
		
		//NSURLRequest* req = [NSURLRequest requestWithURL:url];
		ASIHTTPRequest* req = [ASIHTTPRequest requestWithURL:url];
		req.delegate = self;
		req.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:cacheKey, @"cacheKey",
						[NSValue valueWithCGSize:bounds], @"bounds", 
						comp, @"completion",
						options, @"options", nil];
		[_downloadQueue addOperation:req];
	});
}


- (void)requestFinished:(ASIHTTPRequest *)request
{
	dispatch_async(_queue, ^(void) {
		NSData *responseData = [request responseData];
		[_imageCache setObject:responseData forKey:[request.userInfo objectForKey:@"cacheKey"]];
		
		UIImage* srcImage = [UIImage imageWithData:responseData];
		UIImage* image = [self _resizeImage:srcImage bounds:[[request.userInfo objectForKey:@"bounds"] CGSizeValue] options:[request.userInfo objectForKey:@"options"]];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			LTImageDownloadCallback comp = [request.userInfo objectForKey:@"completion"];
			comp(image, nil);
		});
	});
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	LTImageDownloadCallback comp = [request.userInfo objectForKey:@"completion"];
	comp(nil, [request error]);
}


@end
