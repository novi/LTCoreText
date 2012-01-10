//
//  LTTextPageView.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/07/07.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import "LTCoreText.h"

#define LTTextPageViewDrawPageNumDebug (0)

@interface LTTextPageView : UIView

- (id)initWithFrame:(CGRect)frame layouter:(LTTextLayouter*)layouter pageIndex:(NSUInteger)index;

@property (nonatomic, retain, readonly) LTTextLayouter* layouter;
@property (nonatomic, readonly) NSUInteger index;

- (void)showAttachmentsIfNeeded;

@end
