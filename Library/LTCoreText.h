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


#if DEBUG
    #warning Debug log enabled
    #define LTTextLogInfo NSLog
    #define LTTextLogError NSLog 
#else
    #define LTTextLogInfo(...)  { do {} while (0);}
    #define LTTextLogError(...)  { do {} while (0);}
#endif

//#define LTTextRelease(obj) {if (obj) { [(obj) release]; obj = nil; } }
#define LTTextCFRelease(obj) { if (obj) { CFRelease(obj); } }
#define LTTextMethodDebugLog() {LTTextLogInfo(@"%s,%@", __func__, self);}


#define LTTextViewBackgroundColorDebug (0)


