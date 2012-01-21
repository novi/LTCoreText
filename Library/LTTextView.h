//
//  LTTextView.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/07/07.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import "LTCoreText.h"
#import <CoreText/CoreText.h>

typedef NSUInteger LTTextViewLayoutMode;

enum {
    LTTextViewLayoutModeNormal = 0,
    LTTextViewLayoutModeReverse = 1,
    LTTextViewLayoutModeVertical = 2,
};


@class LTTextView, LTTextLayouter;
@protocol LTTextViewDelegate <NSObject>

@required
- (UIView*)textview:(LTTextView*)textView viewForRunDictionary:(NSDictionary*)dict;

@optional
- (void)textview:(LTTextView*)textView willDrawPageIndex:(NSUInteger)pageIndex inContext:(CGContextRef)context;
- (void)textview:(LTTextView*)textView didDrawPageIndex:(NSUInteger)pageIndex inContext:(CGContextRef)context;

- (void)textviewDidChangeScrollIndex:(LTTextView*)textView;
- (void)textviewBeginDragging:(LTTextView*)textView;
- (void)textviewDidScroll:(LTTextView*)textView;

@end

@interface LTTextView : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, assign) id<LTTextViewDelegate> textViewDelegate;
@property (nonatomic) LTTextViewLayoutMode layoutMode;

@property (nonatomic, retain, readonly) NSArray* layouters;
@property (nonatomic, readonly) NSUInteger allPageCount;
@property (nonatomic, readonly) NSUInteger scrollIndex;

- (void)insertLayouter:(LTTextLayouter*)layouter atIndex:(NSUInteger)index;
- (void)removeLayouterAtIndex:(NSUInteger)index;
- (LTTextLayouter*)layouterAtScrollIndex:(NSUInteger)index pageIndexOnLayouter:(NSUInteger*)indexOn;

- (void)scrollToScrollIndex:(NSUInteger)scrollIndex animated:(BOOL)animated;
- (void)scrollToLayouterPageIndex:(NSUInteger)pageIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated;
- (void)scrollToStringIndex:(NSUInteger)strIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated;

- (void)redrawPageIfNeeded;

- (UIView*)pageViewAtScrollIndex:(NSUInteger)index; // if the page view not loaded, returns nil

@end
