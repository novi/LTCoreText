//
//  LTTextLayouter.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/07/07.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
// 

#import "LTTextLayouter.h"


@interface LTTextFrame : NSObject
{
    id _frame;
    CGPoint* _lineOrigins;
}

@property (nonatomic, retain) id frame;
@property (nonatomic) CGRect contentFrame;
@property (nonatomic) CGRect frameBounds; // frame path
@property (nonatomic) CGPoint* lineOrigins;
@property (nonatomic) BOOL verticalLayout;

- (NSUInteger)indexOfLine:(CTLineRef)line;


@end

@implementation LTTextFrame

@synthesize frame = _frame, contentFrame;
@synthesize lineOrigins = _lineOrigins;
@synthesize frameBounds;
@synthesize verticalLayout;

-(NSUInteger)indexOfLine:(CTLineRef)line
{
    NSArray* lines = (NSArray*)CTFrameGetLines((CTFrameRef)_frame);
    return [lines indexOfObjectIdenticalTo:(id)line];
}

-(void)setFrame:(id)frame
{
    if (_frame != frame) {
        LTTextRelease(_frame);
        _frame = [frame retain];
    }
    
    if (_lineOrigins) {
        free(_lineOrigins);
        _lineOrigins = NULL;
    }
    
    if (!frame) {
        return;
    }
    
    CFArrayRef lines = CTFrameGetLines((CTFrameRef)_frame);
    _lineOrigins = malloc(sizeof(CGPoint)*CFArrayGetCount(lines));
    CTFrameGetLineOrigins((CTFrameRef)_frame, CFRangeMake(0, CFArrayGetCount(lines)), _lineOrigins);
}

- (NSArray*)linesWithRange:(NSRange)range
{
    NSArray* lines = (NSArray*)CTFrameGetLines((CTFrameRef)_frame);
    NSMutableArray* dst = [NSMutableArray arrayWithCapacity:lines.count];
    
    for (id line in lines) {
        CFRange cfrange = CTLineGetStringRange((CTLineRef)line);
        NSRange lineRange = NSMakeRange(cfrange.location, cfrange.length);
        if (NSLocationInRange(range.location, lineRange) || NSLocationInRange(range.location+range.length-1, lineRange)) {
            //NSLog(@"added: %@", [_attributedString.string substringWithRange:lineRange]);
            [dst addObject:(id)line];
        } else {
            //NSLog(@"skipped: %@", [_attributedString.string substringWithRange:lineRange]);
        }
    }
    
    return dst;
}

- (NSArray *)glyphRunsWithRange:(NSRange)range onLine:(CTLineRef)line
{
    NSArray* runs = (NSArray*)CTLineGetGlyphRuns(line);
    NSMutableArray* dst = [NSMutableArray arrayWithCapacity:runs.count];
    
    for (id runObj in runs) {
        CTRunRef run = (CTRunRef)runObj;
        CFRange cfrange = CTRunGetStringRange(run);
        NSRange runRange = NSMakeRange(cfrange.location, cfrange.length);
        if (NSLocationInRange(runRange.location, range)) {
            [dst addObject:(id)run];
        }
    }
    
    return dst;
}

// the rect's origin is on frameBounds, not include layouter's content inset
- (CGRect)frameWithGlyphRuns:(NSArray*)runs onLine:(CTLineRef)line
{
    if (runs.count == 0) {
        return CGRectZero;
    }
    
    CGRect rect = CGRectZero;
    
    NSUInteger lineIndex = [self indexOfLine:line];
    if (lineIndex == NSNotFound) {
        return CGRectZero;
    }
    
    CGPoint lineOrigin = self.lineOrigins[lineIndex];
    
    //NSLog(@"%s, lineOrigin, %@", __func__, NSStringFromCGPoint(lineOrigin) );
    
    for (id runObj in runs) {
        
        CGRect runFrame;
        CGFloat ascent = 0;
        CGFloat descent = 0;
        CGFloat leading = 0;
        CGFloat width = (CGFloat)CTRunGetTypographicBounds((CTRunRef)runObj, CFRangeMake(0, 0), &ascent, &descent, &leading);
        CGPoint p;
        
        /*for (int i = 0; i < CTRunGetGlyphCount(runObj); i++) {
            CTRunGetPositions(runObj, CFRangeMake(i, 1), &p);
            NSLog(@"%d---%@", i, NSStringFromCGPoint(p));
        }*/
        
        CTRunGetPositions((CTRunRef)runObj, CFRangeMake(0, 1), &p);
        
        CFDictionaryRef attr = CTRunGetAttributes((CTRunRef)runObj);
        CGFloat xoffs = p.x;
        NSNumber* vf = (id)CFDictionaryGetValue(attr, kCTVerticalFormsAttributeName);
        if (vf && [vf boolValue]) {
            xoffs = -p.y - leading - descent;
        }
        
        // convert bottom-left origins to top-left
        runFrame = CGRectMake(lineOrigin.x + xoffs, self.frameBounds.size.height - lineOrigin.y -ascent, width, ascent+descent);
    
        runFrame = CGRectStandardize(runFrame);
        
        if (CGRectEqualToRect(CGRectZero, rect)) {
            rect = runFrame;
        } else {
            rect = CGRectUnion(rect, runFrame);
        }
    }
    
    return rect;
}

- (NSArray*)framesWithRange:(NSRange)range
{
    NSArray* lines = [self linesWithRange:range];
    if (lines.count == 0) {
        return [NSArray array];
    }
    
    NSMutableArray* dst = [NSMutableArray arrayWithCapacity:2];
    
    for (id lineObj in lines) {
        NSArray* runs = [self glyphRunsWithRange:range onLine:(CTLineRef)lineObj];
        CGRect frame = [self frameWithGlyphRuns:runs onLine:(CTLineRef)lineObj];
        if ( !CGRectIsEmpty(frame)) {
            [dst addObject:[NSValue valueWithCGRect:frame]];
        }
    }
    
    return dst;
}

- (void)dealloc
{
    if (_lineOrigins) {
        free(_lineOrigins);
        _lineOrigins = NULL;
    }
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

- (CGRect)columnFrameWithColumn:(NSUInteger)col
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
        
		CGRect contentFrame = [self columnFrameWithColumn:currentFrames.count];
        
        NSLog(@"page:%d, col:%d, frame:%@", _frames.count, currentFrames.count, NSStringFromCGRect(contentFrame));
        
        CGPathRef path;
        CGRect frameBounds;
        if (_verticalText) {
            frameBounds = CGRectMake(0, 0, contentFrame.size.height, contentFrame.size.width);
            path = [[UIBezierPath bezierPathWithRect:frameBounds] CGPath];
        } else {
            frameBounds = CGRectMake(0, 0, contentFrame.size.width, contentFrame.size.height);
            path = [[UIBezierPath bezierPathWithRect:frameBounds] CGPath];
        }
		CTFrameRef frame = CTFramesetterCreateFrame(_framesetter, strRange, path, frameAttr);
        
        LTTextFrame* textFrame = [[LTTextFrame alloc] init];
        textFrame.frame = (id)frame;
        textFrame.contentFrame = contentFrame;
        textFrame.frameBounds = frameBounds;
        textFrame.verticalLayout = _verticalText;
		
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

-(void)layoutIfNeeded
{
	if (_needFrameLayout) {
		[self _layoutFrame];
	}
}


#pragma mark - Accessory Method

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



#pragma mark - Drawing

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
                    if (justLine) {
                        CTLineDraw(justLine, context);
                        CFRelease(justLine);
                    } else {
                        CTLineDraw(line, context);
                    }
                } else {
                    CTLineDraw(line, context);
                }
            } else {
                if (justifyThreshold != 1.0 && lineBounds.size.width >= pathBBox.size.width*justifyThreshold) {
                    CTLineRef justLine = CTLineCreateJustifiedLine(line, 1.0, pathBBox.size.width);
                    if (justLine) {
                        CTLineDraw(justLine, context);
                        CFRelease(justLine);
                    } else {
                        CTLineDraw(line, context);
                    }
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
    
    CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
    
    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformTranslate(t, contentFrame.size.width, 0);
    t = CGAffineTransformRotate(t, M_PI_2);
    
    return t;
}

- (CGRect)_convertFrameForCurrentTextProgression:(CGRect)frame
{
    if (_verticalText) {
        frame = CGRectApplyAffineTransform(frame, [self _transformForCurrentTextProgression]);
        return frame;
    } else {
        return frame;
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
            [self _lt_frameDraw:context pathBBox:pathBBox lines:lines lineOrigin:textFrame.lineOrigins];
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
	}
	
}

#pragma mark - Attachments

- (void)_storeFrameOfAttachment:(LTTextFrame*)frame to:(NSMutableArray*)dst
{
	/*CGRect contentFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, _frameSize.width, _frameSize.height), _contentInset);
	CGFloat height = contentFrame.size.height;
    
    CGAffineTransform t = [self _transformForCurrentTextProgression];
	*/
	CFArrayRef lines = CTFrameGetLines((CTFrameRef)frame.frame);
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
                CGRect attachFrame;
                /*
                const CGSize* adv = CTRunGetAdvancesPtr(run);
                
                CGPoint p;
                CTFrameGetLineOrigins(frame.frame, CFRangeMake(i, 1), &p);
                //p = CGPointApplyAffineTransform(p, t);
                float ascent;
                CTLineGetTypographicBounds(line, &ascent, NULL, NULL);
                p.y += ascent;
                if (_verticalText) {
                    //p.y += ascent;
                    //p = CGPointApplyAffineTransform(p, t);
                } else {
                    //p.y += ascent;
                }
                
                NSLog(@"%d: line:%p count: %ld, ascent:%f, %@, p:%@", _verticalText, line, CTLineGetStringRange(line).length, ascent, NSStringFromCGSize(adv[0]), NSStringFromCGPoint(p) );
                //NSLog(@"line:%p, %@", line, NSStringFromCGPoint(p));
                
                
                if (_verticalText) {
                    //attachFrame = CGRectMake(p.x, _frameSize.height - p.y, ascent, adv[0].width);
                    attachFrame = CGRectMake(p.x, (height - p.y), adv[0].width, ascent);
                    attachFrame = CGRectApplyAffineTransform(attachFrame, t);
                } else {
                    attachFrame = CGRectMake(p.x, (height - p.y), adv[0].width, ascent);
                }
                */
                
                attachFrame = [self _convertFrameForCurrentTextProgression: [frame frameWithGlyphRuns:[NSArray arrayWithObject:(id)run] onLine:line] ];
                //attachFrame = CGRectApplyAffineTransform(attachFrame, t);
                
                
                
                NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:(id)attr
                                      ,@"attributes"
                                      ,[NSValue valueWithCGRect:attachFrame ]
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
			[self _storeFrameOfAttachment:frame to:dstArrayFrame];
			[dstarrayPage addObject:dstArrayFrame];
		}
	}
}


-(NSArray *)attachmentsAtPageIndex:(NSUInteger)index column:(NSUInteger)col
{
    if (_needFrameLayout) {
        [self _layoutFrame];
    }
    
    return [[[[_attachments objectAtIndex:index] objectAtIndex:col] copy] autorelease];
}

#pragma mark - Custom Attributes







- (NSArray*)allValueForAttribute:(NSString*)attrKey atPageIndex:(NSUInteger)index column:(NSUInteger)col
{
    LTTextFrame* textFrame = [[_frames objectAtIndex:index] objectAtIndex:col];
    NSRange colRange = [self rangeOfStringAtPageIndex:index column:col];
    NSMutableArray* dst = [NSMutableArray array];

    NSLog(@"page %d, col %d, key :%@-----%@", index, col, attrKey, NSStringFromRange(colRange));
    [_attributedString enumerateAttribute:attrKey inRange:colRange options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            //NSRange fixedRange = range;
            //fixedRange.location += colRange.location;
            /*NSLog(@"%@: %@ - %@(%@)", @"", value, NSStringFromRange(range), NSStringFromRange(colRange));
            NSArray* runs = [textFrame glyphRunsWithRange:range onLine:[[textFrame linesWithRange:range] lastObject]];
            NSLog(@"---- %@\n", [_attributedString.string substringWithRange:fixedRange]);
            for (id runObj in runs) {
                CFRange range = CTRunGetStringRange((CTRunRef) runObj);
                NSLog(@"----      %@", [_attributedString.string substringWithRange:NSMakeRange(range.location, range.length)]);
            }*/
            NSArray* frames = [textFrame framesWithRange:range];
            for (NSValue* frameObj in frames) {
                CGRect f = [frameObj CGRectValue];
                
                //[dst addObject:[NSValue valueWithCGRect:f]]; // original frame
                f = [self _convertFrameForCurrentTextProgression:f];
                
                // convert frame to page view's coordinate
                CGRect colFrame = [self columnFrameWithColumn:col];
                f = CGRectOffset(f, colFrame.origin.x, colFrame.origin.y);
                [dst addObject:[NSValue valueWithCGRect:f]];
            }
        }

    }];
    
    return dst;
}


@end
