//
//  BOMarkdownParser.h
//  Cocktail
//
//  Created by Daniel Eggert on 1/13/12.
//  Copyright (c) 2012 SHAPE ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIFont;
@class UIColor;
@class NSMutableParagraphStyle;

extern NSString * const BOAttribtuedStringLinkTargetKey;

typedef UIFont * (^BOFontReplacementBlock_t)(UIFont *oldFont);


__attribute__((visibility("default")))
@interface BOMarkdownParser : NSObject

+ (instancetype)parser;

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSMutableParagraphStyle *paragraphStyle;

@property (nonatomic, copy) BOFontReplacementBlock_t emphasizeFont;
@property (nonatomic, strong) BOFontReplacementBlock_t doubleEmphasizeFont;
@property (nonatomic, strong) UIColor *linkTextColor;
@property (nonatomic, strong) BOFontReplacementBlock_t replaceLinkFont;

- (NSAttributedString *)parseString:(NSString *)input;

@end
