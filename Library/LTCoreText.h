//
//  LTCoreText.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/07/07.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "LTTextView.h"
#import "LTTextLayouter.h"
#import "LTTextAttachment.h" // Protocol


#define LTTextLogInfo NSLog
#define LTTextLogError NSLog

#define LTTextRelease(obj) {if (obj) { [(obj) release]; obj = nil; } }
#define LTTextCFRelease(obj) { if (obj) { CFRelease(obj); } }
#define LTTextMethodDebugLog() {NSLog(@"%s,%@", __func__, self);}


#define LTTextViewBackgroundColorDebug (0)


