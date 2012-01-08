//
//  LTTextImageView.h
//  LTCoreText
//
//  Created by ito on H.23/08/04.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"
#import <UIKit/UIKit.h>

@interface LTTextImageView : UIImageView

@property (nonatomic, retain) NSURL* imageURL;
@property (nonatomic) CGSize displaySize;

- (void)startDownload;

// Tap Action : lt_imageSelected:

// @property (nonatomic, retain, readonly) UITapGestureRecognizer* tapGesture;

@end
