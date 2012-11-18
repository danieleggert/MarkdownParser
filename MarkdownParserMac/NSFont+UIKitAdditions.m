//
//  NSFont+UIKitAdditions.m
//  MarkdownParser
//
//  Created by Jan on 18.11.12.
//  Copyright (c) 2012 Bödewadt. All rights reserved.
//

#import "NSFont+UIKitAdditions.h"

@implementation NSFont (UIKitAdditions)

// This can’t work, because no italic version of Lucida Grande is available!
+ (NSFont *)italicSystemFontOfSize:(CGFloat)size;
{
	NSFont *baseFont = [NSFont systemFontOfSize:((size == 0) ? [NSFont systemFontSize] : size)];
	return [[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSItalicFontMask];
}

- (NSFont *)fontWithSize:(CGFloat)size;
{
	NSFontDescriptor *fontDescriptor = [self fontDescriptor];
	return [NSFont fontWithDescriptor:fontDescriptor size:((size == 0) ? [NSFont systemFontSize] : size)];
}


@end
