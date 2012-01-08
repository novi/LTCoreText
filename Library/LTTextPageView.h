//
//  LTTextPageView.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"

#define LTTextPageViewDrawPageNumDebug (1)

@interface LTTextPageView : UIView

- (id)initWithFrame:(CGRect)frame layouter:(LTTextLayouter*)layouter pageIndex:(NSUInteger)index;

@property (nonatomic, retain, readonly) LTTextLayouter* layouter;
@property (nonatomic, readonly) NSUInteger index;

- (void)showAttachmentsIfNeeded;

@end
