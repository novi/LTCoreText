//
//  LTTextImageScrollView.h
//  LTCoreText
//
//  Created by ito on H.23/08/04.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//
#import "LTCoreText.h"


@interface LTTextImageScrollView : UIScrollView<UIScrollViewDelegate>

- (id)initWithFrame:(CGRect)frame image:(UIImage*)image;

// Close action: lt_zoomedImageViewClose:

@end
