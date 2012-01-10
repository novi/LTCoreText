//
//  LTTextLayouter.m
//  LTCoreText
//
//  Created by ito on H.23/07/07.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import "LTTextLayouter.h"


@interface LTTextFrame : NSObject
{
    
}

@property (nonatomic, retain) id frame;
@property (nonatomic) CGRect contentFrame;


@end

@implementation LTTextFrame

@synthesize frame, contentFrame;
- (void)dealloc
{
    self.frame = nil;
    [super dealloc];
}

@end

CGFloat const kLTTextLayouterLineToImageSpace = 10.0;



@interface LTTextLayouter()
{
	NSAttributedString* _attributedString;
	CGSize _frameSize;
	NSDictionary* _options;
	
    NSUInteger _columnCount;
	BOOL _needFrameLayout;
	CTFramesetterRef _framesetter;
	NSMutableArray* _frames;
	NSMutableArray* _attachments;
	UIEdgeInsets _contentInset;
	CGFloat _columnSpace;
	CGColorRef _backgroundColor;
    BOOL _verticalText;
}

- (void)_createAttachmentsArray;
- (NSArray*)_attachmentsWithCTFrame:(CTFrameRef)frame;
- (void)_layoutFrame;



@end

@implementation LTTextLayouter

@synthesize attributedString = _attributedString;
@synthesize frameSize = _frameSize;
@synthesize contentInset = _contentInset;
@synthesize columnSpace = _columnSpace;
@synthesize justifyThreshold;
@synthesize useHyphenation;
@synthesize columnCount = _columnCount;
@synthesize verticalText = _verticalText;


#pragma mark -

- (id)init
{    
	[self doesNotRecognizeSelector:_cmd];
    return nil;
}

-(id)initWithAttributedString:(NSAttributedString *)attrString frameSize:(CGSize)size options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        _attributedString = [attrString copy];
		_options = [[NSDictionary dictionaryWithDictionary:options] retain];
		_framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
		_frameSize = size;
		
		_needFrameLayout = YES;
		self.backgroundColor = [UIColor colorWithRed:248/255.0 green:244/255.0 blue:230/255.0 alpha:1.0];
		self.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
		self.columnSpace = 25;
		self.justifyThreshold = 1.0;
		self.useHyphenation = NO;
		
        _columnCount = 1;
		
    }
    return self;
}

- (void)dealloc
{
    
	LTTextMethodDebugLog();
	LTTextRelease(_frames);
	LTTextRelease(_attributedString);
	LTTextCFRelease(_framesetter);
	if (_backgroundColor) CGColorRelease(_backgroundColor);
	[super dealloc];
}

#pragma mark -

-(NSUInteger)columnCountAtPageIndex:(NSUInteger)index
{
    return ((NSArray*)[_frames objectAtIndex:index]).count;
}

- (NSRange)rangeOfStringAtPageIndex:(NSUInteger)index column:(NSUInteger)col
{
    LTTextFrame* textFrame = [[_frames objectAtIndex:index] objectAtIndex:col];
	CTFrameRef frame = (CTFrameRef)textFrame.frame;
	CFRange range = CTFrameGetVisibleStringRange(frame);
	
	return NSMakeRange(range.location, range.length);
}

-(NSUInteger)pageIndexOfStringIndex:(NSUInteger)index columnIndex:(NSUInteger*)col
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
	
	if (index+1 > [_attributedString length]) {
		return NSNotFound; // out of index bounds
	}
	
	NSUInteger count = 0;    
    for (NSUInteger pi = 0; pi < _frames.count; pi++) {
        NSArray* cols = [_frames objectAtIndex:pi];
        for (NSUInteger ci = 0; ci < cols.count; ci++) {
            LTTextFrame* textFrame = [cols objectAtIndex:ci];
            CTFrameRef frame = (CTFrameRef)textFrame.frame;
            count += CTFrameGetVisibleStringRange((CTFrameRef)frame).length;
            if (count > index) {
                if (col) {
                    *col = ci;
                }
                return pi;
            }
        }
    }
	
	return 0;
}

#pragma mark - Layout

- (CGSize)_columnSize
{
    CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
    
    if (_verticalText) {
        CGFloat height = contentFrame.size.height;
        height -= _columnSpace*(_columnCount-1);
        height = floorf(height/(CGFloat)_columnCount);
        return CGSizeMake(contentFrame.size.width, height);
    }
    
    CGFloat width = contentFrame.size.width;
    width -= _columnSpace*(_columnCount-1);
    width = floorf(width/(CGFloat)_columnCount);
    return CGSizeMake(width, contentFrame.size.height);
}

- (CGRect)_columnFrameWithColumn:(NSUInteger)col
{
	CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
    
    if (_verticalText) {
        CGFloat height = [self _columnSize].height;
        
        contentFrame.size.height = height;
        contentFrame = CGRectOffset(contentFrame, 0 , height*col + _columnSpace*col);
        return contentFrame;
    }
    
    CGFloat width = [self _columnSize].width;
    
    contentFrame.size.width = width;
    contentFrame = CGRectOffset(contentFrame, width*col + _columnSpace*col , 0);
	return contentFrame;
}



- (void)_layoutFrame
{
	_needFrameLayout = NO;
	LTTextRelease(_frames);
	_frames = [[NSMutableArray alloc] init];
    
    CFMutableDictionaryRef frameAttr = CFDictionaryCreateMutable(NULL, 2, NULL, NULL);
    
	if (_verticalText) {
        // Don't use, this option has critical bug
        //CFDictionarySetValue(frameAttr, kCTFrameProgressionAttributeName, (CFTypeRef)[NSNumber numberWithInt:kCTFrameProgressionRightToLeft]);
    }
	
	CFIndex length = CFAttributedStringGetLength((CFAttributedStringRef)_attributedString);
	CFRange strRange = CFRangeMake(0, 0);
	
	NSMutableArray* currentFrames = [NSMutableArray array];
	for (; ; ) {
        
		CGRect contentFrame = [self _columnFrameWithColumn:currentFrames.count];
        
        NSLog(@"page:%d, col:%d, frame:%@", _frames.count, currentFrames.count, NSStringFromCGRect(contentFrame));
        
        CGPathRef path;
        if (_verticalText) {
            path = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, contentFrame.size.height, contentFrame.size.width)] CGPath];
        } else {
            path = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, contentFrame.size.width, contentFrame.size.height)] CGPath];
        }
		CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, strRange, path, frameAttr);
        
        LTTextFrame* textFrame = [[LTTextFrame alloc] init];
        textFrame.frame = (id)frame;
        textFrame.contentFrame = contentFrame;
		
        [currentFrames addObject:textFrame];
        [textFrame release];
		
        // current frame(columns) full, change to next page (and col=0)
        if ([currentFrames count] == _columnCount) {
            // Create new frame array
            [_frames addObject:currentFrames];
            currentFrames = [NSMutableArray array];
            //[currentFrames addObject:(id)frame];
        } else {
            //[currentFrames addObject:(id)frame];
        }
		
		//NSLog(@"frame %p, %@, image %d", frame, NSStringFromCGRect(CGPathGetBoundingBox(CTFrameGetPath(frame))), [[self _attachmentsWithCTFrame:frame] count]);
		
		CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
        CFRelease(frame);
        frame = NULL;
        
		if (visibleRange.length+visibleRange.location >= length) {
			break;
		}
		strRange.location = visibleRange.location+visibleRange.length;
	}
    
    CFRelease(frameAttr);
	
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


-(void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    _needFrameLayout = YES;
}

-(void)setColumnCount:(NSUInteger)columnCount
{
    if (columnCount == 0) {
        columnCount = 1;
    }
    _columnCount = columnCount;
    _needFrameLayout = YES;
}

-(void)setColumnSpace:(CGFloat)columnSpace
{
    if (columnSpace < 0) {
        columnSpace = 0;
    }
    _columnSpace = columnSpace;
    _needFrameLayout = YES;
}

-(void)setVerticalText:(BOOL)verticalText
{
    _verticalText = verticalText;
    _needFrameLayout = YES;
}

-(void)setJustifyThreshold:(float)aJustifyThreshold
{
    if (aJustifyThreshold < 0.1 || aJustifyThreshold > 1.0) {
        aJustifyThreshold = 1.0;
    }
    justifyThreshold = aJustifyThreshold;
}

-(void)layoutIfNeeded
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
}


- (void)_lt_frameDraw:(CGContextRef)context pathBBox:(CGRect)pathBBox lines:(CFArrayRef)lines lineOrigin:(CGPoint *)lineOrigin
{
    LTTextLogInfo(@"using %s", __FUNCTION__);
    
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
                    // TODO: justify with hyphenation
                } else {
                    CTLineDraw(line, context);
                }
            }
        } else {
            if (_verticalText) {
                if (justifyThreshold != 1.0 && lineBounds.size.width >= pathBBox.size.height*justifyThreshold) {
                    CTLineRef justLine = CTLineCreateJustifiedLine(line, 1.0, pathBBox.size.height);
                    CTLineDraw(justLine, context);
                    CFRelease(justLine);
                } else {
                    CTLineDraw(line, context);
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
        }
        
        
        
        CGContextRestoreGState(context);
    }
}

- (CGAffineTransform)_transformForCurrentTextProgression
{
    if (!_verticalText) {
        return CGAffineTransformIdentity;
    }
    
    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformRotate(t, -M_PI_2);
    t = CGAffineTransformTranslate(t, -_frameSize.height, 0);
    
    return t;
}

-(void)drawInContext:(CGContextRef)context atPage:(NSUInteger)page
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
	
	if (page >= self.pageCount) {
		return;
	}
	
	
	NSArray* frames = [_frames objectAtIndex:page];

#if LTTextViewBackgroundColorDebug
    for (NSUInteger i = 0; i < [frames count]; i++) {
        CGContextSaveGState(context);
        LTTextFrame* textFrame = [frames objectAtIndex:i];
        CGRect pathBBox = textFrame.contentFrame;
        CGContextTranslateCTM(context, pathBBox.origin.x, _frameSize.height-pathBBox.origin.y-pathBBox.size.height);
        CGContextSetFillColorWithColor(context, [[UIColor yellowColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, pathBBox.size.width, pathBBox.size.height));
        CGContextRestoreGState(context);
    }
#endif
    
	for (NSUInteger i = 0; i < [frames count]; i++) {
		
        LTTextFrame* textFrame = [frames objectAtIndex:i];
		CTFrameRef frame = (CTFrameRef)textFrame.frame;
		CFArrayRef lines = CTFrameGetLines(frame);
		CGPoint* lineOrigin = malloc(CFArrayGetCount(lines)*sizeof(CGPoint));
		CTFrameGetLineOrigins(frame, CFRangeMake(0, CFArrayGetCount(lines)), lineOrigin);
		CGRect pathBBox = textFrame.contentFrame;
        
		CGContextSaveGState(context);
        
        if (_verticalText) {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -_frameSize.height, 0);
            CGContextTranslateCTM(context, pathBBox.origin.y, pathBBox.origin.x);
        } else {
            CGContextTranslateCTM(context, pathBBox.origin.x, _frameSize.height-pathBBox.origin.y-pathBBox.size.height);
        }
		
        if (useHyphenation || justifyThreshold != 1.0) {
            [self _lt_frameDraw:context pathBBox:pathBBox lines:lines lineOrigin:lineOrigin];
        } else {
            CTFrameDraw(frame, context);
        }
		
		/*CGRect imageFrame = [self imageFrameAtPageIndex:page column:i];
         NSArray* attachments = [[_attachments objectAtIndex:page] objectAtIndex:i];
         for (NSDictionary* dict in attachments) {
         NSLog(@"%@", dict);
         CGPoint p = [[dict objectForKey:@"position"] CGPointValue];
         CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
         CGContextMoveToPoint(context, p.x-5.0, roundf(p.y)+0.5);
         CGContextAddLineToPoint(context, p.x-imageFrame.size.width-_columnSpace, roundf(p.y)+0.5);
         CGContextStrokePath(context);
         //CGContextFillRect(context, CGRectMake(p.x, p.y, 10, 10));
         }*/
		
		
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
    
    CGAffineTransform t = [self _transformForCurrentTextProgression];
	
	CFArrayRef lines = CTFrameGetLines(frame);
	for (CFIndex i = 0; i < CFArrayGetCount(lines); i++) {
		CTLineRef line = CFArrayGetValueAtIndex(lines, i);
		CFArrayRef runs = CTLineGetGlyphRuns(line);
		for (CFIndex ri = 0; ri < CFArrayGetCount(runs); ri++) {
			CTRunRef run = CFArrayGetValueAtIndex(runs, ri);
			CFDictionaryRef attr = CTRunGetAttributes(run);
			if (CFDictionaryGetValue(attr, kCTRunDelegateAttributeName)) {
                
                //[dst addObject:(id)attr];
                
				/*DTTextAttachment* attachment = [(id)attr objectForKey:@"DTTextAttachment"];
                 
                 // Fix Image URL
                 if (attachment.contentType == DTTextAttachmentTypeImage) {
                 if ([attachment.contentURL host].length == 0) {
                 NSURL* fixedURL = [NSURL URLWithString:[attachment.contentURL absoluteString] relativeToURL:self.originalURL];
                 //NSLog(@"not full url: %@ ,fixed %@", attachment.contentURL, [fixedURL absoluteURL]);
                 attachment.contentURL = fixedURL;
                 }
                 }
                 */
                
                const CGSize* adv = CTRunGetAdvancesPtr(run);
                
                 CGPoint p;
                 CTFrameGetLineOrigins(frame, CFRangeMake(i, 1), &p);
                //p = CGPointApplyAffineTransform(p, t);
                 float ascent;
                 CTLineGetTypographicBounds(line, &ascent, NULL, NULL);
                if (_verticalText) {
                    //p.y += ascent;
                    p = CGPointApplyAffineTransform(p, t);
                } else {
                    p.y += ascent;
                }
                
                 NSLog(@"%d: line:%p count: %ld, ascent:%f, %@, p:%@", _verticalText, line, CTLineGetStringRange(line).length, ascent, NSStringFromCGSize(adv[0]), NSStringFromCGPoint(p) );
                 //NSLog(@"line:%p, %@", line, NSStringFromCGPoint(p));
                
                CGRect attachFrame;
                if (_verticalText) {
                    attachFrame = CGRectMake(p.x, _frameSize.height - p.y, ascent, adv[0].width);
                } else {
                    attachFrame = CGRectMake(p.x, (height - p.y), adv[0].width, ascent);
                }
                
                //attachFrame = CGRectApplyAffineTransform(attachFrame, t);
                
                 NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:(id)attr
                 ,@"attributes"
                 ,[NSValue valueWithCGPoint:p]
                 ,@"position"
                 ,[NSValue valueWithCGRect: attachFrame]
                 ,@"frame",nil];
                 [dst addObject:dict];
                
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
		for (LTTextFrame* frame in frames) {
			NSMutableArray* dstArrayFrame = [NSMutableArray array];
			[self _storeFrameOfAttachment:(CTFrameRef)frame.frame to:dstArrayFrame];
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

-(NSArray *)attachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col
{
    if (_needFrameLayout) {
        [self _layoutFrame];
    }
    
    return [[[[_attachments objectAtIndex:index] objectAtIndex:col] copy] autorelease];
    
	/*NSArray* frames = [_frames objectAtIndex:index];
	if ([frames count] <= col) {
		return nil;
	}
	return [self _attachmentsWithCTFrame:(CTFrameRef)[frames objectAtIndex:col]];
     */
}


@end
