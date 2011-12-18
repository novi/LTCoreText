//
//  LTTextView.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"
#import <CoreText/CoreText.h>


@class LTTextView;
@protocol LTTextViewDelegate <NSObject>

@required
- (UIView*)textview:(LTTextView*)textView viewForRunDictionary:(NSDictionary*)dict;

@optional
- (void)textview:(LTTextView*)textView willDrawPageIndex:(NSUInteger)pageIndex inContext:(CGContextRef)context;
- (void)textview:(LTTextView*)textView didDrawPageIndex:(NSUInteger)pageIndex inContext:(CGContextRef)context;

@end

@interface LTTextView : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, assign) id<LTTextViewDelegate> textViewDelegate;
@property (nonatomic, retain, readonly) NSArray* layouters;

- (void)insertLayouter:(LTTextLayouter*)layouter atIndex:(NSUInteger)index;
- (void)removeLayouterAtIndex:(NSUInteger)index;

- (void)scrollToStringIndex:(NSUInteger)strIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated;
- (void)stringIndex:(NSUInteger*)strIndex layouterIndex:(NSUInteger*)layouterIndex;

- (void)redrawPageIfNeeded;

@end
