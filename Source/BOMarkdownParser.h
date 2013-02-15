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

extern NSString * const BOLinkAttributeName;

typedef NSDictionary * (^BOAttributesReplacementBlock_t)(NSDictionary *oldAttributes);



__attribute__((visibility("default")))
@interface BOMarkdownParser : NSObject

+ (instancetype)parser;

@property (nonatomic, copy) NSDictionary *baseAttributes;

@property (nonatomic, copy) NSString *unorderedListBullet;
@property (nonatomic, copy) NSString *(^listNumberFromIndex)(int const itemIndex);
@property (nonatomic, copy) BOAttributesReplacementBlock_t listAttributes;
@property (nonatomic, copy) BOAttributesReplacementBlock_t listItemAttributes;

@property (nonatomic, copy) BOAttributesReplacementBlock_t emphasizeFont;
@property (nonatomic, copy) BOAttributesReplacementBlock_t doubleEmphasizeFont;
@property (nonatomic, copy) BOAttributesReplacementBlock_t linkTextColor;
@property (nonatomic, copy) BOAttributesReplacementBlock_t replaceLinkFont;

/** For header levels 1 - 6. Array of BOAttributesReplacementBlock_t instances. */
@property (nonatomic, copy) NSArray *headerAttributes;

- (NSAttributedString *)parseString:(NSString *)input;

@end
