//
//  LTTextAttachmentRunDelegate.h
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


// CTRundelegate callbacks
void lt_TextRunDelegateDeallocCallback(void* context);
CGFloat lt_TextRunDelegateGetAscentCallback(void* context);
CGFloat lt_TextRunDelegateGetDescentCallback(void* context);
CGFloat lt_TextRunDelegateGetWidthCallback(void* context);

CTRunDelegateRef lt_TextCreateRunDelegateForAttachment(id obj);