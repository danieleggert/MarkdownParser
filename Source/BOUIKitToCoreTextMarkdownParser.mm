//
//  BOUIKitToCoreTextMarkdownParser.mm
//  Wheel
//
//  Created by Daniel Eggert on 2/26/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import "BOUIKitToCoreTextMarkdownParser.h"


#import "CoreTextHelpers.h"



@interface UIFont (BOCoreText)

- (id)coreTextFont;

@end




@implementation BOUIKitToCoreTextMarkdownParser

- (void)setupAttributes;
{
    _paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    self.textColor = [UIColor blackColor];
}

- (void)preParseSetupAttributes;
{
    if (self.baseAttributes == nil) {
        NSMutableDictionary *baseAttributes = [NSMutableDictionary dictionary];
        if (self.baseFont != nil) {
            baseAttributes[CTAttributeName::font()] = self.baseFont.coreTextFont;
        }
        
        CTH::ParagraphStyleSettings styleSettings(self.paragraphStyle);
        baseAttributes[CTAttributeName::paragraphStyle()] = styleSettings.paragraphStyle();
        
        if (self.textColor) {
            baseAttributes[CTAttributeName::foregroundColor()] = (__bridge id) self.textColor.CGColor;
        } else {
            baseAttributes[CTAttributeName::foregroundColorFromContext()] = @YES;
        }
        self.baseAttributes = baseAttributes;
    }
    
    if ((self.doubleEmphasizeFont == nil) && (self.fontForDoubleEmphasize != nil)) {
        self.doubleEmphasizeFont = [[[self class] attributesReplacementByChangingFont:self.fontForDoubleEmphasize] copy];
    }
    
    if ((self.replaceLinkFont == nil) && ((self.fontForLink != nil) || (self.linkTextColor != nil))) {
        self.replaceLinkFont = [[[self class] attributesReplacementByChangingFont:self.fontForLink textColor:self.linkTextColor] copy];
    }
    
    [super preParseSetupAttributes];
}

+ (BOAttributesReplacementBlock_t)attributesReplacementByChangingFont:(UIFont *)font;
{
    return [self attributesReplacementByChangingFont:font textColor:nil];
}

+ (BOAttributesReplacementBlock_t)attributesReplacementByChangingFont:(UIFont *)font textColor:(UIColor *)color;
{
    NSString *fontName = font.fontName;
    return ^(NSDictionary *attributes){
        NSMutableDictionary *replacementAttributes = [attributes mutableCopy];
        if (fontName != nil) {
            CTFontRef originalFont = (__bridge CTFontRef) replacementAttributes[CTAttributeName::font()];
            CTFontRef newFont = CTFontCreateWithName((__bridge CFStringRef) fontName, CTFontGetSize(originalFont), NULL);
            replacementAttributes[CTAttributeName::font()] = (__bridge id) newFont;
            newFont->release();
        }
        if (color != nil) {
            replacementAttributes[CTAttributeName::foregroundColor()] = (__bridge id) color.CGColor;
        }
        return replacementAttributes;
    };
}

@end



@implementation UIFont (BOCoreText)

- (id)coreTextFont;
{
    return CFBridgingRelease(__CTFont::createFont(self));
}

@end
