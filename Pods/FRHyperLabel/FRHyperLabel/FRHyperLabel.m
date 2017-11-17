//
//  FRHyperLabel.m
//  FRHyperLabelDemo
//
//  Created by Jinghan Wang on 23/9/15.
//  Copyright © 2015 JW. All rights reserved.
//

#import "FRHyperLabel.h"
#import <CoreText/CoreText.h>

@interface FRHyperLabel ()

@property (nonatomic) NSMutableDictionary *handlerDictionary;
@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic) NSTextContainer *textContainer;
@property (nonatomic) NSAttributedString *backupAttributedText;
@property (nonatomic) CGRect boundingBox;

@end

@implementation FRHyperLabel

static CGFloat highLightAnimationTime = 0.15;
static UIColor *FRHyperLabelLinkColorDefault;
static UIColor *FRHyperLabelLinkColorHighlight;

+ (void)initialize {
	if (self == [FRHyperLabel class]) {
		FRHyperLabelLinkColorDefault = [UIColor colorWithRed:28/255.0 green:135/255.0 blue:199/255.0 alpha:1];
		FRHyperLabelLinkColorHighlight = [UIColor colorWithRed:242/255.0 green:183/255.0 blue:73/255.0 alpha:1];
	}
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self checkInitialization];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self checkInitialization];
	}
	return self;
}

- (void)checkInitialization {
	if (!self.handlerDictionary) {
		self.handlerDictionary = [NSMutableDictionary new];
	}
	
	if (!self.userInteractionEnabled) {
		self.userInteractionEnabled = YES;
	}
	
	if (!self.linkAttributeDefault) {
		self.linkAttributeDefault = @{NSForegroundColorAttributeName: FRHyperLabelLinkColorDefault,
									  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
	}
	
	if (!self.linkAttributeHighlight) {
		self.linkAttributeHighlight = @{NSForegroundColorAttributeName: FRHyperLabelLinkColorHighlight,
										NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
	}
}

#pragma mark - APIs

- (void)clearActionDictionary {
    [self.handlerDictionary removeAllObjects];
}

//designated setter
- (void)setLinkForRange:(NSRange)range withAttributes:(NSDictionary *)attributes andLinkHandler:(void (^)(FRHyperLabel *label, NSRange selectedRange))handler {
	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
	
	if (attributes) {
		[mutableAttributedString addAttributes:attributes range:range];
	}
	
	if (handler) {
		[self.handlerDictionary setObject:handler forKey:[NSValue valueWithRange:range]];
	}
	
	self.attributedText = mutableAttributedString;
}

- (void)setLinkForRange:(NSRange)range withLinkHandler:(void(^)(FRHyperLabel *label, NSRange selectedRange))handler {
	[self setLinkForRange:range withAttributes:self.linkAttributeDefault andLinkHandler:handler];
}

- (void)setLinkForSubstring:(NSString *)substring withAttribute:(NSDictionary *)attribute andLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler {
	NSRange range = [self.attributedText.string rangeOfString:substring];
	if (range.length) {
		[self setLinkForRange:range withAttributes:attribute andLinkHandler:^(FRHyperLabel *label, NSRange range){
			handler(label, [label.attributedText.string substringWithRange:range]);
		}];
	}
}

- (void)setLinkForSubstring:(NSString *)substring withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler {
	[self setLinkForSubstring:substring withAttribute:self.linkAttributeDefault andLinkHandler:handler];
}

- (void)setLinksForSubstrings:(NSArray *)linkStrings withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler {
	for (NSString *linkString in linkStrings) {
		[self setLinkForSubstring:linkString withLinkHandler:handler];
	}
}

#pragma mark - Event Handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	self.backupAttributedText = self.attributedText;
	for (UITouch *touch in touches) {
		CGPoint touchPoint = [touch locationInView:self];
		NSValue *rangeValue = [self attributedTextRangeForPoint:touchPoint];
		if (rangeValue) {
			NSRange range = [rangeValue rangeValue];
			NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
			[attributedString addAttributes:self.linkAttributeHighlight range:range];
			
			[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
				self.attributedText = attributedString;
			} completion:nil];
			return;
		}
	}
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.attributedText = self.backupAttributedText;
	} completion:nil];
	[super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.attributedText = self.backupAttributedText;
	} completion:nil];
	
	for (UITouch *touch in touches) {
		NSValue *rangeValue = [self attributedTextRangeForPoint:[touch locationInView:self]];
		if (rangeValue) {
			void(^handler)(FRHyperLabel *label, NSRange selectedRange) = self.handlerDictionary[rangeValue];
			handler(self, [rangeValue rangeValue]);
			return;
		}
	}
	[super touchesEnded:touches withEvent:event];
}

#pragma mark - Substring Locator

- (NSInteger) characterIndexForPoint:(CGPoint) point {
	
    // init text storage
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // init text container
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, self.frame.size.height) ];
    textContainer.lineFragmentPadding  = 0;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.lineBreakMode        = self.lineBreakMode;
    
    [layoutManager addTextContainer:textContainer];

    CGFloat result = 0;
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:point
                                                      inTextContainer:textContainer
                             fractionOfDistanceBetweenInsertionPoints:&result];
    
    return (NSInteger)characterIndex;
}

- (NSValue *)attributedTextRangeForPoint:(CGPoint)point {

	NSInteger indexOfCharacter = [self characterIndexForPoint:point];
	
	for (NSValue *rangeValue in self.handlerDictionary) {
		NSRange range = [rangeValue rangeValue];
		if (NSLocationInRange(indexOfCharacter, range)) {
			return rangeValue;
		}
	}

	return nil;
}

- (CGRect)attributedTextBoundingBox {
	if (CGRectGetWidth(_boundingBox) != 0) {
		return _boundingBox;
	}
	
	NSLayoutManager *layoutManager = [NSLayoutManager new];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
	
	textContainer.lineFragmentPadding = 0.0;
	textContainer.lineBreakMode = self.lineBreakMode;
	textContainer.maximumNumberOfLines = self.numberOfLines;
	textContainer.size = self.bounds.size;
	[layoutManager addTextContainer:textContainer];
	
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
	[textStorage addLayoutManager:layoutManager];
	
	CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
	
	
	CGFloat H = 0;
	
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (CFMutableAttributedStringRef) self.attributedText);
	CGRect box = CGRectMake(0,0, CGRectGetWidth(textBoundingBox), CGFLOAT_MAX);
	CFIndex startIndex = 0;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, box);
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, NULL);
	
	CFArrayRef lineArray = CTFrameGetLines(frame);
	CFIndex j = 0;
	CFIndex lineCount = CFArrayGetCount(lineArray);
	if (lineCount > self.numberOfLines && self.numberOfLines != 0) {
		lineCount = self.numberOfLines;
	}
	
	CGFloat h, ascent, descent, leading;
	
	for (j = 0; j < lineCount; j++) {
		CTLineRef currentLine = (CTLineRef)CFArrayGetValueAtIndex(lineArray, j);
		CTLineGetTypographicBounds(currentLine, &ascent, &descent, &leading);
		h = ascent + descent + leading;
		H += h;
	}
	
	CFRelease(frame);
	CFRelease(path);
	CFRelease(framesetter);
	
	box.size.height = H;
	
	_boundingBox = box;
	
	return box;
}


@end
