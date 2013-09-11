//
//  CoreGraphicsHelpers.h
//  Wheel
//
//  Created by Daniel Eggert on 1/1/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import <initializer_list>


#define CGH_PURE __attribute__((pure))
#define CGH_WARN_UNUSED __attribute__((warn_unused_result))
#define CGH_PURE_WARN_UNUSED __attribute__((pure, warn_unused_result))



struct CGHAffineTransform {
    CGHAffineTransform(void) : _t(CGAffineTransformIdentity) {};
    CGHAffineTransform(CGAffineTransform t) : _t(t) {};
    
    operator CGAffineTransform(void) const {
        return _t;
    }
    CGHAffineTransform translate(CGFloat tx, CGFloat ty) CGH_PURE_WARN_UNUSED {
        return CGAffineTransformTranslate(_t, tx, ty);
    }
    CGHAffineTransform scale(CGFloat sx, CGFloat sy) CGH_PURE_WARN_UNUSED {
        return CGAffineTransformScale(_t, sx, sy);
    }
    CGHAffineTransform rotate(CGFloat angle) CGH_PURE_WARN_UNUSED {
        return CGAffineTransformRotate(_t, angle);
    }
    
    CGAffineTransform _t;
};


struct CGContext {
    
    /** Graphics state functions. **/
    
    void saveGState(void) {
        CGContextSaveGState(this);
    }
    void restoreGState(void) {
        CGContextRestoreGState(this);
    }
    
    /** Coordinate space transformations. **/
    
    void translateCTM(CGPoint p) {
        CGContextTranslateCTM(this, p.x, p.y);
    }

    void translateCTM(CGFloat x, CGFloat y) {
        CGContextTranslateCTM(this, x, y);
    }
    
    void scaleCTM(CGFloat sx, CGFloat sy) {
        CGContextScaleCTM(this, sx, sy);
    }
    
    void rotateCTM(CGFloat angle) {
        CGContextRotateCTM(this, angle);
    }
    
    void concatCTM(CGAffineTransform t) {
        CGContextConcatCTM(this, t);
    }
    
    void setAlpha(CGFloat alpha) {
        CGContextSetAlpha(this, alpha);
    }
    
    void setBlendMode(CGBlendMode mode) {
        CGContextSetBlendMode(this, mode);
    }
    
    /** Clipping functions. **/
    
    void clip(void) {
        CGContextClip(this);
    }
    
    CGRect getClipBoundingBox(void) {
        return CGContextGetClipBoundingBox(this);
    }
    
    /** Primitive color functions. **/
    
    void setFillColor(CGColorRef color) {
        CGContextSetFillColorWithColor(this, color);
    }
    void setFillColor(UIColor *color) {
        CGContextSetFillColorWithColor(this, color.CGColor);
    }
    void setStrokeColor(CGColorRef color) {
        CGContextSetStrokeColorWithColor(this, color);
    }
    void setStrokeColor(UIColor *color) {
        CGContextSetStrokeColorWithColor(this, color.CGColor);
    }
    
    void setLineWidth(CGFloat w) {
        CGContextSetLineWidth(this, w);
    }
    
    /** Path information functions. **/
    
    bool isPathEmpty(void) {
        return CGContextIsPathEmpty(this);
    }
    
    CGPoint getPathCurrentPoint(void) {
        return CGContextGetPathCurrentPoint(this);
    }
    
    /** Path construction functions. **/
    
    void beginPath(void) {
        CGContextBeginPath(this);
    };
    
    /** Path construction convenience functions. **/
    
    void addPath(CGPathRef path) {
        CGContextAddPath(this, path);
    }
    
    /** Path drawing functions. **/
    
    
    /** Path drawing convenience functions. **/
    
    void fillPath(void) {
        CGContextFillPath(this);
    }

    void eoFillPath(void) {
        CGContextEOFillPath(this);
    }
    
    void strokePath(void) {
        CGContextStrokePath(this);
    }
    
    void fillRect(CGRect r) {
        CGContextFillRect(this, r);
    }
    
    void fillEllipseInRect(CGRect rect) {
        CGContextFillEllipseInRect(this, rect);
    }
    
    void fillCircle(CGPoint const center, CGFloat const radius) {
        CGRect rect = CGRectMake(center.x - radius, center.y - radius, radius * 2.f, radius * 2.f);
        fillEllipseInRect(rect);
    }
    
    void strokeRect(CGRect rect) {
        CGContextStrokeRect(this, rect);
    }
    
    void strokeLineSegments(std::initializer_list<const CGPoint> points) {
        CGContextStrokeLineSegments(this, points.begin(), points.size());
    }
    
    /** Antialiasing functions. **/

    void setShouldAntialias(bool shouldAntialias) {
        CGContextSetShouldAntialias(this, shouldAntialias);
    }
    
    /** Shadow support. **/
    
    void setShadow(CGSize offset, CGFloat blur, UIColor *color) {
        CGContextSetShadowWithColor(this, offset, blur, color.CGColor);
    }
    void setShadow(CGSize offset, CGFloat blur) {
        CGContextSetShadow(this, offset, blur);
    }
    void unsetShadow(void) {
        CGContextSetShadowWithColor(this, CGSizeZero, 0, NULL);
    }
    
    /** Text functions. **/
    
    void setTextPosition(CGFloat x, CGFloat y) {
        CGContextSetTextPosition(this, x, y);
    }
    void setTextPosition(CGPoint p) {
        CGContextSetTextPosition(this, p.x, p.y);
    }

    void setTextMatrix(CGAffineTransform t) {
        CGContextSetTextMatrix(this, t);
    }
    
    void setTextDrawingMode(CGTextDrawingMode mode) {
        CGContextSetTextDrawingMode(this, mode);
    }
    
    void setFont(CGFontRef font) {
        CGContextSetFont(this, font);
    }
    
    void setFontSize(CGFloat size) {
        CGContextSetFontSize(this, size);
    }
    
    void showGlyphsAtPositions(const CGGlyph *glyphs, const CGPoint *positions, size_t count) {
        CGContextShowGlyphsAtPositions(this, glyphs, positions, count);
    }

    void showGlyphAtPosition(CGGlyph glyph, CGPoint position) {
        CGContextShowGlyphsAtPositions(this, &glyph, &position, 1);
    }
    
    /** Layer */
    
    void drawLayerInRect(CGRect rect, CGLayerRef layer) {
        CGContextDrawLayerInRect(this, rect, layer);
    }
};

struct CGPath {
    
    static CGMutablePathRef createMutable(void) {
        return CGPathCreateMutable();
    }

    static CGPathRef createEllips(CGRect const r) {
        return CGPathCreateWithEllipseInRect(r, NULL);
    }
    
    static CGPathRef createCircle(CGPoint const center, CGFloat const radius) {
        CGRect rect = CGRectMake(center.x - radius, center.y - radius, radius * 2.f, radius * 2.f);
        return CGPathCreateWithEllipseInRect(rect, NULL);
    }
    
    CGPathRef createCopyByTransformingPath(CGAffineTransform t) const {
        return CGPathCreateCopyByTransformingPath(this, &t);
    }
    CGPathRef createCopyByScalingPath(CGFloat s) const {
        CGAffineTransform t = CGAffineTransformMakeScale(s, s);
        return this->createCopyByTransformingPath(t);
    }
    
    void moveToPoint(CGPoint p) {
        CGPathMoveToPoint(this, NULL, p.x, p.y);
    }
    void lineToPoint(CGPoint p) {
        CGPathAddLineToPoint(this, NULL, p.x, p.y);
    }
    void closeSubpath(void) {
        CGPathCloseSubpath(this);
    }
    
    void addLines(std::initializer_list<CGPoint> const &points) {
        auto it = points.begin();
        if (0 < points.size()) {
            CGPathMoveToPoint(this, NULL, it->x, it->y);
            for (++it; it != points.end(); ++it) {
                CGPathAddLineToPoint(this, NULL, it->x, it->y);
            }
        }
    }
    void addLinesAndClose(std::initializer_list<CGPoint> const &points) {
        auto it = points.begin();
        if (0 < points.size()) {
            CGPathMoveToPoint(this, NULL, it->x, it->y);
            for (++it; it != points.end(); ++it) {
                CGPathAddLineToPoint(this, NULL, it->x, it->y);
            }
            CGPathCloseSubpath(this);
        }
    }
    
    void addRelativeArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat delta) {
        CGPathAddRelativeArc(this, NULL, center.x, center.y, radius, startAngle, delta);
    }
    
    void addRect(CGRect rect) {
        CGPathAddRect(this, NULL, rect);
    }
    
    void addEllipseInRect(CGRect rect) {
        CGPathAddEllipseInRect(this, NULL, rect);
    }
    void addCircle(CGPoint center, CGFloat radius) {
        CGRect rect = CGRectMake(center.x-radius, center.y-radius, 2.f * radius, 2.f * radius);
        CGPathAddEllipseInRect(this, NULL, rect);
    }
    void addCWCircle(CGPoint center, CGFloat radius) {
        CGPathAddArc(this, NULL, center.x, center.y, radius, 0, 2.f * (CGFloat) M_PI, YES);
    }
    
    void addPath(CGPathRef otherPath) {
        CGPathAddPath(this, NULL, otherPath);
    }
    
    void release(void) const {
        if (this != NULL) {
            CFRelease(this);
        }
    }
    
    CGFloat length(void) const;
};


