//
//  LTTextAttachmentRunDelegate.m
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
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