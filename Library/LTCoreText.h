//
//  LTCoreText.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "LTTextLayouter.h"
#import "LTTextAttachment.h" // Protocol


#define LTTextLogInfo NSLog
#define LTTextLogError NSLog

#define LTTextRelease(obj) {if (obj) { [(obj) release]; obj = nil; } }
#define LTTextCFRelease(obj) { if (obj) { CFRelease(obj); } }
#define LTTextMethodDebugLog() {NSLog(@"%s,%@", __func__, self);}


#define LTTextViewBackgroundColorDebug (0)


