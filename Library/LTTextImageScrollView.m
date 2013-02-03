//
//  LTTextImageScrollView.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/04.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "LTTextImageScrollView.h"

@interface LTTextImageScrollView()

//- (void)_centeringImage;
@property (nonatomic) UIImageView* imageView;

@end

@implementation LTTextImageScrollView

@synthesize imageView;

-(id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame image:nil];
}

- (id)initWithFrame:(CGRect)frame image:(UIImage*)aImage
{
    self = [super initWithFrame:frame];
    if (self) {
		self.contentSize = aImage.size;
		self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.8];
		self.delegate = self;
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 2.0;
		self.alwaysBounceHorizontal = YES;
		self.alwaysBounceVertical = YES;
		self.scrollEnabled = YES;
		self.bouncesZoom = YES;
		self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		
		
		UIImageView* aImageView = [[UIImageView alloc] initWithImage:aImage];
		aImageView.userInteractionEnabled = YES;
		aImageView.contentMode = UIViewContentModeCenter;
		aImageView.frame = self.bounds;
//		[aImageView sizeToFit];
		[self addSubview:aImageView];
		self.imageView = aImageView;
		
		UITapGestureRecognizer* tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[self addGestureRecognizer:tapgr];
        
        UITapGestureRecognizer* doubleTapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
        doubleTapgr.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapgr];
		
		//[self _centeringImage];
    }
    return self;
}

- (void)tapped:(UITapGestureRecognizer*)tapgr
{
	[[UIApplication sharedApplication] sendAction:@selector(lt_zoomedImageViewClose:) to:nil from:self forEvent:nil];
}

- (void)doubleTapped:(UITapGestureRecognizer*)tapgr
{
    if (self.zoomScale != 1.0) {
        [self setZoomScale:1.0 animated:YES];
    } else {
        [self setZoomScale:2.0 animated:YES];
    }
}

- (void)dealloc
{
	LTTextMethodDebugLog();
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	
	if (self.zooming) {
		//[self _centeringImage];
	}
}

#pragma mark - Scroll View Delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	//[self _centeringImage];
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	//[self _centeringImage];
}
/*
- (void)_centeringImage
{
	// http://stackoverflow.com/questions/638299/uiscrollview-with-centered-uiimageview-like-photos-app
	//UIImageView* imageView = self.imageView;
	CGRect innerFrame = self.imageView.frame;
	CGRect scrollerBounds = self.bounds;
	
	if ( ( innerFrame.size.width < scrollerBounds.size.width ) || ( innerFrame.size.height < scrollerBounds.size.height ) )
	{
		CGFloat tempx = self.imageView.center.x - ( scrollerBounds.size.width / 2 );
		CGFloat tempy = self.imageView.center.y - ( scrollerBounds.size.height / 2 );
		CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
		
		self.contentOffset = myScrollViewOffset;
		
	}
	
	UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
	if ( scrollerBounds.size.width > innerFrame.size.width )
	{
		anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
		anEdgeInset.right = -anEdgeInset.left;  // I don't know why this needs to be negative, but that's what works
	}
	if ( scrollerBounds.size.height > innerFrame.size.height )
	{
		anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
		anEdgeInset.bottom = -anEdgeInset.top;  // I don't know why this needs to be negative, but that's what works
	}
	self.contentInset = anEdgeInset;
}
*/

@end
