//
//  NSFont+UIKitAdditions.h
//  MarkdownParser
//
//  Created by Jan on 18.11.12.
//  Copyright (c) 2012 Bödewadt. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSFont (UIKitAdditions)

+ (NSFont *)italicSystemFontOfSize:(CGFloat)size;

- (NSFont *)fontWithSize:(CGFloat)size;

@end
