//
//  NSAttributedString+Markdown.m
//  Cocktail
//
//  Created by Daniel Eggert on 1/13/12.
//  Copyright (c) 2012 SHAPE ApS. All rights reserved.
//  Copyright (c) 2012 Daniel Eggert / Bödewadt. All rights reserved.
//

#import "NSAttributedString+Markdown.h"

#import <libkern/OSAtomic.h>
#import <UIKit/UIKit.h>



@implementation NSMutableAttributedString (BOMarkers)

- (void)replaceAttributesInRangeWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker withReplacementBlock:(BOAttributesReplacementBlock_t)attributesBlock;
{
    NSCharacterSet *privateUse = [NSCharacterSet characterSetWithRange:NSMakeRange(0xe000, 0xf900 - 0xe000)];
    NSMutableString *string = [self mutableString];
    NSRange remainingRange = NSMakeRange(0, [string length]);
    while (0 < remainingRange.length) {
        NSRange const startRange = [string rangeOfString:startMarker options:NSLiteralSearch range:remainingRange];
        if (startRange.length == 0) {
            break;
        } else {
            remainingRange = NSMakeRange(NSMaxRange(startRange), [string length] - NSMaxRange(startRange));
            NSRange const endRange = [string rangeOfString:endMarker options:NSLiteralSearch range:remainingRange];
            if (endRange.length == 0) {
                break;
            } else {
                remainingRange = NSMakeRange(NSMaxRange(endRange), [string length] - NSMaxRange(endRange));
                // Remove markers:
                [string replaceCharactersInRange:endRange withString:@""];
                [string replaceCharactersInRange:startRange withString:@""];
                remainingRange.location -= startRange.length + endRange.length;
                // Set style:
                if (attributesBlock != nil) {
                    NSRange styleRange = NSMakeRange(startRange.location, endRange.location - startRange.location - startRange.length);
                    // Don't include trailing '\n':
                    while (0 < styleRange.length) {
                        unichar c = [string characterAtIndex:NSMaxRange(styleRange) - 1];
                        if ([privateUse characterIsMember:c]) {
                            styleRange.length -= 1;
                        } else if (c == '\n') {
                            styleRange.length -= 1;
                            break;
                        } else {
                            break;
                        }
                    }
                    [self enumerateAttributesInRange:styleRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *originalAttributes, NSRange range, BOOL *stop) {
                        (void) stop;
                        NSDictionary *newAttributes = attributesBlock(originalAttributes);
                        [self setAttributes:newAttributes range:range];
                    }];
                }
            }
        }
    }
}

- (void)addAttributesToRangeWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker markedAttributesBlock:(NSDictionary * (^)(unichar marker))markBlock replacementBlock:(BOAttributesReplacementBlock_t)attributesBlock;
{
    NSMutableString *string = [self mutableString];
    NSRange remainingRange = NSMakeRange(0, [string length]);
    while (0 < remainingRange.length) {
        NSRange startRange = [string rangeOfString:startMarker options:NSLiteralSearch range:remainingRange];
        if (startRange.length == 0) {
            break;
        } else {
            unichar const marker = [string characterAtIndex:NSMaxRange(startRange)];
            startRange.length += 1;
            
            remainingRange = NSMakeRange(NSMaxRange(startRange), [string length] - NSMaxRange(startRange));
            NSRange const endRange = [string rangeOfString:endMarker options:NSLiteralSearch range:remainingRange];
            if (endRange.length == 0) {
                break;
            } else {
                remainingRange = NSMakeRange(NSMaxRange(endRange), [string length] - NSMaxRange(endRange));
                // Remove markers:
                [string replaceCharactersInRange:endRange withString:@""];
                [string replaceCharactersInRange:startRange withString:@""];
                remainingRange.location -= startRange.length + endRange.length;
                // Set style:
                NSRange styleRange = NSMakeRange(startRange.location, endRange.location - startRange.location - startRange.length);
                NSDictionary *attributes = markBlock(marker);
                if (attributes != nil) {
                    [self addAttributes:attributes range:styleRange];
                }
                if (attributesBlock != nil) {
                    [self enumerateAttributesInRange:styleRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *originalAttributes, NSRange range, BOOL *stop) {
                        (void) stop;
                        NSDictionary *newAttributes = attributesBlock(originalAttributes);
                        [self setAttributes:newAttributes range:range];
                    }];
                }
            }
        }
    }
}

- (void)enumerateAttribute:(NSString *)attrName inRangesWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker usingBlock:(void (^)(id value, NSRange range))block;
{
    NSMutableString *string = [self mutableString];
    NSRange remainingRange = NSMakeRange(0, [string length]);
    while (0 < remainingRange.length) {
        NSRange const startRange = [string rangeOfString:startMarker options:NSLiteralSearch range:remainingRange];
        if (startRange.length == 0) {
            break;
        } else {
            remainingRange = NSMakeRange(NSMaxRange(startRange), [string length] - NSMaxRange(startRange));
            NSRange const endRange = [string rangeOfString:endMarker options:NSLiteralSearch range:remainingRange];
            if (endRange.length == 0) {
                break;
            } else {
                remainingRange = NSMakeRange(NSMaxRange(endRange), [string length] - NSMaxRange(endRange));
                // Remove markers:
                [string replaceCharactersInRange:endRange withString:@""];
                [string replaceCharactersInRange:startRange withString:@""];
                remainingRange.location -= startRange.length + endRange.length;
                // Set style:
                NSRange styleRange = NSMakeRange(startRange.location, endRange.location - startRange.location - startRange.length);
                [self enumerateAttribute:attrName inRange:styleRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
                    (void) stop;
                    block(value, range);
                }];
            }
        }
    }
}

@end
