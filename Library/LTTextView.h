//
//  LTTextView.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"

@interface LTTextView : UIScrollView<UIScrollViewDelegate>


@property (nonatomic, retain, readonly) NSArray* layouters;

- (void)insertLayouter:(LTTextLayouter*)layouter atIndex:(NSUInteger)index;
- (void)removeLayouterAtIndex:(NSUInteger)index;

- (void)scrollToStringIndex:(NSUInteger)strIndex onLayouterAtIndex:(NSUInteger)layouterIndex animated:(BOOL)animated;
- (void)stringIndex:(NSUInteger*)strIndex layouterIndex:(NSUInteger*)layouterIndex;

- (void)redrawPageIfNeeded;

@end
