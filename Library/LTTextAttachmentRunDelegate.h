//
//  LTTextAttachmentRunDelegate.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/12/16.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


// CTRundelegate callbacks
void lt_TextRunDelegateDeallocCallback(void* context);
CGFloat lt_TextRunDelegateGetAscentCallback(void* context);
CGFloat lt_TextRunDelegateGetDescentCallback(void* context);
CGFloat lt_TextRunDelegateGetWidthCallback(void* context);

CTRunDelegateRef lt_TextCreateRunDelegateForAttachment(id obj);