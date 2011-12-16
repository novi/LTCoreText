//
//  LTTextLayouter.h
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTCoreText.h"

NSString* const LTTextLayouterOptionOriginalURLKey;


@interface LTTextLayouter : NSObject

// TODO:
// ヘッダを左に置く

+(NSAttributedString *)generateAttributedStringFromHTMLString:(NSData*)htmlData title:(NSString *)title options:(NSDictionary *)options;

-(id)initWithAttributedString:(NSAttributedString *)attrString frameSize:(CGSize)size landscapeLayout:(BOOL)landscape options:(NSDictionary*)options;

@property (nonatomic, readonly) BOOL isLandscapeLayout;
@property (nonatomic, retain, readonly) NSAttributedString* attributedString;
@property (nonatomic, readonly) CGSize frameSize;
@property (nonatomic, readonly) NSUInteger pageCount;
@property (nonatomic, readonly) NSUInteger columnCount;

@property (nonatomic, retain) UIColor* backgroundColor;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGFloat columnSpace;
@property (nonatomic) float justifyThreshold; // 1.0 is no justify
@property (nonatomic) BOOL useHyphenation;

- (NSUInteger)pageIndexAtStringIndex:(NSUInteger)index;

- (NSRange)rangeOfStringAtPageIndex:(NSUInteger)index;

- (NSArray*)attachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col;

- (CGRect)imageFrameAtPageIndex:(NSUInteger)index column:(NSUInteger)col;
- (NSArray*)imageAttachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col;
- (NSArray*)imageFrameWithImageSizes:(NSArray*)sizes atPageIndex:(NSUInteger)index column:(NSUInteger)col;

- (void)doLayout;

- (void)drawInContext:(CGContextRef)context atPage:(NSUInteger)pageIndex;

@end
