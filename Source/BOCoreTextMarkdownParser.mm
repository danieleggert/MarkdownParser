//
//  BOCoreTextMarkdownParser.m
//  Wheel
//
//  Created by Daniel Eggert on 2/26/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import "BOCoreTextMarkdownParser.h"

#import "CoreTextHelpers.h"



@implementation BOCoreTextMarkdownParser

- (NSAttributedString *)parseString:(NSString *)input;
{
    // Ugly hack here, to not copy the string again:
    NSMutableAttributedString *result = (id) [super parseString:input];
    if (result == nil) {
        return nil;
    }
    
    [result beginEditing];
    
    NSUInteger location = 0;
    NSUInteger length = [result length];
    while (location < length) {
        NSRange linebreak = [result.string rangeOfString:@"\r" options:NSLiteralSearch range:NSMakeRange(location, length - location)];
        if (linebreak.location == NSNotFound) {
            break;
        }
        if (0 < linebreak.location) {
            // Update before:
            {
                NSRange longestEffectiveRange;
                id style = [result attribute:CTAttributeName::paragraphStyle() atIndex:linebreak.location - 1 longestEffectiveRange:&longestEffectiveRange inRange:NSMakeRange(location, linebreak.location - location)];
                NSRange newline = [result.string rangeOfString:@"\n" options:(NSBackwardsSearch | NSLiteralSearch) range:longestEffectiveRange];
                NSRange paragraphRange = ((newline.location == NSNotFound) ?
                                          NSMakeRange(location, linebreak.location - location) :
                                          NSMakeRange(newline.location + 1, linebreak.location - newline.location- 1));
                
                if (style != nil) {
                    CTH::ParagraphStyleSettings styleSettings(style);
                    styleSettings.paragraphSpacing = 0;
                    [result addAttribute:CTAttributeName::paragraphStyle() value:styleSettings.paragraphStyle() range:paragraphRange];
                    
                }
            }
            // Update after:
            {
                NSRange longestEffectiveRange;
                NSRange const remainderRange = NSMakeRange(linebreak.location + 1, length - linebreak.location - 1);
                id style = [result attribute:CTAttributeName::paragraphStyle() atIndex:linebreak.location + 1 longestEffectiveRange:&longestEffectiveRange inRange:remainderRange];
                NSRange newline = [result.string rangeOfString:@"\n" options:(NSLiteralSearch) range:remainderRange];
                NSRange paragraphRange = ((newline.location == NSNotFound) ?
                                          NSMakeRange(linebreak.location + 1, length - linebreak.location - 1) :
                                          NSMakeRange(linebreak.location + 1, newline.location - linebreak.location - 1));
                
                if (style != nil) {
                    CTH::ParagraphStyleSettings styleSettings(style);
                    styleSettings.paragraphSpacingBefore = 0;
                    styleSettings.firstLineHeadIndent = styleSettings.headIndent;
                    [result addAttribute:CTAttributeName::paragraphStyle() value:styleSettings.paragraphStyle() range:paragraphRange];
                }
            }
        }
        location = NSMaxRange(linebreak);
    }
    
    // Remove trailing new lines:
    {
        NSMutableString *mutableText = result.mutableString;
        while ((0 < [mutableText length]) && [mutableText hasSuffix:@"\n"]) {
            [mutableText replaceCharactersInRange:NSMakeRange([mutableText length] - 1, 1) withString:@""];
        }
    }
    
    [result endEditing];
    return result;
}

@end
