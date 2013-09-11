//
//  CoreTextHelpers.mm
//  Wheel
//
//  Created by Daniel Eggert on 12/31/12.
//  Copyright (c) 2012 Bödewadt. All rights reserved.
//

#import "CoreTextHelpers.h"

#import "CoreGraphicsHelpers.h"
#import <UIKit/UIKit.h>



CTFontRef __CTFont::createFont(UIFont *uiFont)
{
    return CTFontCreateWithName((__bridge CFStringRef) uiFont.fontName, uiFont.pointSize, NULL);
}


#pragma mark - ParagraphStyleSettings

CTH::ParagraphStyleSettings::ParagraphStyleSettings(void)
{
    CTParagraphStyleRef s = CTParagraphStyleCreate(NULL, 0);
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierAlignment, (int8_t *) &alignment);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierFirstLineHeadIndent, &firstLineHeadIndent);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierHeadIndent, &headIndent);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierTailIndent, &tailIndent);
    id stops = nil;
    s->getObjectForSpecifier(kCTParagraphStyleSpecifierTabStops, &stops);
    tabStops = stops;
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierLineBreakMode, (int8_t *) &lineBreakMode);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierMaximumLineHeight, &maximumLineHeight);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierMinimumLineHeight, &minimumLineHeight);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierParagraphSpacingBefore, &paragraphSpacingBefore);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierParagraphSpacing, &paragraphSpacing);
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierLineBoundsOptions, (int8_t *) &lineBoundsOptions);
    s->release();
}

CTH::ParagraphStyleSettings::ParagraphStyleSettings(NSParagraphStyle *other)
{
    alignment = NSTextAlignmentToCTTextAlignment(other.alignment);
    firstLineHeadIndent = other.firstLineHeadIndent;
    headIndent = other.headIndent;
    tailIndent = other.tailIndent;
    tabStops = nil; // UIKit doesn't support tab stops
    lineBreakMode = (CTLineBreakMode) other.lineBreakMode;
    maximumLineHeight = other.maximumLineHeight;
    minimumLineHeight = other.minimumLineHeight;
    paragraphSpacingBefore = other.paragraphSpacing;
    paragraphSpacing = other.paragraphSpacing;
    lineBoundsOptions = 0; // default
}

CTH::ParagraphStyleSettings::ParagraphStyleSettings(id paragraphStyle)
{
    CTParagraphStyleRef s = (__bridge CTParagraphStyleRef) paragraphStyle;
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierAlignment, (int8_t *) &alignment);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierFirstLineHeadIndent, &firstLineHeadIndent);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierHeadIndent, &headIndent);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierTailIndent, &tailIndent);
    id stops = nil;
    s->getObjectForSpecifier(kCTParagraphStyleSpecifierTabStops, &stops);
    tabStops = stops;
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierLineBreakMode, (int8_t *) &lineBreakMode);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierMaximumLineHeight, &maximumLineHeight);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierMinimumLineHeight, &minimumLineHeight);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierParagraphSpacingBefore, &paragraphSpacingBefore);
    s->getFloatValueForSpecifier(kCTParagraphStyleSpecifierParagraphSpacing, &paragraphSpacing);
    s->getInt8ValueForSpecifier(kCTParagraphStyleSpecifierLineBoundsOptions, (int8_t *) &lineBoundsOptions);
}

CTParagraphStyleRef CTH::ParagraphStyleSettings::createParagraphStyle(void) const
{
    CTParagraphStyleSetting const s[] = {
        {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
        {kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineHeadIndent), &firstLineHeadIndent},
        {kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent},
        {kCTParagraphStyleSpecifierTailIndent, sizeof(tailIndent), &tailIndent},
        {kCTParagraphStyleSpecifierTabStops, sizeof(tabStops), &tabStops},
        {kCTParagraphStyleSpecifierLineBreakMode, sizeof(lineBreakMode), &lineBreakMode},
        {kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight},
        {kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minimumLineHeight), &minimumLineHeight},
        {kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paragraphSpacingBefore), &paragraphSpacingBefore},
        {kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing},
        {kCTParagraphStyleSpecifierLineBoundsOptions, sizeof(lineBoundsOptions), &lineBoundsOptions},
    };
    
    return CTParagraphStyleCreate(s, sizeof(s) / sizeof(*s));
}

id CTH::ParagraphStyleSettings::paragraphStyle(void) const
{
    return CFBridgingRelease(createParagraphStyle());
}

void CTH::ParagraphStyleSettings::setTabStops(std::initializer_list<CGFloat> locations)
{
    NSMutableArray *stops = [NSMutableArray array];
    std::for_each(locations.begin(), locations.end(), [&](CGFloat const &location){
        CTTextTabRef t = CTTextTabCreate(kCTTextAlignmentLeft, location, NULL);
        [stops addObject:CFBridgingRelease(t)];
    });
    tabStops = stops;
}

void CTH::ParagraphStyleSettings::setCenteredTabStops(std::initializer_list<CGFloat> locations)
{
    NSMutableArray *stops = [NSMutableArray array];
    std::for_each(locations.begin(), locations.end(), [&](CGFloat const &location){
        CTTextTabRef t = CTTextTabCreate(kCTTextAlignmentCenter, location, NULL);
        [stops addObject:CFBridgingRelease(t)];
    });
    tabStops = stops;
}

#pragma mark -

CTH::Frame::Frame(void) :
_typesetter(NULL), _bounds(CGRectZero), _lines(nil)
{}

CTH::Frame::Frame(Frame const &other) :
_typesetter(other._typesetter), _bounds(other._bounds), _lines([other._lines copy]), _origins(other._origins), _lineRanges(other._lineRanges)
{
    if (_typesetter != NULL) {
        CFRetain(_typesetter);
    }
}

CTH::Frame::Frame(NSAttributedString *text, CGRect bounds) :
_typesetter(CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef) text)), _bounds(bounds), _lines(nil)
{
    NSLocale *locale = [NSLocale currentLocale];
    
    double const hyphenationFactor = 0.9;
    CGFloat const width = CGRectGetWidth(bounds);
    
    NSMutableArray *lines = [NSMutableArray array];
    
    CGFloat const xOffset = CGRectGetMinX(_bounds);
    
    CGFloat yOffset = CGRectGetMaxY(bounds);
    CFIndex startIndex = 0;
    
    while ((NSUInteger) startIndex < [text length]) {
        CFIndex lineLength = CTTypesetterSuggestLineBreakWithOffset(_typesetter, startIndex, width, xOffset);
        CFIndex breakPos = startIndex + lineLength;
        CFRange lineRange = CFRangeMake(startIndex, breakPos - startIndex);
        
        CTLineRef line = CTTypesetterCreateLine(_typesetter, lineRange);
        double lineWidth = line->getTypographicWidth() - line->getTrailingWhitespaceWidth();
        
        BOOL shouldHyphenate = (lineWidth / width < hyphenationFactor);
        if (shouldHyphenate) {
            // Find a place to hyphenate:
            lineLength = CTTypesetterSuggestClusterBreakWithOffset(_typesetter, startIndex, width, xOffset);
            if (lineLength != lineRange.length) {
                CFIndex hyphBreakPos = startIndex + lineLength;
                CFRange hyphLineRange = CFRangeMake(startIndex, hyphBreakPos - startIndex);
                
                CFRange limitRange = CFRangeMake(startIndex, hyphBreakPos - startIndex);
                UTF32Char character = 0;
                hyphBreakPos = CFStringGetHyphenationLocationBeforeIndex((__bridge CFStringRef) text.string, hyphBreakPos, limitRange, 0, (__bridge CFLocaleRef) locale, &character);
                if (kCFNotFound != hyphBreakPos) {
                    hyphLineRange = CFRangeMake(startIndex, hyphBreakPos - startIndex);
                    
                    NSRange nsLineRange = NSMakeRange(hyphLineRange.location, hyphLineRange.length);
                    NSMutableAttributedString *lineText = [[text attributedSubstringFromRange:nsLineRange] mutableCopy];
                    unichar hyphenCharacter = (unichar) character;
                    [lineText.mutableString appendString:[NSString stringWithCharacters:&hyphenCharacter length:1]];
                    
                    line->release();
                    line = __CTLine::createWithAttributedString(lineText);
                    lineRange = hyphLineRange;
                    breakPos = hyphBreakPos;
                }
            }
        }
        
        [lines addObject:(__bridge id) line];
        _lineRanges.push_back(NSMakeRange(lineRange.location, lineRange.length));
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        (void) line->getTypographicBounds(ascent, descent, leading);
        CGPoint origin = CGPointMake(xOffset, yOffset - ascent);
        _origins.push_back(origin);
        
        leading = leadingForRange(lineRange, text);
        
        yOffset -= leading;
        startIndex = breakPos;
        line->release();
    }
    _lines = [lines copy];
}

CGFloat CTH::Frame::leadingForRange(CFRange const &textRange, NSAttributedString *text)
{
    __block BOOL isLastLine = NO;
    __block NSRange nextParagraphRange = {0, 0};
    {
        NSRange range = NSMakeRange(textRange.location, textRange.length);
        range.length = MIN(range.length + 1, [text length] - range.location);
        
        [[text string] enumerateSubstringsInRange:range options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            (void) substring;
            (void) substringRange;
            if (NSMaxRange(enclosingRange) == (NSUInteger) (textRange.location + textRange.length)) {
                isLastLine = YES;
            } else if ((NSUInteger) (textRange.location + textRange.length) <= enclosingRange.location) {
                nextParagraphRange = enclosingRange;
                *stop = YES;
            }
        }];
    }
    
    CTParagraphStyleRef style = (__bridge CTParagraphStyleRef) [text attribute:CTAttributeName::paragraphStyle() atIndex:textRange.location effectiveRange:NULL];
    CGFloat maximumLineHeight = 0;
    CTParagraphStyleGetValueForSpecifier(style, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight);
    if (! isLastLine) {
        return maximumLineHeight;
    }
    
    if (nextParagraphRange.length != 0) {
        CTParagraphStyleRef beforeStyle = (__bridge CTParagraphStyleRef) [text attribute:CTAttributeName::paragraphStyle() atIndex:nextParagraphRange.location effectiveRange:NULL];
        CGFloat paragraphSpacingBefore = 0;
        if (CTParagraphStyleGetValueForSpecifier(beforeStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paragraphSpacingBefore), &paragraphSpacingBefore)) {
            return paragraphSpacingBefore + maximumLineHeight;
        }
    }
    
    CGFloat paragraphSpacing = 0;
    if (CTParagraphStyleGetValueForSpecifier(style, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing)) {
        return paragraphSpacing + maximumLineHeight;
    }
    
    return maximumLineHeight;
}

CTH::Frame::~Frame(void)
{
    if (_typesetter != NULL) {
        CFRelease(_typesetter);
    }
    _lines = nil;
}

NSRange CTH::Frame::getStringRangeForPosition(CGPoint const &point) const
{
    __block NSRange stringRange = {NSNotFound, 0};
    [_lines enumerateObjectsUsingBlock:^(id aLine, NSUInteger idx, BOOL *stop) {
        (void) stop;
        CTLineRef const line = (__bridge CTLineRef) aLine;
        CGRect r = line->getBoundsWithOptions(kCTLineBoundsUseGlyphPathBounds);
        CGPoint origin = _origins[idx];
        r.origin.x += origin.x;
        r.origin.y += origin.y;
        if (CGRectContainsPoint(r, point)) {
            CGPoint relativePosition = point;
            relativePosition.x -= origin.x;
            relativePosition.y -= origin.y;
            NSInteger relativeIndex = -1;
            line->enumerateGlyphRuns([&](CTRunRef glyphRun, bool &lineStop){
                glyphRun->enumerateGlyphs([&](NSInteger stringIndex, CGRect glyphBounds, bool &runStop){
                    BOOL const pointInside = CGRectContainsPoint(glyphBounds, relativePosition);
                    if (pointInside) {
                        runStop = true;
                        lineStop = true;
                        NSRange lineRange = line->getStringRange();
                        relativeIndex = stringIndex - lineRange.location;
                    }
                });
            });
            if (0 <= relativeIndex) {
                *stop = YES;
                stringRange = NSMakeRange(_lineRanges[idx].location + relativeIndex, 1);
            }
        }
    }];
    return stringRange;
}

NSRange CTH::Frame::getStringRange(void) const
{
    return NSMakeRange(0, 0);
}

NSRange CTH::Frame::getVisibleStringRange(void) const
{
    return NSMakeRange(0, 0);
}

//NSArray *CTH::Frame::getLines(void) const
//{
//}
//
//NSArray *CTH::Frame::getLineOrigins(void) const
//{
//}

void CTH::Frame::draw(CGContextRef ctx)
{
    [_lines enumerateObjectsUsingBlock:^(id aLine, NSUInteger idx, BOOL *stop) {
        (void) stop;
        CTLineRef const line = (__bridge CTLineRef) aLine;
        ctx->setTextPosition(_origins.at(idx));
        line->draw(ctx);
    }];
}

NSString *CTH::Frame::description(void) const
{
    NSMutableArray *lineDescriptions = [NSMutableArray array];
    std::for_each(_origins.cbegin(), _origins.cend(), [&](CGPoint const &point){
        [lineDescriptions addObject:NSStringFromCGPoint(point)];
    });
    return [NSString stringWithFormat:@"CTH::Frame %u lines; origins = {%@}", (unsigned) [_lines count], [lineDescriptions componentsJoinedByString:@", "]];
}

#pragma mark -

void __CTLine::drawWithBaselineShifts(CGContextRef context) const
{
    NSArray *runs = this->getGlyphRuns();
    for (id run in runs) {
        CTRunRef ctRun = (__bridge CTRunRef) run;
        NSDictionary *attributes = (__bridge id) CTRunGetAttributes(ctRun);
        NSNumber *baselineShift = attributes[CTAttributeName::baselineShift()];
        if (baselineShift != nil) {
            context->translateCTM(0, [baselineShift floatValue]);
        }
        CTRunDraw(ctRun, context, CFRangeMake(0, 0));
        if (baselineShift != nil) {
            context->translateCTM(0, -[baselineShift floatValue]);
        }
    }
}

void __CTLine::enumerateGlyphRuns(std::function<void(CTRunRef run)> f) const
{
    NSArray *runs = this->getGlyphRuns();
    for (id run in runs) {
        CTRunRef ctRun = (__bridge CTRunRef) run;
        f(ctRun);
    }
}

void __CTLine::enumerateGlyphRuns(std::function<void(CTRunRef run, bool &stop)> f) const
{
    NSArray *runs = this->getGlyphRuns();
    bool stop = false;
    for (id run in runs) {
        CTRunRef ctRun = (__bridge CTRunRef) run;
        f(ctRun, stop);
        if (stop) {
            break;
        }
    }
}

void __CTRun::enumerateGlyphs(CGContextRef ctx, std::function<void(CGGlyph glyph, CGPoint position, CGSize advance)> f) const
{
    if (ctx != NULL) {
        NSDictionary *attributes = this->getAttributes();
        CTFontRef ctFont = (__bridge CTFontRef) attributes[CTAttributeName::font()];
        CGFontRef cgFont = ctFont->copyGraphicsFont();
        ctx->setFont(cgFont);
        CFRelease(cgFont);
        ctx->setFontSize(CTFontGetSize(ctFont));
        ctx->setFillColor((__bridge CGColorRef) attributes[CTAttributeName::foregroundColor()]);
    }
    for (CFIndex i = 0; i < this->getGlyphCount(); ++i) {
        CGGlyph glyph = this->getGlyph(i);
        CGPoint position = this->getPosition(i);
        CGSize advance = this->getAdvance(i);
        f(glyph, position, advance);
    }
}

void __CTRun::enumerateGlyphs(CGContextRef ctx, std::function<void(CGGlyph glyph, CGPoint position, CGRect glyphBounds)> f) const
{
    NSDictionary *attributes = this->getAttributes();
    CTFontRef ctFont = (__bridge CTFontRef) attributes[CTAttributeName::font()];
    
    size_t const glyphCount = this->getGlyphCount();
    CGRect boundingRects[glyphCount];
    CTFontGetOpticalBoundsForGlyphs(ctFont, CTRunGetGlyphsPtr(this), boundingRects, glyphCount, 0);
    
    if (ctx != NULL) {
        CGFontRef cgFont = ctFont->copyGraphicsFont();
        ctx->setFont(cgFont);
        CFRelease(cgFont);
        ctx->setFontSize(CTFontGetSize(ctFont));
        ctx->setFillColor((__bridge CGColorRef) attributes[CTAttributeName::foregroundColor()]);
    }
    for (CFIndex i = 0; i < this->getGlyphCount(); ++i) {
        CGGlyph glyph = this->getGlyph(i);
        CGPoint position = this->getPosition(i);
        f(glyph, position, boundingRects[i]);
    }
}

void __CTRun::enumerateGlyphs(std::function<void(NSInteger stringIndex, CGRect glyphBounds, bool &stop)> f) const
{
    NSDictionary *attributes = this->getAttributes();
    CTFontRef ctFont = (__bridge CTFontRef) attributes[CTAttributeName::font()];
    
    size_t const glyphCount = this->getGlyphCount();
    
    CGRect boundingRects[glyphCount];
    CTFontGetOpticalBoundsForGlyphs(ctFont, CTRunGetGlyphsPtr(this), boundingRects, glyphCount, 0);
    
    CGPoint positions[glyphCount];
    CTRunGetPositions(this, CFRangeMake(0, 0), positions);
    
    CFIndex stringIndexes[glyphCount];
    CTRunGetStringIndices(this, CFRangeMake(0, 0), stringIndexes);
    
    bool stop = false;
    for (CFIndex i = 0; i < this->getGlyphCount(); ++i) {
        CGRect bounds = boundingRects[i];
        bounds.origin.x += positions[i].x;
        bounds.origin.y += positions[i].y;
        f((NSInteger) stringIndexes[i], bounds, stop);
        if (stop) {
            break;
        }
    }
}

void __CTFrame::drawWithBaselineShifts(CGContextRef ctx) const
{
    NSArray *lines = this->getLines();
    size_t const lineCount = [lines count];
    CGPoint origins[lineCount];
    this->getLineOrigins(origins);
    CGPoint const frameOrigin = this->getBoundingBox().origin;
    
    for (size_t lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
        CTLineRef line = (__bridge CTLineRef) lines[lineIndex];
        CGPoint lineOrigin = origins[lineIndex];
        lineOrigin.x += frameOrigin.x;
        lineOrigin.y += frameOrigin.y;
        
        ctx->setTextPosition(lineOrigin);
        line->drawWithBaselineShifts(ctx);
    }
}

void __CTFrame::enumerateLinesWithImageBounds(CGContextRef ctx, std::function<void(CTLineRef line, CGRect imageBounds, CGPoint lineOrigin)> f) const
{
    NSArray *lines = this->getLines();
    size_t const lineCount = [lines count];
    CGPoint origins[lineCount];
    this->getLineOrigins(origins);
    CGPoint const frameOrigin = this->getBoundingBox().origin;
    
    for (size_t lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
        CTLineRef line = (__bridge CTLineRef) lines[lineIndex];
        CGPoint lineOrigin = origins[lineIndex];
        lineOrigin.x += frameOrigin.x;
        lineOrigin.y += frameOrigin.y;
        
        ctx->setTextPosition(lineOrigin);
        CGRect imageBounds = line->getImageBounds(ctx);
        
        f(line, imageBounds, lineOrigin);
    }
}


CTRunRef __CTLine::getGlyphRunsForIndex(NSInteger idx) const {
    CTRunRef result = NULL;
    enumerateGlyphRuns([&](CTRunRef run, bool &stop){
        if (NSLocationInRange(idx, run->getStringRange())) {
            stop = true;
            result = run;
        }
    });
    return result;
}
