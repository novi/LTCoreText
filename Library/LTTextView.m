//
//  LTTextView.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/07/07.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import "LTTextView.h"
#import "LTTextPageView.h"

@interface LTTextView()
{
    LTTextViewLayoutMode _layoutMode;
    BOOL _layoutModeChanged;
	BOOL _framesizeChanged;
	NSMutableArray* _layouters;
	NSMutableArray* _loadedViews;
	NSUInteger _pageCount;
	struct {
		NSUInteger attrIndex;
		NSUInteger strIndex;
	} _currentState;
	NSUInteger _currentScrollIndex;
    NSUInteger _scrollIndexChanged;
}

- (NSMutableArray*)_loadedViewsArrayCount:(NSUInteger)count;
- (CGPoint)_contentOffsetForIndex:(NSUInteger)index;
- (CGSize)_contentSizeForCurrentLayoutMode;
- (LTTextLayouter*)layouterAtScrollIndex:(NSUInteger)index pageIndexOnLayouter:(NSUInteger*)indexOn;
- (NSUInteger)_scrollIndexOfLayouter:(LTTextLayouter*)layouterA atPageIndex:(NSUInteger)index;
- (void)_recreateTextviews;

@end

@implementation LTTextView

@synthesize textViewDelegate;
@synthesize layoutMode = _layoutMode;
@synthesize allPageCount = _pageCount;
@synthesize scrollIndex = _currentScrollIndex;


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
        self.scrollsToTop = NO;
		
		_layouters = [[NSMutableArray alloc] init];
		_loadedViews = [[NSMutableArray alloc] init];
		
		_currentScrollIndex = NSUIntegerMax;
        _layoutMode = LTTextViewLayoutModeNormal;
    }
    return self;
}

- (void)dealloc
{
    LTTextRelease(_layouters);
	LTTextRelease(_loadedViews);
    [super dealloc];
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

#pragma mark - Accessory Method

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

-(NSArray *)layouters
{
	return [NSArray arrayWithArray:_layouters];
}

-(void)setLayoutMode:(LTTextViewLayoutMode)layoutMode
{
    if (_layoutMode == layoutMode) {
        return;
    }
    if (layoutMode == LTTextViewLayoutModeNormal ||
        layoutMode == LTTextViewLayoutModeReverse ||
        layoutMode == LTTextViewLayoutModeVertical) {
        _layoutMode = layoutMode;
    } else {
        _layoutMode = LTTextViewLayoutModeNormal;
    }
    
    NSLog(@"%s: current scroll index: %d", __func__, _currentScrollIndex);
    
    _layoutModeChanged = YES;
    
    _framesizeChanged = YES;
    [self setNeedsLayout];
}


#pragma mark - Scroll and String index

-(void)scrollToScrollIndex:(NSUInteger)pageIndex animated:(BOOL)animated
{
    if (pageIndex+1 > _pageCount) {
        pageIndex = _pageCount-1;
    }
    
    _currentScrollIndex = pageIndex;
    [self setContentOffset:[self _contentOffsetForIndex:_currentScrollIndex] animated:animated];
    
    [self _recreateTextviews];
}

-(void)scrollToLayouterPageIndex:(NSUInteger)pageIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated
{
    if (layouterIndex+1 > [_layouters count]) {
		return;
	}
    
    NSUInteger scrollIndex = [self _scrollIndexOfLayouter:[_layouters objectAtIndex:layouterIndex]
                                              atPageIndex:pageIndex];
	
    [self scrollToScrollIndex:scrollIndex animated:animated];
}

-(void)scrollToStringIndex:(NSUInteger)strIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated
{
	if (layouterIndex+1 > [_layouters count]) {
		return;
	}
	
	LTTextLayouter* layouter = [_layouters objectAtIndex:layouterIndex];
	NSUInteger pageIndex = 0;
    if (strIndex != 0) {
        pageIndex = [layouter pageIndexOfStringIndex:strIndex columnIndex:NULL];
    }
	
	[self scrollToLayouterPageIndex:pageIndex onLayouterAtIndex:layouterIndex animated:animated];
}

-(void)stringIndex:(NSUInteger *)strIndex layouterIndex:(NSUInteger *)layouterIndex
{
	NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self layouterAtScrollIndex:_currentScrollIndex pageIndexOnLayouter:&pageIndex];
	if (layouterIndex) {
		*layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
	}
	
	if (strIndex) {
		*strIndex = [layouter rangeOfStringAtPageIndex:pageIndex column:0].location;
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

- (LTTextLayouter*)layouterAtScrollIndex:(NSUInteger)index pageIndexOnLayouter:(NSUInteger*)indexOn
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

#pragma mark - Layouter

-(void)insertLayouter:(LTTextLayouter *)layouter atIndex:(NSUInteger)index
{
	if (index > [_layouters count]) {
		index = [_layouters count];
	}
	
	// Get current layouter and page index
	NSUInteger pageIndex = 0;
	LTTextLayouter* curLayouter = [self layouterAtScrollIndex:_currentScrollIndex pageIndexOnLayouter:&pageIndex];
	
	// Add attributed string and create layouter
	[_layouters insertObject:layouter atIndex:index];
	[_loadedViews insertObject:[self _loadedViewsArrayCount:layouter.pageCount] atIndex:index];
	
	[self _calculatePageCount];
	
	
	self.contentSize = [self _contentSizeForCurrentLayoutMode];
	
	[self _recreateTextviews];
	
	self.contentOffset = [self _contentOffsetForIndex:[self _scrollIndexOfLayouter:curLayouter atPageIndex:pageIndex]];
	self.scrollEnabled = YES;
}

-(void)removeLayouterAtIndex:(NSUInteger)index
{
	if (index+1 > [_layouters count]) {
		return;
	}
	
	// Get current layouter and page index
	NSUInteger pageIndex = 0;
	LTTextLayouter* curLayouter = [self layouterAtScrollIndex:_currentScrollIndex pageIndexOnLayouter:&pageIndex];
	
	// Remove string and layouter
	[_layouters removeObjectAtIndex:index];
	[_loadedViews removeObjectAtIndex:index];
	
	[self _calculatePageCount];
	
	self.contentSize = [self _contentSizeForCurrentLayoutMode];
	
	[self _recreateTextviews];
	
	self.contentOffset = [self _contentOffsetForIndex:[self _scrollIndexOfLayouter:curLayouter atPageIndex:pageIndex]];
	self.scrollEnabled = YES;
}

#pragma mark - Content frames

- (CGSize)_contentSizeForCurrentLayoutMode
{
    CGRect bounds = self.bounds;
    
    if (_layoutMode == LTTextViewLayoutModeNormal) {
        return CGSizeMake(bounds.size.width*_pageCount, bounds.size.height);
    } else if (_layoutMode == LTTextViewLayoutModeReverse) {
        return CGSizeMake(bounds.size.width*_pageCount, bounds.size.height);
    } else if (_layoutMode == LTTextViewLayoutModeVertical) {
        return CGSizeMake(bounds.size.width, bounds.size.height*_pageCount);
    }
    return CGSizeZero;
}

- (CGPoint)_contentOffsetForIndex:(NSUInteger)index
{
    CGRect bounds = self.bounds;
    
    if (_layoutMode == LTTextViewLayoutModeNormal) {
        return CGPointMake(bounds.size.width*index, 0);
    } else if (_layoutMode == LTTextViewLayoutModeReverse) {
        return CGPointMake(bounds.size.width*(_pageCount-index-1), 0);
    } else if (_layoutMode == LTTextViewLayoutModeVertical) {
        return CGPointMake(0, bounds.size.height*index);
    }
    
    return CGPointZero;
}

- (NSUInteger)_currentScrollIndex
{
	CGFloat pageWidth = self.bounds.size.width;
    CGFloat pageHeight = self.bounds.size.height;
    
	NSInteger pageIndex = 0;
	if (_layoutMode == LTTextViewLayoutModeNormal) {
        pageIndex = floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    } else if (_layoutMode == LTTextViewLayoutModeReverse) {
        pageIndex = floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        pageIndex = _pageCount - 1 - pageIndex;
    } else if (_layoutMode == LTTextViewLayoutModeVertical) {
        pageIndex = floor((self.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
    }
	
	return pageIndex;
}

- (CGRect)_frameWithScrollIndex:(NSUInteger)index
{
	if (index < _pageCount) {
		CGRect bounds = self.bounds;
		CGRect frame; 
        if (_layoutMode == LTTextViewLayoutModeNormal) {
            frame = CGRectMake(bounds.size.width*index, 0, bounds.size.width, bounds.size.height);
        } else if (_layoutMode == LTTextViewLayoutModeReverse) {
            frame = CGRectMake(bounds.size.width*(_pageCount-index-1), 0, bounds.size.width, bounds.size.height);
        } else if (_layoutMode == LTTextViewLayoutModeVertical) {
            frame = CGRectMake(0, bounds.size.height*index, bounds.size.width, bounds.size.height);
        }
		//frame = UIEdgeInsetsInsetRect(frame, _contentInset);
		return frame;
	}
	return CGRectZero;
}

#pragma mark - Page Views

- (UIView*)_hasViewWithScrollIndex:(NSUInteger)scrollIndex
{
	CGRect frame = [self _frameWithScrollIndex:scrollIndex];
	if (CGRectEqualToRect(frame, CGRectZero)) {
		return nil;
	}
	
	NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self layouterAtScrollIndex:scrollIndex pageIndexOnLayouter:&pageIndex];
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
	LTTextLayouter* layouter = [self layouterAtScrollIndex:scrollIndex pageIndexOnLayouter:&pageIndex];
	LTTextPageView* pageView = [[[LTTextPageView alloc] initWithFrame:frame layouter:layouter pageIndex:pageIndex] autorelease];
	NSUInteger layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
	
	NSMutableArray* loadedViews = [_loadedViews objectAtIndex:layouterIndex];
	[loadedViews replaceObjectAtIndex:pageIndex withObject:pageView];
	
	LTTextLogInfo(@"created view layouter:%d, page:%d, scroll:%d", layouterIndex, pageIndex, [self _scrollIndexOfLayouter:layouter atPageIndex:pageIndex]);
	
	return pageView;
}

-(UIView *)pageViewAtScrollIndex:(NSUInteger)index
{
    NSUInteger pageIndex = 0;
	LTTextLayouter* layouter = [self layouterAtScrollIndex:index pageIndexOnLayouter:&pageIndex];
	NSUInteger layouterIndex = [_layouters indexOfObjectIdenticalTo:layouter];
    
	id obj = [[_loadedViews objectAtIndex:layouterIndex] objectAtIndex:pageIndex];
	if ([obj isKindOfClass:[NSNull class]]) {
		return nil;
	}
    
    return (UIView*)obj;
}

- (NSMutableArray*)_loadedViewsArrayCount:(NSUInteger)count
{
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
	for (NSUInteger i = 0; i < count; i++) {
		[array addObject:[NSNull null]];
	}
	
	return array;
}

- (void)_recreateTextviews
{
	if (self.hidden || self.alpha == 0.0) {
		NSLog(@"TextView: %@ is not appears.", self);
		return;
	}
	
	LTTextLogInfo(@"%s: current scroll index: %d", __func__, _currentScrollIndex);
    
    
	
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
	NSLog(@"scrollIndexToUse: %@", scrollIndexToUse);
	
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
        [self sendSubviewToBack:view];
	}
	
	//LTTextLogInfo(@"%@", self.subviews);
}

-(void)_layoutPages
{
    _currentScrollIndex = [self _currentScrollIndex];
    
    [self stringIndex:&_currentState.strIndex layouterIndex:&_currentState.attrIndex];
    
    LTTextLogInfo(@"scroll index changed, attr:%u, str:%u, decelerating: %d", _currentState.attrIndex, _currentState.strIndex, self.isDecelerating);
    
    [self _recreateTextviews];
    LTTextPageView* pageView = (id)[self _hasViewWithScrollIndex:_currentScrollIndex];
    [pageView showAttachmentsIfNeeded];
    
    
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
	self.contentSize = [self _contentSizeForCurrentLayoutMode];
	
	//self.contentOffset = CGPointMake(bounds.size.width*[self _scrollIndexOfLayouter:_currentPageState._layouter atPageIndex:_currentPageState._pageIndex], 0);
	
	//[self setContentOffset:CGPointMake(self.bounds.size.width*_currentPageIndex, 0) animated:NO];
	//[self scrollToStringIndex:_currentState.strIndex onAttributedStringAtIndex:_currentState.attrIndex animated:YES];
	
    if (_layoutModeChanged) {
        _layoutModeChanged = NO;
        self.contentOffset = [self _contentOffsetForIndex:_currentScrollIndex];
    } else {
        //[self scrollToStringIndex:_currentState.strIndex onLayouterAtIndex:_currentState.attrIndex animated:NO];
    }
}


-(void)layoutSubviews
{
	[super layoutSubviews];
	
	BOOL framesizeChanged = _framesizeChanged;
	if (_framesizeChanged) {
		[self _framesizeChanged];
	}
	
	if ( ([self _currentScrollIndex] != _currentScrollIndex) || framesizeChanged) {
        [self _layoutPages];
	}
	
	
}

#pragma mark - Scroll View Delegate

- (void)_notifyScrollIndexChangingIfChanged
{
    if (_scrollIndexChanged != _currentScrollIndex) {
        if ([self.textViewDelegate respondsToSelector:@selector(textviewDidChangeScrollIndex:)]) {
            [self.textViewDelegate textviewDidChangeScrollIndex:self];
        }
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollIndexChanged = _currentScrollIndex;
    if ([self.textViewDelegate respondsToSelector:@selector(textviewBeginDragging:)]) {
        [self.textViewDelegate textviewBeginDragging:self];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self _notifyScrollIndexChangingIfChanged];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _notifyScrollIndexChangingIfChanged];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.textViewDelegate respondsToSelector:@selector(textviewDidScroll:)]) {
        [self.textViewDelegate textviewDidScroll:self];
    }
}

@end
