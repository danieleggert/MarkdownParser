//
//  BOUIKitMarkdownParser.h
//  Wheel
//
//  Created by Daniel Eggert on 2/26/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import "BOMarkdownParser.h"



@interface BOUIKitMarkdownParser : BOMarkdownParser

@property (nonatomic, strong) UIFont *baseFont;
@property (readonly, nonatomic, strong) NSMutableParagraphStyle *paragraphStyle;

@property (nonatomic, strong) UIFont *fontForEmphasize;
@property (nonatomic, strong) UIFont *fontForDoubleEmphasize;
@property (nonatomic, strong) UIFont *fontForLink;

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *linkTextColor;

+ (BOAttributesReplacementBlock_t)attributesReplacementByChangingFont:(UIFont *)font;
+ (BOAttributesReplacementBlock_t)attributesReplacementByChangingFont:(UIFont *)font textColor:(UIColor *)color;

@end
