//
//  LTTextLayouter.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"


// Primitive
@interface LTTextLayouter : NSObject

-(id)initWithAttributedString:(NSAttributedString *)attrString frameSize:(CGSize)size options:(NSDictionary*)options;

@property (nonatomic, retain, readonly) NSAttributedString* attributedString;
@property (nonatomic, readonly) CGSize frameSize;
@property (nonatomic, readonly) NSUInteger pageCount;
@property (nonatomic) NSUInteger columnCount;

@property (nonatomic, retain) UIColor* backgroundColor;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGFloat columnSpace;
@property (nonatomic) float justifyThreshold; // 1.0 is no justify
@property (nonatomic) BOOL useHyphenation; // attributedString must be hyphenated with (soft-hyphen, u0x00AD)


- (NSRange)rangeOfStringAtPageIndex:(NSUInteger)index column:(NSUInteger)col;
- (NSUInteger)pageIndexAtStringIndex:(NSUInteger)index;

- (NSArray*)attachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col;

- (void)layoutIfNeeded;

- (void)drawInContext:(CGContextRef)context atPage:(NSUInteger)pageIndex;

@end



