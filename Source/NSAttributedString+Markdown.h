//
//  NSAttributedString+Markdown.h
//  Cocktail
//
//  Created by Daniel Eggert on 1/13/12.
//  Copyright (c) 2012 SHAPE ApS. All rights reserved.
//  Copyright (c) 2012 Daniel Eggert / Bödewadt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BOMarkdownParser.h"




@interface NSMutableAttributedString (BOMarkers)

- (void)replaceAttributesInRangeWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker withReplacementBlock:(BOAttributesReplacementBlock_t)attributesBlock;

- (void)addAttributesToRangeWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker markedAttributesBlock:(NSDictionary * (^)(unichar marker))markBlock replacementBlock:(BOAttributesReplacementBlock_t)attributesBlock;

- (void)enumerateAttribute:(NSString *)attrName inRangesWithStartMarker:(NSString *)startMarker endMarker:(NSString *)endMarker usingBlock:(void (^)(id value, NSRange range))block;

@end
