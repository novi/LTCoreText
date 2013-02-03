//
//  LTTextImageView.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/04.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "LTTextImageView.h"
#import "LTImageDownloader.h"

const NSUInteger kLTTextImageViewOverlayViewTag = 0x10;

@implementation LTTextImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.userInteractionEnabled = YES;
        self.contentMode = UIViewContentModeScaleAspectFit;

#if LTTextViewBackgroundColorDebug  
        self.backgroundColor = [UIColor greenColor];
#endif
		
		UIView* overlayView = [[UIView alloc] initWithFrame:frame];
		overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		overlayView.tag = kLTTextImageViewOverlayViewTag;
		[self addSubview:overlayView];
		
		UITapGestureRecognizer* tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[overlayView addGestureRecognizer:tapgr];
		
    }
    return self;
}

- (void)setHighlightedOff
{
	UIView* overlayView = [self viewWithTag:kLTTextImageViewOverlayViewTag];
	overlayView.backgroundColor = [UIColor clearColor];
}

- (void)tapped:(UITapGestureRecognizer*)gr
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIView* overlayView = [self viewWithTag:kLTTextImageViewOverlayViewTag];
		overlayView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.5];
	});
	
	[self performSelector:@selector(setHighlightedOff) withObject:nil afterDelay:0.25];
	
	[[UIApplication sharedApplication] sendAction:@selector(lt_imageSelected:) to:nil from:self forEvent:nil];
}

-(UITapGestureRecognizer *)tapGesture
{
	UIView* overlayView = [self viewWithTag:kLTTextImageViewOverlayViewTag];
	return overlayView.gestureRecognizers.lastObject;
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	
	UIView* overlayView = [self viewWithTag:kLTTextImageViewOverlayViewTag];
	overlayView.frame = self.bounds;
}

- (void)dealloc
{
	LTTextMethodDebugLog();
}

-(void)startDownload
{
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [UIColor lightGrayColor], LTImageDownloaderOptionBorderColor,
                             [NSNumber numberWithFloat:1.0f], LTImageDownloaderOptionBorderWidth, nil];
    
    //LTDummyObject* dummyObject = [[[LTDummyObject alloc] init] autorelease];
    
    self.alpha = 0.0;
    self.image = nil;
    
    NSURL* currentURL = [self.imageURL copy];
    
    [[LTImageDownloader sharedInstance] downloadImageWithURL:currentURL
                                                 imageBounds:self.displaySize
                                                     options:options
                                                  completion:
     ^(UIImage *image, NSError *error) {
         //NSLog(@"image downloaded: req:%@, cur:%@", currentURL, self.imageURL);
         if ([self.imageURL isEqual:currentURL]) {
             if (image) {
                 self.image = image;
                 [UIView animateWithDuration:0.5
                                  animations:^{ 
                                      self.alpha = 1.0;
                                  }];
             } else {
                 // error
             }
         }
         
     }];
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
