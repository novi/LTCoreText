//
//  LTTextLayouter.m
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTTextLayouter.h"

CGFloat const kLTTextLayouterLineToImageSpace = 10.0;

NSString* const LTTextLayouterOptionOriginalURLKey = @"originalURL";

@interface LTTextLayouter()
{
	NSAttributedString* _attributedString;
	CGSize _frameSize;
	BOOL _landscapeLayout;
	NSDictionary* _options;
	
	BOOL _needFrameLayout;
	CTFramesetterRef _framesetter;
	NSMutableArray* _frames;
	NSMutableArray* _attachments;
	UIEdgeInsets _contentInset;
	CGFloat _columnSpace;
	CGColorRef _backgroundColor;
}

- (void)_createAttachmentsArray;
- (NSUInteger)_imageCountOfAttachments:(NSArray*)array;
- (NSArray*)_attachmentsWithCTFrame:(CTFrameRef)frame;
- (void)_layoutFrame;

@property (nonatomic, retain) NSURL* originalURL;

@end

@implementation LTTextLayouter

@synthesize attributedString = _attributedString;
@synthesize frameSize = _frameSize;
@synthesize contentInset = _contentInset;
@synthesize columnSpace = _columnSpace;
@synthesize justifyThreshold;
@synthesize useHyphenation;
@synthesize isLandscapeLayout = _landscapeLayout;
@synthesize originalURL;

+(NSAttributedString *)generateAttributedStringFromHTMLString:(NSData*)htmlData title:(NSString *)title options:(NSDictionary *)options
{
	
	NSMutableDictionary* attrOptions = [NSMutableDictionary dictionaryWithCapacity:5];
	/*[attrOptions setObject:@"Palatino" forKey:DTDefaultFontFamily];
	[attrOptions setObject:[NSNumber numberWithFloat:14.0/12.0] forKey:NSTextSizeMultiplierDocumentOption];
	[attrOptions setObject:[NSNumber numberWithFloat:1.2] forKey:DTDefaultLineHeightMultiplier];
	[attrOptions setObject:[NSValue valueWithCGSize:CGSizeMake(1, 1)] forKey:DTMaxImageSize];
	//[attrOptions setObject:[NSNumber numberWithBool:self.hyphenSwitch.on] forKey:DTUseHyphenation];
	*/
    NSDictionary* attr = nil;
     
	NSAttributedString* mainString = [[NSAttributedString alloc] initWithHTML:htmlData options:attrOptions documentAttributes:&attr];
	
	// Create Title Attibuted String
	NSMutableDictionary* titleAttributes = [NSMutableDictionary dictionaryWithCapacity:5];
	CTFontRef titleFont = CTFontCreateWithName(CFSTR("Palatino-Bold"), 28.0, NULL);
	UIColor* titleColor = [UIColor colorWithWhite:0.1 alpha:1.0];
	[titleAttributes setObject:(id)titleFont forKey:(id)kCTFontAttributeName];
	CFRelease(titleFont);
	[titleAttributes setObject:(id)[titleColor CGColor]	forKey:(id)kCTForegroundColorAttributeName];
	
	CTParagraphStyleSetting titleStyleSetting[2];
	titleStyleSetting[0].valueSize = sizeof(CGFloat);
	titleStyleSetting[0].spec = kCTParagraphStyleSpecifierParagraphSpacingBefore;
	CGFloat titleParaSpaceBefore = 24.0f;
	titleStyleSetting[0].value = &titleParaSpaceBefore;
	
	titleStyleSetting[1].valueSize = sizeof(CGFloat);
	titleStyleSetting[1].spec = kCTParagraphStyleSpecifierParagraphSpacing;
	CGFloat titleParaSpace = 24.0f;
	titleStyleSetting[1].value = &titleParaSpace;
	
	CTParagraphStyleRef titleStyle = CTParagraphStyleCreate(titleStyleSetting, 2);
	[titleAttributes setObject:(id)titleStyle forKey:(id)kCTParagraphStyleAttributeName];
	CFRelease(titleStyle);
	
	NSMutableAttributedString* attrString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", title] attributes:titleAttributes] autorelease];
	
	[attrString appendAttributedString:mainString];
	
	return attrString;
}

#pragma mark -

- (id)init
{    
	[self doesNotRecognizeSelector:_cmd];
    return nil;
}

-(id)initWithAttributedString:(NSAttributedString *)attrString frameSize:(CGSize)size landscapeLayout:(BOOL)landscape options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        _attributedString = [attrString copy];
		_options = [[NSDictionary dictionaryWithDictionary:options] retain];
		_framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
		_frameSize = size;
		_landscapeLayout = landscape;
		_needFrameLayout = YES;
		self.backgroundColor = [UIColor colorWithRed:248/255.0 green:244/255.0 blue:230/255.0 alpha:1.0];
		self.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
		self.columnSpace = 25;
		self.justifyThreshold = 1.0;
		self.useHyphenation = NO;
		
		self.originalURL = [options objectForKey:LTTextLayouterOptionOriginalURLKey];
    }
    return self;
}

- (void)dealloc
{
	self.originalURL = nil;
	LTTextMethodDebugLog();
	LTTextRelease(_frames);
	LTTextRelease(_attributedString);
	LTTextCFRelease(_framesetter);
	if (_backgroundColor) CGColorRelease(_backgroundColor);
	[super dealloc];
}

#pragma mark -

- (NSRange)rangeOfStringAtPageIndex:(NSUInteger)index
{
	CTFrameRef frame = (CTFrameRef)[[_frames objectAtIndex:index] lastObject];
	CFRange range = CTFrameGetVisibleStringRange(frame);
	
	return NSMakeRange(range.location, range.length);
}

-(NSUInteger)pageIndexAtStringIndex:(NSUInteger)index
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
	
	if (index+1 > [_attributedString length]) {
		return 0;
	}
	
	/*NSUInteger count = 0;
	 for (id frame in _frames) {
	 count += CTFrameGetVisibleStringRange((CTFrameRef)frame).length;
	 if (count > index) {
	 //return [self _pageIndexAtFrameIndex:[_frames indexOfObjectIdenticalTo:frame]];
	 }
	 }*/
	
	return 0;
}
/*
 - (CGSize)_columnSize
 {
 CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
 
 CGFloat width = contentFrame.size.width;
 width -= _columnSpace*(_columnCount-1);
 width = floorf(width/(CGFloat)_columnCount);
 return CGSizeMake(width, contentFrame.size.height);
 }*/

- (CGRect)_columnFrameWithColumn:(NSUInteger)col
{
	CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
	CGFloat width = (contentFrame.size.width - _columnSpace*2.0)/2.0;
	
	if (_landscapeLayout) {
		if (col == 1) {
			contentFrame.origin.x += width + _columnSpace;
			contentFrame.size.width = width;
		} else {
			contentFrame.size.width = width;
		}
	}
	
	return contentFrame;
}

- (CTFrameRef)_frameWithContentFrame:(CGRect)contentFrame range:(CFRange)range rightImageAlign:(BOOL)rightImage
{
	//CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
	CGSize size = contentFrame.size;
	
	CGFloat imageWidths_pt[] = {100, 140, 160, 200};
	NSUInteger allowImageCounts_pt[] = {0, 1, 2, NSUIntegerMax};
	
	CGFloat imageWidths_ls[] = {20, 120, 160, 180};
	NSUInteger allowImageCounts_ls[] = {0, 1, 2, NSUIntegerMax};
	
	CGFloat* imageWidths;
	NSUInteger* allowImageCounts;
	if (_landscapeLayout) {
		imageWidths = imageWidths_ls;
		allowImageCounts = allowImageCounts_ls;
	} else {
		imageWidths = imageWidths_pt;
		allowImageCounts = allowImageCounts_pt;
	}
	
	for (int i = 0 ; i < 4; i++) {
		CGFloat imageWidth = imageWidths[i];
		CGRect r;
		if (rightImage) {
			r = CGRectMake(contentFrame.origin.x, contentFrame.origin.y, size.width-imageWidth-_columnSpace, size.height);
		} else {
			r = CGRectMake(contentFrame.origin.x+imageWidth+_columnSpace, contentFrame.origin.y, size.width-imageWidth-_columnSpace, size.height);
		}
		CGPathRef path =  [[UIBezierPath bezierPathWithRect:r] CGPath];	
		CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, range, path, NULL);
		NSUInteger imageCount = [self _imageCountOfAttachments:[self _attachmentsWithCTFrame:frame]];
		if (imageCount <= allowImageCounts[i]) {
			return (CTFrameRef)[(id)frame autorelease];
		}
		LTTextCFRelease(frame);
	}
	
	return NULL;
}


- (CGRect)imageFrameAtPageIndex:(NSUInteger)index column:(NSUInteger)col;
{
	CGRect colFrame = [self _columnFrameWithColumn:col];
	NSArray* frames = [_frames objectAtIndex:index];
	if ([frames count] <= col) {
		return CGRectZero;
	}
	CTFrameRef frame = (CTFrameRef)[frames objectAtIndex:col];
	
	CGRect pathBBox = CGPathGetBoundingBox(CTFrameGetPath(frame));
	
	colFrame.size.width -= pathBBox.size.width+_columnSpace;
	if (col == 1) {
		//colFrame.origin.x += pathBBox.size.width+_columnSpace;
	}
	NSLog(@"image %@ at %d col %d", NSStringFromCGRect(colFrame), index, col);
	return colFrame;
}

- (void)_layoutFrame
{
	_needFrameLayout = NO;
	LTTextRelease(_frames);
	_frames = [[NSMutableArray alloc] init];
	
	
	CFIndex length = CFAttributedStringGetLength((CFAttributedStringRef)_attributedString);
	CFRange strRange = CFRangeMake(0, 0);
	
	NSMutableArray* currentFrames = [NSMutableArray array];
	for (; ; ) {
		CGRect contentFrame;
		CTFrameRef frame;
		if (_landscapeLayout) {
			if ([currentFrames count] == 1) {
				contentFrame = [self _columnFrameWithColumn:1];
				frame = [self _frameWithContentFrame:contentFrame range:strRange rightImageAlign:NO];
			} else {
				contentFrame = [self _columnFrameWithColumn:0];
				frame = [self _frameWithContentFrame:contentFrame range:strRange rightImageAlign:NO];
			}
		} else {
			contentFrame = [self _columnFrameWithColumn:0];
			frame = [self _frameWithContentFrame:contentFrame range:strRange rightImageAlign:NO];
		}
		
		if (_landscapeLayout) {
			if ([currentFrames count] == 2) {
				// Create new frame array
				[_frames addObject:currentFrames];
				currentFrames = [NSMutableArray array];
				[currentFrames addObject:(id)frame];
			} else {
				[currentFrames addObject:(id)frame];
			}
		} else {
			[_frames addObject:[NSArray arrayWithObject:(id)frame]];
		}
		
		NSLog(@"frame %p, %@, image %d", frame, NSStringFromCGRect(CGPathGetBoundingBox(CTFrameGetPath(frame))), [[self _attachmentsWithCTFrame:frame] count]);
		
		CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
		if (visibleRange.length+visibleRange.location >= length) {
			break;
		}
		strRange.location = visibleRange.location+visibleRange.length;
	}
	
	if ([currentFrames count]) {
		[_frames addObject:currentFrames];
	}
	
	[self _createAttachmentsArray];
	
	LTTextLogInfo(@"page count %d", [_frames count]);
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
	_backgroundColor = CGColorRetain([backgroundColor CGColor]);
}

-(UIColor *)backgroundColor
{
	return [UIColor colorWithCGColor:_backgroundColor];
}


-(NSUInteger)pageCount
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
	return _frames.count;
}

-(NSUInteger)columnCount
{	
	if (_landscapeLayout) {
		return 2;
	}
	return 1;
}

/*
 -(void)setContentInset:(UIEdgeInsets)contentInset
 {
 _contentInset = contentInset;
 _needFrameLayout = YES;
 }
 
 -(void)setColumnCount:(NSUInteger)columnCount
 {
 _columnCount = columnCount;
 _needFrameLayout = YES;
 }
 
 -(void)setColumnSpace:(CGFloat)columnSpace
 {
 _columnSpace = columnSpace;
 _needFrameLayout = YES;
 }*/

-(void)doLayout
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
}


-(void)drawInContext:(CGContextRef)context atPage:(NSUInteger)page
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
	
	if (page >= self.pageCount) {
		return;
	}
	
	//CGContextTranslateCTM(context, 0, _contentInset.bottom);
	
	NSArray* frames = [_frames objectAtIndex:page];
	//for (id obj in [_frames objectAtIndex:page]) {
	for (NSUInteger i = 0; i < [frames count]; i++) {
		
		CTFrameRef frame = (CTFrameRef)[frames objectAtIndex:i];
		CFArrayRef lines = CTFrameGetLines(frame);
		CGPoint* lineOrigin = malloc(CFArrayGetCount(lines)*sizeof(CGPoint));
		CTFrameGetLineOrigins(frame, CFRangeMake(0, CFArrayGetCount(lines)), lineOrigin);
		CGRect pathBBox = CGPathGetBoundingBox(CTFrameGetPath(frame));
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, pathBBox.origin.x, pathBBox.origin.y);
		
		{
			CGContextSetFillColorWithColor(context, _backgroundColor);
			//[[UIColor colorWithWhite:0.9+0.1 alpha:1.0] set];
			UIRectFill(CGRectMake(0, 0, pathBBox.size.width, pathBBox.size.height));
			
			//CTFrameDraw(frame, context);
			for (CFIndex linei = 0; linei < CFArrayGetCount(lines); linei++) {
				CGContextSaveGState(context);
				CGContextSetTextMatrix(context, CGAffineTransformIdentity);
				CGContextSetTextPosition(context, 0, 0);
				CGContextTranslateCTM(context, lineOrigin[linei].x, lineOrigin[linei].y);
				
				CTLineRef line = CFArrayGetValueAtIndex(lines, linei);
				CGRect lineBounds = CTLineGetImageBounds(line, context);
				if (useHyphenation) {
					CFRange cfStringRange = CTLineGetStringRange(line);
					NSRange stringRange = NSMakeRange(cfStringRange.location, cfStringRange.length);
					static const unichar softHypen = 0x00AD;
					unichar lastChar = [_attributedString.string characterAtIndex:stringRange.location + stringRange.length-1];
					
					if(softHypen == lastChar) {
						NSMutableAttributedString* lineAttrString = [[_attributedString attributedSubstringFromRange:stringRange] mutableCopy];
						NSRange replaceRange = NSMakeRange(stringRange.length-1, 1);
						[lineAttrString replaceCharactersInRange:replaceRange withString:@"-"];
						
						CTLineRef hyphenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)lineAttrString);
						CTLineRef justifiedLine = CTLineCreateJustifiedLine(hyphenLine, 1.0, pathBBox.size.width); 
						CTLineDraw(justifiedLine, context);
						CFRelease(justifiedLine);
						//CTLineDraw(hyphenLine, context);
						CFRelease(hyphenLine);
						[lineAttrString release];
					} else {
						if (justifyThreshold != 1.0 && lineBounds.size.width >= pathBBox.size.width*justifyThreshold) {
							CTLineRef justLine = CTLineCreateJustifiedLine(line, 1.0, pathBBox.size.width);
							CTLineDraw(justLine, context);
							CFRelease(justLine);
						} else {
							CTLineDraw(line, context);
						}
					}
				} else {
					if (justifyThreshold != 1.0 && lineBounds.size.width >= pathBBox.size.width*justifyThreshold) {
						CTLineRef justLine = CTLineCreateJustifiedLine(line, 1.0, pathBBox.size.width);
						CTLineDraw(justLine, context);
						CFRelease(justLine);
					} else {
						CTLineDraw(line, context);
					}
				}
				
				CGContextRestoreGState(context);
			}
		}
		
		CGRect imageFrame = [self imageFrameAtPageIndex:page column:i];
		NSArray* attachments = [[_attachments objectAtIndex:page] objectAtIndex:i];
		for (NSDictionary* dict in attachments) {
			NSLog(@"%@", dict);
			CGPoint p = [[dict objectForKey:@"position"] CGPointValue];
			CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
			CGContextMoveToPoint(context, p.x-5.0, roundf(p.y)+0.5);
			CGContextAddLineToPoint(context, p.x-imageFrame.size.width-_columnSpace, roundf(p.y)+0.5);
			CGContextStrokePath(context);
			//CGContextFillRect(context, CGRectMake(p.x, p.y, 10, 10));
		}
		
		
		CGContextRestoreGState(context);
		//CGContextTranslateCTM(context, size.width+_columnSpace, 0);
		free(lineOrigin);
	}
	
}

#pragma mark - Attachments

- (void)_storeFrameOfAttachment:(CTFrameRef)frame to:(NSMutableArray*)dst
{
	CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
	CGFloat height = contentFrame.size.height;
	
	CFArrayRef lines = CTFrameGetLines(frame);
	for (CFIndex i = 0; i < CFArrayGetCount(lines); i++) {
		CTLineRef line = CFArrayGetValueAtIndex(lines, i);
		CFArrayRef runs = CTLineGetGlyphRuns(line);
		for (CFIndex ri = 0; ri < CFArrayGetCount(runs); ri++) {
			CTRunRef run = CFArrayGetValueAtIndex(runs, ri);
			CFDictionaryRef attr = CTRunGetAttributes(run);
			if (CFDictionaryGetValue(attr, @"DTTextAttachment")) {
				/*DTTextAttachment* attachment = [(id)attr objectForKey:@"DTTextAttachment"];
				
				// Fix Image URL
				if (attachment.contentType == DTTextAttachmentTypeImage) {
					if ([attachment.contentURL host].length == 0) {
						NSURL* fixedURL = [NSURL URLWithString:[attachment.contentURL absoluteString] relativeToURL:self.originalURL];
						//NSLog(@"not full url: %@ ,fixed %@", attachment.contentURL, [fixedURL absoluteURL]);
						attachment.contentURL = fixedURL;
					}
				}
				
				CGPoint p;
				CTFrameGetLineOrigins(frame, CFRangeMake(i, 1), &p);
				float ascent;
				CTLineGetTypographicBounds(line, &ascent, NULL, NULL);
				p.y += ascent;
				NSLog(@"line:%p count: %ld", line, CTLineGetStringRange(line).length);
				//NSLog(@"line:%p, %@", line, NSStringFromCGPoint(p));
				NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:attachment
									  ,@"attachment"
									  ,[NSValue valueWithCGPoint:p]
									  ,@"position"
									  ,[NSValue valueWithCGPoint:CGPointMake(p.x, (height - p.y) + _contentInset.bottom)]
									  ,@"position_view", nil];
				[dst addObject:dict];
                 */
				//				[array addObject:attachment];
			}
		}
	}
}

- (void)_createAttachmentsArray
{
	LTTextRelease(_attachments);
	_attachments = [[NSMutableArray alloc] init];
	
	
	for (NSArray* frames in _frames) {
		NSMutableArray* dstarrayPage = [NSMutableArray array];
		[_attachments addObject:dstarrayPage];
		for (id frame in frames) {
			NSMutableArray* dstArrayFrame = [NSMutableArray array];
			[self _storeFrameOfAttachment:(CTFrameRef)frame to:dstArrayFrame];
			[dstarrayPage addObject:dstArrayFrame];
		}
	}
}

-(NSArray *)_attachmentsWithCTFrame:(CTFrameRef)frame
{
	NSMutableArray* array = [NSMutableArray array];
	[self _storeFrameOfAttachment:frame to:array];
	return array;
}

- (NSUInteger)_imageCountOfAttachments:(NSArray*)array
{
	NSUInteger count = 0;
	for (NSDictionary* dict in array) {
		/*DTTextAttachment* attachment = [dict objectForKey:@"attachemnt"];
		if (attachment.contentType == DTTextAttachmentTypeImage) {
			count++;
		}*/
	}
	
	return count;
}

-(NSArray *)attachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col
{
	NSArray* frames = [_frames objectAtIndex:index];
	if ([frames count] <= col) {
		return nil;
	}
	return [self _attachmentsWithCTFrame:(CTFrameRef)[frames objectAtIndex:col]];
}

-(NSArray *)imageAttachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col
{
	NSArray* frames = [_frames objectAtIndex:index];
	if ([frames count] <= col) {
		return nil;
	}
	NSMutableArray* array = [NSMutableArray array];
	[self _storeFrameOfAttachment:(CTFrameRef)[frames objectAtIndex:col] to:array];
	
	NSMutableArray* dst = [NSMutableArray array];
	for (NSDictionary* dict in array) {
		/*DTTextAttachment* attachment = [dict objectForKey:@"attachemnt"];
		if (attachment.contentType == DTTextAttachmentTypeImage) {
			[dst addObject:dict];
		}*/
	}
	return dst;
}

-(NSArray *)imageFrameWithImageSizes:(NSArray *)sizes atPageIndex:(NSUInteger)index column:(NSUInteger)col
{
	NSArray* attachments = [self imageAttachmentsAtPageIndex:index column:col];
	if (attachments.count != sizes.count) {
		LTTextLogError(@"Error: %s, image size is not equal to attachment count", __func__);
		return nil;
	}
	CGRect imageFrame = [self imageFrameAtPageIndex:index column:col];
	
	NSMutableArray* dst = [NSMutableArray array];
	CGRect lastFrame = CGRectZero;
	
	NSUInteger i = 0;
	for (NSValue* sizeVal in sizes) {
		NSDictionary* dict = [attachments objectAtIndex:i];
		CGPoint p = [[dict objectForKey:@"position_view"] CGPointValue];
		
		CGSize imgSize = [sizeVal CGSizeValue];
		CGFloat height = MAX(imgSize.height, 40);
		CGRect frame = CGRectMake(imageFrame.origin.x, floorf(p.y-height), imageFrame.size.width, height);
		frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(0, 0, kLTTextLayouterLineToImageSpace, 0));
		
		BOOL frameBoundsAdjust = NO;
		if (!CGRectContainsRect(CGRectInset(CGRectMake(0, 0, _frameSize.width, _frameSize.height), 0, 10), frame) || frame.origin.y < 10) {
			frame.origin.y += (kLTTextLayouterLineToImageSpace*2) + height;
			frameBoundsAdjust = YES;
		}
		
		if ( !CGRectEqualToRect(lastFrame, CGRectZero) &&
			CGRectIntersectsRect(lastFrame, frame)) {
			if (frameBoundsAdjust) {
				frame.origin.y += (kLTTextLayouterLineToImageSpace) + height;
			} else {
				frame.origin.y += (kLTTextLayouterLineToImageSpace*2) + height;
			}
		}
		
		lastFrame = frame;
		[dst addObject:[NSValue valueWithCGRect:frame]];
		// imageView.frame = frame;
		i++;
	}
	
	return dst;
}

@end
