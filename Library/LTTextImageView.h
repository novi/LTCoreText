//
//  LTTextImageView.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/04.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "LTCoreText.h"
#import <UIKit/UIKit.h>

@interface LTTextImageView : UIImageView

@property (nonatomic) NSURL* imageURL;
@property (nonatomic) CGSize displaySize;

- (void)startDownload;

// Tap Action : lt_imageSelected:

// @property (nonatomic, retain, readonly) UITapGestureRecognizer* tapGesture;

@end
