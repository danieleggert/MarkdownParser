//
//  BOMarkdownParser.m
//  Cocktail
//
//  Created by Daniel Eggert on 1/13/12.
//  Copyright (c) 2012 SHAPE ApS. All rights reserved.
//

#import "BOMarkdownParser.h"

#import "NSAttributedString+Markdown.h"
#import <UIKit/UIKit.h>

#import "markdown.h"
#import "buffer.h"

#define UNUSED __attribute__((unused))



NSString * const BOAttribtuedStringLinkTargetKey = @"linkTarget";



@interface BOMarkdownParser (Private)

- (void)setupAttributes;
- (void)addAttribtuesToAttributedString:(NSMutableAttributedString *)output;

@end


static NSString * const startEmphMarker = @"\U0000f800";
static NSString * const endEmphMarker = @"\U0000f801";

static NSString * const startDoubleEmphMarker = @"\U0000f802";
static NSString * const endDoubleEmphMarker = @"\U0000f803";

static NSString * const startLinkMarker = @"\U0000f804";
static NSString * const endLinkMarker = @"\U0000f805";

static unichar const linkOffset = 0x0000f400;


//static void renderBlockcode(struct buf *ob, struct buf *text, void *opaque);
//static void renderBlockquote(struct buf *ob, struct buf *text, void *opaque);
//static void renderBlockhtml(struct buf *ob, struct buf *text, void *opaque);
//static void renderHeader(struct buf *ob, struct buf *text, int level, void *opaque);
//static void renderHrule(struct buf *ob, void *opaque);
//static void renderList(struct buf *ob, struct buf *text, int flags, void *opaque);
//static void renderListitem(struct buf *ob, struct buf *text, int flags, void *opaque);
static void renderParagraph(struct buf *ob, struct buf *text, void *opaque);
//static int renderAutolink(struct buf *ob, struct buf *link, enum mkd_autolink type, void *opaque);
//static int renderCodespan(struct buf *ob, struct buf *text, void *opaque);
static int renderDoubleEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
static int renderEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
//static int renderImage(struct buf *ob, struct buf *link, struct buf *title, struct buf *alt, void *opaque);
static int renderLinebreak(struct buf *ob, void *opaque);
static int renderLink(struct buf *ob, struct buf *link, struct buf *title, struct buf *content, void *opaque);
//static int renderRawHTMLTag(struct buf *ob, struct buf *tag, void *opaque);
//static int renderTripleEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
//static void renderEntity(struct buf *ob, struct buf *entity, void *opaque);
static void renderNormalText(struct buf *ob, struct buf *text, void *opaque);


@interface BOMarkdownParser ()

@property (nonatomic, strong) NSMutableArray *links;

@end



@implementation BOMarkdownParser

+ (instancetype)parser;
{
    return [[self alloc] init];
}

- (id)init;
{
    self = [super init];
    if (self) {
        [self setupAttributes];
    }
    return self;
}

- (NSAttributedString *)parseString:(NSString *)input;
{
    self.links = [NSMutableArray array];
    NSDictionary *baseAttributes = @{NSFontAttributeName: self.font, NSForegroundColorAttributeName: self.textColor};
    
    struct mkd_renderer renderer = {};
    
    renderer.opaque = (__bridge void *) self;
    renderer.emph_chars = "*_";
    // Callbacks:
    
//    renderer.blockcode = renderBlockcode;
//    renderer.blockquote = renderBlockquote;
//    renderer.blockhtml = renderBlockhtml;
//    renderer.header = renderHeader;
//    renderer.hrule = renderHrule;
//    renderer.list = renderList;
//    renderer.listitem = renderListitem;
    renderer.paragraph = renderParagraph;
//    renderer.autolink = renderAutolink;
//    renderer.codespan = renderCodespan;
    renderer.double_emphasis = renderDoubleEmphasis;
    renderer.emphasis = renderEmphasis;
//    renderer.image = renderImage;
    renderer.linebreak = renderLinebreak;
    renderer.link = renderLink;
//    renderer.raw_html_tag = renderRawHTMLTag;
//    renderer.triple_emphasis = renderTripleEmphasis;
//    renderer.entity = renderEntity;
    renderer.normal_text = renderNormalText;
    
    NSData *utf8InputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    struct buf * const inputBuffer = bufnew([utf8InputData length]);
    bufput(inputBuffer, [utf8InputData bytes], [utf8InputData length]);
    
    struct buf * const outputBuffer = bufnew(lround(((double) inputBuffer->size) * 1.2));
    
    markdown(outputBuffer, inputBuffer, &renderer);

    NSData *bufferData = [NSData dataWithBytes:outputBuffer->data length:outputBuffer->size];
    NSString *bufferString = [[NSString alloc] initWithData:bufferData encoding:NSUTF8StringEncoding];
    
    NSMutableAttributedString *_output = [[NSMutableAttributedString alloc] init];
    [_output appendAttributedString:[[NSAttributedString alloc] initWithString:bufferString attributes:baseAttributes]];
    
    [_output beginEditing];
    [self addAttribtuesToAttributedString:_output];
    [_output endEditing];
    
    NSAttributedString *result = [_output copy];
    _output = nil;
    bufrelease(outputBuffer);
    bufrelease(inputBuffer);
    
    return result;
}

@end



@implementation BOMarkdownParser (Private)

- (void)setupAttributes;
{
    self.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textColor = [UIColor blackColor];
    
    self.emphasizeFont = ^(UIFont *originalFont){
        CGFloat size = originalFont.pointSize;
        return [UIFont italicSystemFontOfSize:size];
    };

    self.doubleEmphasizeFont = ^(UIFont *originalFont){
        CGFloat size = originalFont.pointSize;
        return [UIFont boldSystemFontOfSize:size];
    };
    
    self.replaceLinkFont = self.emphasizeFont;
}

- (void)addAttribtuesToAttributedString:(NSMutableAttributedString *)output;
{
    [output updateFontAttributeInRangesWithStartMarker:startEmphMarker endMarker:endEmphMarker usingBlock:self.emphasizeFont];
    [output updateFontAttributeInRangesWithStartMarker:startDoubleEmphMarker endMarker:endDoubleEmphMarker usingBlock:self.doubleEmphasizeFont];
    
    [output addAttributesToRangeWithStartMarker:startLinkMarker endMarker:endLinkMarker usingAttributesBlock:^NSDictionary *(unichar marker){
        NSUInteger const linkIndex = (marker - linkOffset);
        if (linkIndex < [_links count]) {
            NSString *link = [_links objectAtIndex:linkIndex];
            return @{NSForegroundColorAttributeName: self.linkTextColor, BOAttribtuedStringLinkTargetKey: link};
        } else {
            return nil;
        }
    } fontBlock:self.replaceLinkFont];
}

@end


//static void renderBlockcode(UNUSED struct buf *ob, struct buf *text, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderBlockquote(UNUSED struct buf *ob, struct buf *text, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderBlockhtml(UNUSED struct buf *ob, struct buf *text, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderHeader(UNUSED struct buf *ob, struct buf *text, int level, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderHrule(UNUSED struct buf *ob, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderList(UNUSED struct buf *ob, struct buf *text, int flags, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderListitem(UNUSED struct buf *ob, struct buf *text, int flags, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
static void renderParagraph(UNUSED struct buf *ob, struct buf *text, void * UNUSED opaque)
{
    bufput(ob, text->data, text->size);
    bufputc(ob, '\n');
}

//static int renderAutolink(UNUSED struct buf *ob, struct buf *link, enum mkd_autolink type, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static int renderCodespan(UNUSED struct buf *ob, struct buf *text, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}

static int renderDoubleEmphasis(struct buf *ob, struct buf *text, char UNUSED c, void * UNUSED opaque)
{
    bufputs(ob, [startDoubleEmphMarker UTF8String]);
    bufput(ob, text->data, text->size);
    bufputs(ob, [endDoubleEmphMarker UTF8String]);
    return 1;
}

static int renderEmphasis(UNUSED struct buf *ob, struct buf *text, char UNUSED c, void * UNUSED opaque)
{
    bufputs(ob, [startEmphMarker UTF8String]);
    bufput(ob, text->data, text->size);
    bufputs(ob, [endEmphMarker UTF8String]);
    return 1;
}

//static int renderImage(UNUSED struct buf *ob, struct buf *link, struct buf *title, struct buf *alt, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}

static int renderLinebreak(struct buf *ob, void * UNUSED opaque)
{
    bufputc(ob, '\r');
    return 1;
}

static int renderLink(UNUSED struct buf *ob, struct buf *link, struct buf * UNUSED title, struct buf *content, void *opaque)
{
    NSData *linkData = [NSData dataWithBytes:link->data length:link->size];
    NSString *linkString = [[NSString alloc] initWithData:linkData encoding:NSUTF8StringEncoding];
    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
    [parser.links addObject:linkString];
    
    unichar const linkMarker = linkOffset + (unichar)([parser.links count]) - 1;
    NSString *startMarker = [startLinkMarker stringByAppendingString:[[NSString alloc] initWithCharacters:(const unichar []){linkMarker} length:1]];
    bufputs(ob, [startMarker UTF8String]);
    bufput(ob, content->data, content->size);
    bufputs(ob, [endLinkMarker UTF8String]);
    return 1;
}

//static int renderRawHTMLTag(UNUSED struct buf *ob, struct buf *tag, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static int renderTripleEmphasis(UNUSED struct buf *ob, struct buf *text, char c, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
//static void renderEntity(UNUSED struct buf *ob, struct buf *entity, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}

static void renderNormalText(struct buf *ob, struct buf *text, void * UNUSED opaque)
{
    bufput(ob, text->data, text->size);
}
