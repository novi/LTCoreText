//
//  LTTextAttachmentRunDelegate.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/12/16.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "LTTextAttachmentRunDelegate.h"
#import "LTTextAttachment.h"

void lt_TextRunDelegateDeallocCallback(void* context)
{
    
}

CGFloat lt_TextRunDelegateGetAscentCallback(void* context)
{
    if ([(__bridge id)context conformsToProtocol:@protocol(LTTextAttachment)]) {
        id<LTTextAttachment> obj = (__bridge id)context;
        return obj.displaySize.height;
    }
    
    return 0.0;
}

CGFloat lt_TextRunDelegateGetDescentCallback(void* context)
{
    return 0;
}

CGFloat lt_TextRunDelegateGetWidthCallback(void* context)
{
    if ([(__bridge id)context conformsToProtocol:@protocol(LTTextAttachment)]) {
        id<LTTextAttachment> obj = (__bridge id)context;
        return obj.displaySize.width;
    }
    
    return 0.0;
}

CTRunDelegateRef lt_TextCreateRunDelegateForAttachment(id obj)
{
    CTRunDelegateCallbacks callbacks;
    callbacks.dealloc = lt_TextRunDelegateDeallocCallback;
    

    return CTRunDelegateCreate(&callbacks, (__bridge void*)obj);
}