//
//  LTTextImageView.h
//  LTCoreText
//
//  Created by ito on H.23/08/04.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"
#import <UIKit/UIKit.h>

@class DTTextAttachment;
@interface LTTextImageView : UIImageView

@property (nonatomic, retain) DTTextAttachment* attachment;

// Tap Action : lt_imageSelected:

// @property (nonatomic, retain, readonly) UITapGestureRecognizer* tapGesture;

@end
