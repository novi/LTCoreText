//
//  LTTextImageScrollView.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/04.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import "LTCoreText.h"


@interface LTTextImageScrollView : UIScrollView<UIScrollViewDelegate>

- (id)initWithFrame:(CGRect)frame image:(UIImage*)image;

// Close action: lt_zoomedImageViewClose:

@end
