//
//  BOUIKitMarkdownParser.m
//  Wheel
//
//  Created by Daniel Eggert on 2/26/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import "BOUIKitMarkdownParser.h"



@implementation BOUIKitMarkdownParser

- (void)setupAttributes;
{
    _paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
}

- (void)preParseSetupAttributes;
{
    if (self.baseAttributes == nil) {
        self.baseAttributes = @{NSFontAttributeName: self.baseFont,
                                NSKernAttributeName: [NSNull null],
                                NSParagraphStyleAttributeName: self.paragraphStyle,
                                NSForegroundColorAttributeName: self.textColor,
                                };
    }
    
    if ((self.emphasizeFont == nil) && (self.fontForEmphasize != nil)) {
        self.emphasizeFont = [[[self class] attributesReplacementByChangingFont:self.fontForEmphasize] copy];
    }

    if ((self.doubleEmphasizeFont == nil) && (self.fontForDoubleEmphasize != nil)) {
        self.doubleEmphasizeFont = [[[self class] attributesReplacementByChangingFont:self.fontForDoubleEmphasize] copy];
    }

    if ((self.replaceLinkFont == nil) && ((self.fontForLink != nil) || (self.linkTextColor != nil))) {
        self.replaceLinkFont = [[[self class] attributesReplacementByChangingFont:self.fontForLink textColor:self.linkTextColor] copy];
    }
    
    [super preParseSetupAttributes];
}

- (NSString *)linkAttributeName;
{
    return NSLinkAttributeName;
}

- (NSURL *)linkURLFromLinkString:(NSString *)linkString;
{
    if ([linkString hasPrefix:@"/"]) {
        linkString = [@"minibar:/" stringByAppendingString:linkString];
    }
    return [super linkURLFromLinkString:linkString];
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
            UIFont *originalFont = attributes[NSFontAttributeName];
            UIFont *replacementFont = [UIFont fontWithName:fontName size:originalFont.pointSize];
            replacementAttributes[NSFontAttributeName] = replacementFont;
        }
        if (color != nil) {
            replacementAttributes[NSForegroundColorAttributeName] = color;
        }
        return replacementAttributes;
    };
}

@end
