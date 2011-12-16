//
//  LTTextView.m
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTTextView.h"
#import "NSAttributedString+HTML.h"
#import "LTTextPageView.h"

@interface LTTextView()
{
	BOOL _framesizeChanged;
	NSMutableArray* _layouters;
	NSMutableArray* _loadedViews;
	NSUInteger _pageCount;
	struct {
		NSUInteger attrIndex;
		NSUInteger strIndex;
	} _currentState;
	NSUInteger _currentScrollIndex;
}

- (LTTextLayouter*)_layouterAtScrollIndex:(NSUInteger)index indexOnLayouter:(NSUInteger*)indexOn;
- (NSUInteger)_scrollIndexOfLayouter:(LTTextLayouter*)layouterA atPageIndex:(NSUInteger)index;
- (void)_recreateTextviews;

@end

@implementation LTTextView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_framesizeChanged = YES;
		
		self.autoresizingMask = UIViewAutoresizingNone;
		self.pagingEnabled = YES;
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = NO;
		self.delegate = self;
		
		//_attributedStrings = [[NSMutableArray alloc] init];
		_layouters = [[NSMutableArray alloc] init];
		_loadedViews = [[NSMutableArray alloc] init];
		
		_currentScrollIndex = NSUIntegerMax;
    }
    return self;
}

- (void)dealloc
{
    LTTextRelease(_layouters);
	LTTextRelease(_loadedViews);
    [super dealloc];
}

-(NSArray *)layouters
{
	return [NSArray arrayWithArray:_layouters];
}

- (void)_calculatePageCount
{
	NSUInteger count = 0;
	for (LTTextLayouter* layouter in _layouters) {
		count += layouter.pageCount;
	}
	_pageCount = count;
}

-(void)redrawPageIfNeeded
{
	[self _recreateTextviews];
}

-(void)scrollToStringIndex:(NSUInteger)strIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated
{
	if (layouterIndex+1 > [_layouters count]) {
		return;
	}
	
	LTTextLayouter* layouter = [_layouters objectAtIndex:layouterIndex];
	NSUInteger pageIndex = [layouter pageIndexAtStringIndex:strIndex];
	
	_currentScrollIndex = [self _scrollIndexOfLayouter:layouter atPageIndex:pageIndex];
	CGPoint p = CGPointMake(self.bounds.size.width*_currentScrollIndex, 0);
	
	[self setContentOffset:p animated:animated];
	
	//[self _recreateTextviews];
}

-(void)stringIndex:(NSUInteger *)strIndex layouterIndex:(NSUInteger *)layouterIndex
{
	NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self _layouterAtScrollIndex:_currentScrollIndex indexOnLayouter:&pageIndex];
	if (layouterIndex) {
		*layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
	}
	
	if (strIndex) {
		*strIndex = [layouter rangeOfStringAtPageIndex:pageIndex].location;
	}
}

- (NSUInteger)_scrollIndexOfLayouter:(LTTextLayouter*)layouterA atPageIndex:(NSUInteger)index
{
	NSUInteger count = 0;
	BOOL found = NO;
	LTTextLayouter* hitLayouter = nil;
	for (LTTextLayouter* layouter in _layouters) {
		if (layouterA == layouter) {
			found = YES;
			hitLayouter = layouter;
			break;
		}
		count += layouter.pageCount;
	}
	
	if ( ! found) {
		return 0;
	}
	if (index < hitLayouter.pageCount) {
		return count+index;
	}
	
	return count+hitLayouter.pageCount-1;
}

/*
- (LTTextLayouter*)_createNewLayouterWithAttributedString:(NSAttributedString*)attrString size:(CGSize)size
{
	LTTextLayouter* layouter = [[LTTextLayouter alloc] initWithAttributedString:attrString frameSize:size];
	layouter.contentInset = UIEdgeInsetsMake(50, 30, 20, 50);
	layouter.columnSpace = 32;
	layouter.columnCount = 2;
	return layouter;
}
*/

- (LTTextLayouter*)_layouterAtScrollIndex:(NSUInteger)index indexOnLayouter:(NSUInteger*)indexOn
{
	if (index+1 > _pageCount) {
		return nil;
	}
	
	NSUInteger count = 0;
	for (LTTextLayouter* layouter in _layouters) {
		count += layouter.pageCount;
		if (count > index) {
			if (indexOn) {
				*indexOn = index - (count-layouter.pageCount);
			}
			return layouter;
		}
	}
	
	return nil;
}

- (NSMutableArray*)_loadedViewsArrayCount:(NSUInteger)count
{
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
	for (NSUInteger i = 0; i < count; i++) {
		[array addObject:[NSNull null]];
	}
	
	return array;
}

-(void)insertLayouter:(LTTextLayouter *)layouter atIndex:(NSUInteger)index
{
	if (index > [_layouters count]) {
		index = [_layouters count];
	}
	
	// Get current layouter and page index
	NSUInteger pageIndex = 0;
	LTTextLayouter* curLayouter = [self _layouterAtScrollIndex:_currentScrollIndex indexOnLayouter:&pageIndex];
	
	// Add attributed string and create layouter
	[_layouters insertObject:layouter atIndex:index];
	[_loadedViews insertObject:[self _loadedViewsArrayCount:layouter.pageCount] atIndex:index];
	
	[self _calculatePageCount];
	
	
	CGRect bounds = self.bounds;
	self.contentSize = CGSizeMake(bounds.size.width*_pageCount, bounds.size.height);
	
	[self _recreateTextviews];
	
	self.contentOffset = CGPointMake(bounds.size.width*[self _scrollIndexOfLayouter:curLayouter atPageIndex:pageIndex], 0);
	self.scrollEnabled = YES;
}

-(void)removeLayouterAtIndex:(NSUInteger)index
{
	if (index+1 > [_layouters count]) {
		return;
	}
	
	// Get current layouter and page index
	NSUInteger pageIndex = 0;
	LTTextLayouter* curLayouter = [self _layouterAtScrollIndex:_currentScrollIndex indexOnLayouter:&pageIndex];
	
	// Remove string and layouter
	[_layouters removeObjectAtIndex:index];
	[_loadedViews removeObjectAtIndex:index];
	
	[self _calculatePageCount];
	
	CGRect bounds = self.bounds;
	self.contentSize = CGSizeMake(bounds.size.width*_pageCount, bounds.size.height);
	
	[self _recreateTextviews];
	
	self.contentOffset = CGPointMake(bounds.size.width*[self _scrollIndexOfLayouter:curLayouter atPageIndex:pageIndex], 0);
	self.scrollEnabled = YES;
}

- (NSUInteger)_currentScrollIndex
{
	CGFloat pageWidth = self.bounds.size.width;
	NSInteger pageIndex = 0;
	pageIndex = floorf(self.contentOffset.x/pageWidth);
	
	return pageIndex;
}

- (CGRect)_frameWithScrollIndex:(NSUInteger)index
{
	if (index < _pageCount) {
		CGRect bounds = self.bounds;
		CGRect frame = CGRectMake(bounds.size.width*index, 0, bounds.size.width, bounds.size.height);
		//frame = UIEdgeInsetsInsetRect(frame, _contentInset);
		return frame;
	}
	return CGRectZero;
}

- (UIView*)_hasViewWithScrollIndex:(NSUInteger)scrollIndex
{
	CGRect frame = [self _frameWithScrollIndex:scrollIndex];
	if (CGRectEqualToRect(frame, CGRectZero)) {
		return nil;
	}
	
	NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self _layouterAtScrollIndex:scrollIndex indexOnLayouter:&pageIndex];
	NSUInteger layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
	
	/*for (LTTextPageView* pageview  in self.subviews) {
		if ([pageview isKindOfClass:[LTTextPageView class]]) {
			if (layouter == pageview.layouter && pageIndex == pageview.index) {
				return pageview;
			}
		}
	}*/
	id obj = [[_loadedViews objectAtIndex:layouterIndex] objectAtIndex:pageIndex];
	if ([obj isKindOfClass:[NSNull class]]) {
		return nil;
	}
	((UIView*)obj).frame = frame;
	return obj;
}

- (UIView*)_viewWithScrollIndex:(NSUInteger)scrollIndex
{
	CGRect frame = [self _frameWithScrollIndex:scrollIndex];
	if (CGRectEqualToRect(frame, CGRectZero)) {
		return nil;
	}
	
	NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self _layouterAtScrollIndex:scrollIndex indexOnLayouter:&pageIndex];
	LTTextPageView* pageView = [[[LTTextPageView alloc] initWithFrame:frame layouter:layouter pageIndex:pageIndex] autorelease];
	NSUInteger layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
	
	NSMutableArray* loadedViews = [_loadedViews objectAtIndex:layouterIndex];
	[loadedViews replaceObjectAtIndex:pageIndex withObject:pageView];
	
	LTTextLogInfo(@"created view layouter:%d, page:%d, scroll:%d", layouterIndex, pageIndex, [self _scrollIndexOfLayouter:layouter atPageIndex:pageIndex]);
	
	return pageView;
}

- (void)_framesizeChanged
{
	_framesizeChanged = NO;

	
	for (UIView* view in self.subviews) {
		if ([view isKindOfClass:[LTTextPageView class]]) {
			[view removeFromSuperview];
		}
	}
	
	[self _calculatePageCount];
	
	CGRect bounds = self.bounds;
	self.contentSize = CGSizeMake(bounds.size.width*_pageCount, bounds.size.height);
	
	//self.contentOffset = CGPointMake(bounds.size.width*[self _scrollIndexOfLayouter:_currentPageState._layouter atPageIndex:_currentPageState._pageIndex], 0);
	
	//[self setContentOffset:CGPointMake(self.bounds.size.width*_currentPageIndex, 0) animated:NO];
	//[self scrollToStringIndex:_currentState.strIndex onAttributedStringAtIndex:_currentState.attrIndex animated:YES];
	[self scrollToStringIndex:_currentState.strIndex onLayouterAtIndex:_currentState.attrIndex animated:NO];
}

-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	_framesizeChanged = YES;
}
-(void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	//_framesizeChanged = YES;
}

- (void)_recreateTextviews
{
	if (self.hidden || self.alpha == 0.0) {
		NSLog(@"TextView: %@ is not appears.", self);
		return;
	}
	
	LTTextLogInfo(@"current scroll index: %d", _currentScrollIndex);
	
	NSMutableArray* viewsToUse = [NSMutableArray array];
	for (int i = 0; i < 3; i++) {
		NSUInteger index = (_currentScrollIndex+i-1);
		if (index < _pageCount) {
			UIView* pageview = [self _hasViewWithScrollIndex:index];
			if ( ! pageview) {
				// Create new view
				pageview = [self _viewWithScrollIndex:index];
//				[self addSubview:pageview];
			} else {
				[pageview removeFromSuperview];
			}
			[viewsToUse addObject:pageview];
		} else {
			LTTextLogInfo(@"invalid index %u", index);
		}
	}
	
	NSMutableArray* scrollIndexToUse = [NSMutableArray arrayWithCapacity:7];
	for (int i = 0; i < 7; i++) {
		NSUInteger index = (_currentScrollIndex+i-((7-1)/2));
		if (index < _pageCount) {
			[scrollIndexToUse addObject:[NSNumber numberWithUnsignedInteger:index]];
		}
	}
	NSLog(@"%@", scrollIndexToUse);
	
	// Remove loaded view if not needed
	for (NSUInteger i = 0; i < _loadedViews.count; i++) {
		NSMutableArray* views = [_loadedViews objectAtIndex:i];
		for (NSUInteger pagei = 0; pagei < [views count]; pagei++) {
			UIView* pageview = [views objectAtIndex:pagei];
			if ([pageview isKindOfClass:[UIView class]]) {
				NSUInteger scrollIndex = [self _scrollIndexOfLayouter:[_layouters objectAtIndex:i] atPageIndex:pagei];
				//NSNumber* scrollIndexnum = [NSNumber numberWithUnsignedInteger:scrollIndex];
				BOOL notfound = YES;
				for (NSNumber* num in scrollIndexToUse) {
					if (scrollIndex == [num unsignedIntegerValue]) {
						notfound = NO;
						break;
					}
				}
				if (notfound) {
					// Remove view
					[views replaceObjectAtIndex:pagei withObject:[NSNull null]];
				}
			}
		}
	}

	
	for (UIView* view in self.subviews) {
		if ([view isKindOfClass:[LTTextPageView class]]) {
			BOOL toUse = NO;
			for (UIView* toUseView in viewsToUse) {
				if (toUseView == view) {
					toUse = YES;
				}
			}
			
			if ( ! toUse) {
				[view removeFromSuperview];
			}
		}
	}
	
	for (UIView* view in viewsToUse) {
		[self addSubview:view];
	}
	
	//LTTextLogInfo(@"%@", self.subviews);
}


-(void)layoutSubviews
{
	[super layoutSubviews];
	
	BOOL framesizeChanged = _framesizeChanged;
	if (_framesizeChanged) {
		[self _framesizeChanged];
	}
	
	if ([self _currentScrollIndex] != _currentScrollIndex || framesizeChanged) {
		_currentScrollIndex = [self _currentScrollIndex];

		[self stringIndex:&_currentState.strIndex layouterIndex:&_currentState.attrIndex];
		
		LTTextLogInfo(@"attr:%u, str:%u", _currentState.attrIndex, _currentState.strIndex);
		
		[self _recreateTextviews];
		LTTextPageView* pageView = (id)[self _hasViewWithScrollIndex:_currentScrollIndex];
		[pageView showAttachmentsIfNeeded];
	}
	
	
}

#pragma mark - Scroll View Delegate

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	//_currentPageIndex = [self _currentIndex];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	//LTTextPageView* pageView = (id)[self _hasViewWithScrollIndex:[self _currentScrollIndex]];
	//[pageView showAttachmentsIfNeeded];
}

@end
