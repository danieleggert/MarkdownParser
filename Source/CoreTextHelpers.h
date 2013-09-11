//
//  CoreTextHelpers.h
//  Wheel
//
//  Created by Daniel Eggert on 12/31/12.
//  Copyright (c) 2012 Bödewadt. All rights reserved.
//

#import <CoreText/CoreText.h>

#import <functional>
#import <initializer_list>
#import <vector>
@class UIFont;



/** Makes it slightly less verbose to yse kCT...AttributeName constants with an NSDictionary. */
struct CTAttributeName {
    static NSString * font(void) { return (__bridge id) kCTFontAttributeName; };
    static NSString * ligature(void) { return (__bridge id) kCTLigatureAttributeName; };
    static NSString * foregroundColor(void) { return (__bridge id) kCTForegroundColorAttributeName; };
    static NSString * foregroundColorFromContext(void) { return (__bridge id) kCTForegroundColorFromContextAttributeName; };
    static NSString * kern(void) { return (__bridge id) kCTKernAttributeName; };
    static NSString * paragraphStyle(void) { return (__bridge id) kCTParagraphStyleAttributeName; };
    static NSString * runDelegate(void) { return (__bridge id) kCTRunDelegateAttributeName; };
    static NSString * baselineShift(void) { return @"baselineShift"; };
};


#pragma mark - CTFont

namespace CTH {
    
    typedef enum FontWeight_e {
        ThinFontWeight = 0,
        LightFontWeight,
        BookFontWeight,
        RegularFontWeight,
        BoldFontWeight,
        HeavyFontWeight,
        
        FontWeightCount,
    } FontWeight_t;
    
    typedef enum FontOptions_e {
        FontOptionsNone = 0,
        FontOptionSmallCaps = 1 << 0,
        FontLowerCaseSmallCaps = 1 << 1,
        FontOptionUpperCaseNumbers = 1 << 2,
    } FontOptions_t;
    
    class ParagraphStyleSettings {
        //
        // N.B.: This class stores internal pointers and copy'ing etc. doesn't work (until a working copy constructor has been implemented).
        //
    public:
        ParagraphStyleSettings(void);
        ParagraphStyleSettings(NSParagraphStyle *other);
        ParagraphStyleSettings(id paragraphStyle);
        ~ParagraphStyleSettings(void) {
            tabStops = nil; // release tabs stops
        };
        
        CTParagraphStyleRef createParagraphStyle(void) const;
        id paragraphStyle(void) const;
        
        CTTextAlignment alignment;
        CGFloat firstLineHeadIndent;
        CGFloat headIndent;
        CGFloat tailIndent;
        __strong id tabStops;
        CTLineBreakMode lineBreakMode;
        CGFloat maximumLineHeight;
        CGFloat minimumLineHeight;
        CGFloat paragraphSpacingBefore;
        CGFloat paragraphSpacing;
        CTLineBoundsOptions lineBoundsOptions;
        
        void setLineHeight(CGFloat height) {
            minimumLineHeight = height;
            maximumLineHeight = height;
        }
        
        void setTabStops(std::initializer_list<CGFloat> locations);
        void setCenteredTabStops(std::initializer_list<CGFloat> locations);
        
    private:
        
        
    };
    
    
    class Frame  {
    public:
        Frame(void);
        Frame(Frame const &other);
        Frame(NSAttributedString *text, CGRect bounds);
        ~Frame(void);
        
        NSRange getStringRangeForPosition(CGPoint const &point) const;
        NSRange getStringRange(void) const;
        NSRange getVisibleStringRange(void) const;
        
        void draw(CGContextRef ctx);
        
        NSString *description(void) const;
        
    private:
        CGFloat leadingForRange(CFRange const &textRange, NSAttributedString *text);
        
        CTTypesetterRef const _typesetter;
        CGRect _bounds;
        
        __strong NSArray *_lines;
        std::vector<CGPoint> _origins;
        std::vector<NSRange> _lineRanges;
    };
}


struct __CTFont {
    
    static CTFontRef createFont(UIFont *uiFont);
    
    CGFloat getSize(void) const {
        return CTFontGetSize(this);
    }
    
    CGFloat getAscent(void) const {
        return CTFontGetAscent(this);
    }

    CGFloat getDescent(void) const {
        return CTFontGetDescent(this);
    }
    
    CGRect getBoundingBox(void) const {
        return CTFontGetBoundingBox(this);
    }
    
    CGAffineTransform getMatrix(void) const {
        return CTFontGetMatrix(this);
    }
    
    CGFontRef copyGraphicsFont(void) const {
        return CTFontCopyGraphicsFont(this, NULL);
    }
    
    CTFontDescriptorRef copyFontDescriptor(void) const {
        return CTFontCopyFontDescriptor(this);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
};



#pragma mark - CTParagraphStyle

struct __CTParagraphStyle {
    
    BOOL getValueForSpecifier(CTParagraphStyleSpecifier spec, size_t valueBufferSize, void *valueBuffer) const {
        return CTParagraphStyleGetValueForSpecifier(this, spec, valueBufferSize, valueBuffer);
    }
    BOOL getFloatValueForSpecifier(CTParagraphStyleSpecifier spec, CGFloat *valueBuffer) const {
        return CTParagraphStyleGetValueForSpecifier(this, spec, sizeof(*valueBuffer), valueBuffer);
    }
    BOOL getInt8ValueForSpecifier(CTParagraphStyleSpecifier spec, int8_t *valueBuffer) const {
        return CTParagraphStyleGetValueForSpecifier(this, spec, sizeof(*valueBuffer), valueBuffer);
    }
    BOOL getObjectForSpecifier(CTParagraphStyleSpecifier spec, id *valueBuffer) const {
        return CTParagraphStyleGetValueForSpecifier(this, spec, sizeof(*valueBuffer), valueBuffer);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
};



#pragma mark - CTFontDescriptor

struct __CTFontDescriptor {
    
    static CTFontDescriptorRef createWithAttributes(NSDictionary *attributes) {
        return CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef) attributes);
    }
    
    CTFontDescriptorRef createCopyWithFeature(int featureTypeIdentifier, int featureSelectorIdentifier) const {
        return CTFontDescriptorCreateCopyWithFeature(this, (__bridge CFNumberRef) @(featureTypeIdentifier), (__bridge CFNumberRef) @(featureSelectorIdentifier));
    }
    
    CTFontRef createFont(CGFloat pointSize) const {
        return CTFontCreateWithFontDescriptor(this, pointSize, NULL);
    }
    
    static void replaceByAddingFeature(CTFontDescriptorRef &descriptor, int featureTypeIdentifier, int featureSelectorIdentifier)
    {
        CTFontDescriptorRef newDescriptor = descriptor->createCopyWithFeature(featureTypeIdentifier, featureSelectorIdentifier);
        descriptor->release();
        descriptor = newDescriptor;
    }
    
    NSDictionary *attributes(void) const {
        return CFBridgingRelease(CTFontDescriptorCopyAttributes(this));
    }
    
    CTFontDescriptorRef createCopyWithAttributes(NSDictionary *attributes) const {
        return CTFontDescriptorCreateCopyWithAttributes(this, (__bridge CFDictionaryRef) attributes);
    }
    CTFontDescriptorRef createCopyWithFontName(NSString *fontName) const {
        NSDictionary *attributes = @{(__bridge id) kCTFontNameAttribute: fontName};
        return CTFontDescriptorCreateCopyWithAttributes(this, (__bridge CFDictionaryRef) attributes);
    }
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
};

#pragma mark - CTLine

struct __CTLine {
    
    static CTLineRef createWithAttributedString(NSAttributedString *string) {
        return CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) string);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
    
    double getTypographicWidth(void) const {
        return CTLineGetTypographicBounds(this, NULL, NULL, NULL);
    }
    double getTrailingWhitespaceWidth(void) const {
        return CTLineGetTrailingWhitespaceWidth(this);
    }
    double getTypographicBounds(CGFloat &ascent) const {
        CGFloat a = 0;
        double result = CTLineGetTypographicBounds(this, &a, NULL, NULL);
        ascent = a;
        return result;
    }
    double getTypographicBounds(CGFloat &ascent, CGFloat &descent) const {
        CGFloat a = 0;
        CGFloat d = 0;
        double result = CTLineGetTypographicBounds(this, &a, &d, NULL);
        ascent = a;
        descent = d;
        return result;
    }
    double getTypographicBounds(CGFloat &ascent, CGFloat &descent, CGFloat &leading) const {
        CGFloat a = 0;
        CGFloat d = 0;
        CGFloat l = 0;
        double result = CTLineGetTypographicBounds(this, &a, &d, &l);
        ascent = a;
        descent = d;
        leading = l;
        return result;
    }

    CGFloat getLeading(void) const {
        CGFloat l = 0;
        (void) CTLineGetTypographicBounds(this, NULL, NULL, &l);
        return l;
    }
    CGFloat getAscent(void) const {
        CGFloat a = 0;
        (void) CTLineGetTypographicBounds(this, &a, NULL, NULL);
        return a;
    }
    
    CGRect getBoundsWithOptions(CTLineBoundsOptions options) const {
        return CTLineGetBoundsWithOptions(this, options);
    }
    
    CGRect getImageBounds(CGContextRef ctx) const {
        return CTLineGetImageBounds(this, ctx);
    }
    
    NSArray * getGlyphRuns(void) const {
        return (__bridge id) CTLineGetGlyphRuns(this);
    };
    
    double getPenOffsetForFlush(CGFloat flushFactor, double flushWidth) const {
        return CTLineGetPenOffsetForFlush(this, flushFactor, flushWidth);
    }
    
    CGFloat getOffsetForStringIndex(CFIndex charIndex) const {
        return CTLineGetOffsetForStringIndex(this, charIndex, NULL);
    };
    
    NSInteger getStringIndexForPosition(CGPoint p) const {
        return CTLineGetStringIndexForPosition(this, p);
    }
    
    CTRunRef getGlyphRunsForIndex(NSInteger idx) const;
    
    NSRange getStringRange(void) const {
        CFRange r = CTLineGetStringRange(this);
        return NSMakeRange(r.location, r.length);
    }
    
    void draw(CGContextRef context) const {
        CTLineDraw(this, context);
    }
    
    void drawWithBaselineShifts(CGContextRef context) const;
    
    void enumerateGlyphRuns(std::function<void(CTRunRef run)> f) const;
    void enumerateGlyphRuns(std::function<void(CTRunRef run, bool &stop)> f) const;
    
};



#pragma mark - CTRun

struct __CTRun {
    NSDictionary *getAttributes(void) const {
        return (__bridge NSDictionary *) CTRunGetAttributes(this);
    }
    
    CFIndex getGlyphCount(void) const __attribute__((pure)) {
        return CTRunGetGlyphCount(this);
    }
    
    CGAffineTransform getTextMatrix(void) const {
        return CTRunGetTextMatrix(this);
    }
    
    void getPositions(CFRange range, CGPoint buffer[]) const {
        CTRunGetPositions(this, range, buffer);
    }
    CGPoint getPosition(CFIndex location) const {
        CGPoint result;
        CTRunGetPositions(this, CFRangeMake(location, 1), &result);
        return result;
    }
    
    double getTypographicBounds(CGFloat* ascent, CGFloat* descent, CGFloat* leading) const {
        return CTRunGetTypographicBounds(this, CFRangeMake(0, 0), ascent, descent, leading);
    }
    
//    CGRect getImageBounds(CGContextRef ctx) const {
//        return CTRunGetImageBounds(this, ctx, <#CFRange range#>)
//    }

    void getAdvances(CFRange range, CGSize buffer[]) const {
        return CTRunGetAdvances(this, range, buffer);
    }
    CGSize getAdvance(CFIndex location) const {
        CGSize result;
        CTRunGetAdvances(this, CFRangeMake(location, 1), &result);
        return result;
    }
    
    void getGlyphs(CFRange range, CGGlyph buffer[]) const {
        return CTRunGetGlyphs(this, range, buffer);
    }

    CGGlyph getGlyph(CFIndex location) const {
        CGGlyph result;
        CTRunGetGlyphs(this, CFRangeMake(location, 1), &result);
        return result;
    }
    
    NSRange getStringRange(void) const {
        CFRange r = CTRunGetStringRange(this);
        return NSMakeRange(r.location, r.length);
    }
    
    void enumerateGlyphs(CGContextRef ctx, std::function<void(CGGlyph glyph, CGPoint position, CGSize advance)> f) const;
    void enumerateGlyphs(CGContextRef ctx, std::function<void(CGGlyph glyph, CGPoint position, CGRect glyphBounds)> f) const;
    void enumerateGlyphs(std::function<void(NSInteger stringIndex, CGRect glyphBounds, bool &stop)> f) const;
};



#pragma mark - CTTypesetter

struct __CTTypesetter {
    static CTTypesetterRef createWithAttributedString(CFAttributedStringRef string) {
        return CTTypesetterCreateWithAttributedString(string);
    }
    static CTTypesetterRef createWithAttributedString(NSAttributedString *string) {
        return CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef) string);
    }
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
    
    CFIndex suggestLineBreak(CFIndex startIndex, double width) const {
        return CTTypesetterSuggestLineBreak(this, startIndex, width);
    }
    CFIndex suggestClusterBreak(CFIndex startIndex, double width) const {
        return CTTypesetterSuggestClusterBreak(this, startIndex, width);
    }
    
    CTLineRef createLine(CFRange stringRange) const {
        return CTTypesetterCreateLine(this, stringRange);
    }
    
    CTLineRef createLineWithOffset(CFRange stringRange, double offset) const {
        return CTTypesetterCreateLineWithOffset(this, stringRange, offset);
    }
};



#pragma mark - CTFramesetter

struct __CTFramesetter {
    static CTFramesetterRef createWithAttributedString(NSAttributedString *string) {
        return CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) string);
    }
    
    CTFrameRef createFrame(CFRange stringRange, CGPathRef path, CFDictionaryRef frameAttributes) const {
        return CTFramesetterCreateFrame(this, stringRange, path, frameAttributes);
    }
    CTFrameRef createFrame(CGPathRef path) const {
        return CTFramesetterCreateFrame(this, CFRangeMake(0, 0), path, NULL);
    }
    CTFrameRef createFrame(CGRect rect) const {
        CGPathRef path = CGPathCreateWithRect(rect, NULL);
        CTFrameRef f = CTFramesetterCreateFrame(this, CFRangeMake(0, 0), path, NULL);
        CGPathRelease(path);
        return f;
    }
    
    CGSize suggestFrameSize(CFRange stringRange, CFDictionaryRef frameAttributes, CGSize constraints, CFRange *fitRange) const {
        return CTFramesetterSuggestFrameSizeWithConstraints(this, stringRange, frameAttributes, constraints, fitRange);
    }
    CGSize suggestFrameSize(CGSize constraints) const {
        return CTFramesetterSuggestFrameSizeWithConstraints(this, CFRangeMake(0, 0), NULL, constraints, NULL);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
};



#pragma mark - CTFrame

struct __CTFrame {
    void draw(CGContextRef context) const {
        CTFrameDraw(this, context);
    }
    
    void drawWithBaselineShifts(CGContextRef context) const;
    
    NSArray *getLines(void) const {
        return (__bridge id) CTFrameGetLines(this);
    }
    
    void getLineOrigins(CGPoint *origins) const {
        CTFrameGetLineOrigins(this, CFRangeMake(0, 0), origins);
    }
    
    void enumerateLinesWithImageBounds(CGContextRef ctx, std::function<void(CTLineRef line, CGRect imageBounds, CGPoint lineOrigin)> f) const;
    
    CGRect getBoundingBox(void) const {
        CGPathRef path = CTFrameGetPath(this);
        return CGPathGetPathBoundingBox(path);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
};
