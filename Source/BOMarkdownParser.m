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



@interface BOMarkdownParser (Private)

- (void)setupAttributes;
- (void)preParseSetupAttributes;
- (void)addAttributesToAttributedString:(NSMutableAttributedString *)output;

@end


static NSString * const startEmphMarker = @"\U0000f800";
static NSString * const endEmphMarker = @"\U0000f801";

static NSString * const startDoubleEmphMarker = @"\U0000f802";
static NSString * const endDoubleEmphMarker = @"\U0000f803";

static NSString * const startLinkMarker = @"\U0000f804";
static NSString * const endLinkMarker = @"\U0000f805";

static NSString * const startImageMarker = @"\U0000f806";
static NSString * const endImageMarker = @"\U0000f807";

static NSString * const startImageTitleMarker = @"\U0000f808";
static NSString * const endImageTitleMarker = @"\U0000f809";

// We use these for multiple indentation
static NSString * const startListMarker[] = {@"\U0000f810", @"\U0000f811", @"\U0000f812"};
static NSString * const endListMarker[] = {@"\U0000f820", @"\U0000f821", @"\U0000f822"};

static NSString * const startListItemMarker[] = {@"\U0000f818", @"\U0000f819", @"\U0000f81a"};
static NSString * const endListItemMarker[] = {@"\U0000f828", @"\U0000f829", @"\U0000f82a"};

static NSString * const startHeaderMarker[] = {@"\U0000f830", @"\U0000f831", @"\U0000f832", @"\U0000f833", @"\U0000f834", @"\U0000f835"};
static NSString * const endHeaderMarker[] = {@"\U0000f840", @"\U0000f841", @"\U0000f842", @"\U0000f843", @"\U0000f844", @"\U0000f845"};

static unichar const linkOffset = 0x0000f400;
static unichar const imageOffset = 0x0000f500;


//static void renderBlockcode(struct buf *ob, struct buf *text, void *opaque);
//static void renderBlockquote(struct buf *ob, struct buf *text, void *opaque);
//static void renderBlockhtml(struct buf *ob, struct buf *text, void *opaque);
static void renderHeader(struct buf *ob, struct buf *text, int level, void *opaque);
//static void renderHrule(struct buf *ob, void *opaque);
static void renderList(struct buf *ob, struct buf *text, int flags, void *opaque);
static void renderListitem(struct buf *ob, struct buf *text, int flags, void *opaque);
static void renderParagraph(struct buf *ob, struct buf *text, void *opaque);
static int renderAutolink(struct buf *ob, struct buf *link, enum mkd_autolink type, void *opaque);
//static int renderCodespan(struct buf *ob, struct buf *text, void *opaque);
static int renderDoubleEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
static int renderEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
static int renderImage(struct buf *ob, struct buf *link, struct buf *title, struct buf *alt, void *opaque);
static int renderLinebreak(struct buf *ob, void *opaque);
static int renderLink(struct buf *ob, struct buf *linkBuffer, struct buf *title, struct buf *content, void *opaque);
//static int renderRawHTMLTag(struct buf *ob, struct buf *tag, void *opaque);
//static int renderTripleEmphasis(struct buf *ob, struct buf *text, char c, void *opaque);
//static void renderEntity(struct buf *ob, struct buf *entity, void *opaque);
static void renderNormalText(struct buf *ob, struct buf *text, void *opaque);


@interface BOMarkdownParser ()

@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic) int listDepth;
@property (nonatomic) int listItemIndex;

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
    if (input == nil) {
        return nil;
    }
    
    [self preParseSetupAttributes];
    
    struct mkd_renderer renderer = {};
    
    renderer.opaque = (__bridge void *) self;
    renderer.emph_chars = "*_";
    // Callbacks:
    
//    renderer.blockcode = renderBlockcode;
//    renderer.blockquote = renderBlockquote;
//    renderer.blockhtml = renderBlockhtml;
    renderer.header = renderHeader;
//    renderer.hrule = renderHrule;
    renderer.list = renderList;
    renderer.listitem = renderListitem;
    renderer.paragraph = renderParagraph;
    renderer.autolink = renderAutolink;
//    renderer.codespan = renderCodespan;
    renderer.double_emphasis = renderDoubleEmphasis;
    renderer.emphasis = renderEmphasis;
    renderer.image = renderImage;
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
    
    NSMutableAttributedString *outputText = [[NSMutableAttributedString alloc] init];
    [outputText appendAttributedString:[[NSAttributedString alloc] initWithString:bufferString attributes:self.baseAttributes]];
    
    [outputText beginEditing];
    [self addAttributesToAttributedString:outputText];
    [outputText endEditing];
    
    bufrelease(outputBuffer);
    bufrelease(inputBuffer);
    
    return outputText;
}

- (NSString *)linkAttributeName;
{
    return @"BOLink";
}

- (NSURL *)linkURLFromLinkString:(NSString *)linkString;
{
    return (linkString == nil) ? nil : [NSURL URLWithString:linkString];
}

@end



@implementation BOMarkdownParser (Private)

- (void)setupAttributes;
{
    self.unorderedListBullet = @"•";
    self.listNumberFromIndex = ^(int listIndex){
        return [NSString stringWithFormat:@"%d.", listIndex];
    };
    NSMutableParagraphStyle *listParagraph = [[NSMutableParagraphStyle alloc] init];
    listParagraph.headIndent = 16.;
    listParagraph.firstLineHeadIndent = -16.;
//    self.listAttributes = @[];
//    self.listItemAttributes = @[];
    
    self.baseAttributes = @{};
    
    self.emphasizeFont = nil;
    self.doubleEmphasizeFont = nil;
    self.replaceLinkFont = nil;
}

- (void)preParseSetupAttributes;
{
    self.links = [NSMutableArray array];
    self.images = [NSMutableArray array];
    self.listDepth = 0;
    self.listItemIndex = 0;
}

- (void)addAttributesToAttributedString:(NSMutableAttributedString *)output;
{
    [output replaceAttributesInRangeWithStartMarker:startEmphMarker endMarker:endEmphMarker withReplacementBlock:self.emphasizeFont];
    [output replaceAttributesInRangeWithStartMarker:startDoubleEmphMarker endMarker:endDoubleEmphMarker withReplacementBlock:self.doubleEmphasizeFont];
    
    [output addAttributesToRangeWithStartMarker:startLinkMarker endMarker:endLinkMarker markedAttributesBlock:^NSDictionary *(unichar marker){
        NSUInteger const linkIndex = (marker - linkOffset);
        if (linkIndex < [self.links count]) {
            id link = [self.links objectAtIndex:linkIndex];
            return @{self.linkAttributeName: link};
        } else {
            return nil;
        }
    } replacementBlock:self.replaceLinkFont];
    
    [output addAttributesToRangeWithStartMarker:startImageMarker endMarker:endImageMarker markedAttributesBlock:^NSDictionary *(unichar marker){
        NSUInteger const imageIndex = (marker - imageOffset);
        if ((imageIndex < [self.images count]) && (self.insertImage != nil)) {
            BOMarkdownParserImage *image = self.images[imageIndex];
            return self.insertImage(image);
        } else {
            return nil;
        }
    } replacementBlock:nil];
    
    [output replaceAttributesInRangeWithStartMarker:startImageTitleMarker endMarker:endImageTitleMarker withReplacementBlock:self.imageTitleAttributes];
    
    [output replaceAttributesInRangeWithStartMarker:startListMarker[0] endMarker:endListMarker[0] withReplacementBlock:self.listAttributes];
    [output replaceAttributesInRangeWithStartMarker:startListItemMarker[0] endMarker:endListItemMarker[0] withReplacementBlock:self.listItemAttributes];
    
    for (int level = 0; level < 6; ++level) {
        BOAttributesReplacementBlock_t attributesBlock = (level < (int) [self.headerAttributes count]) ? self.headerAttributes[level] : nil;
        [output replaceAttributesInRangeWithStartMarker:startHeaderMarker[level] endMarker:endHeaderMarker[level] withReplacementBlock:attributesBlock];
    }
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

static void renderHeader(UNUSED struct buf *ob, struct buf *text, int level, void * UNUSED opaque)
{
    int const levelCount = (int) (sizeof(startHeaderMarker) / sizeof(*startHeaderMarker));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"
    int const clampedLevel = MAX(MIN(level - 1, levelCount - 1), 0);
#pragma clang diagnostic pop
    bufputs(ob, [startHeaderMarker[clampedLevel] UTF8String]);
    bufput(ob, text->data, text->size);
    bufputc(ob, '\n');
    bufputs(ob, [endHeaderMarker[clampedLevel] UTF8String]);
}

//static void renderHrule(UNUSED struct buf *ob, void *opaque)
//{
//    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
//}
//
static void renderList(UNUSED struct buf *ob, struct buf *text, int UNUSED flags, void *opaque)
{
    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
    int const depth = parser.listDepth;
    
    bufputs(ob, [startListMarker[depth] UTF8String]);
    bufput(ob, text->data, text->size);
    bufputs(ob, [endListMarker[depth] UTF8String]);
}

static void renderListitem(UNUSED struct buf *ob, struct buf *text, int flags, void *opaque)
{
    BOOL const isOrdered = ((flags & MKD_LIST_ORDERED) != 0);
    //BOOL const isBlock = ((flags & MKD_LI_BLOCK) != 0);
    BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
    int const depth = parser.listDepth;
    
    NSString *bullet = parser.unorderedListBullet;
    if (isOrdered) {
        int const index = parser.listItemIndex + 1;
        parser.listItemIndex = index;
        bullet = parser.listNumberFromIndex(index);
    }
    
    bufputs(ob, [startListItemMarker[depth] UTF8String]);
    bufputs(ob, [bullet UTF8String]);
    bufputs(ob, "\t");
    bufput(ob, text->data, text->size);
    bufputs(ob, [endListItemMarker[depth] UTF8String]);
}

static void renderParagraph(UNUSED struct buf *ob, struct buf *text, void * UNUSED opaque)
{
    bufput(ob, text->data, text->size);
    bufputc(ob, '\n');
}

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

static int renderImage(UNUSED struct buf *ob, struct buf *linkBuffer, struct buf *title, struct buf *alt, void *opaque)
{
    NSData *linkData = [NSData dataWithBytes:linkBuffer->data length:linkBuffer->size];
    NSString *linkString = [[NSString alloc] initWithData:linkData encoding:NSUTF8StringEncoding];
    if (linkString != nil) {
        BOMarkdownParserImage *image = [[BOMarkdownParserImage alloc] init];
        image.link = linkString;
        
        NSData *altData = [NSData dataWithBytes:alt->data length:alt->size];
        NSString *altString = [[NSString alloc] initWithData:altData encoding:NSUTF8StringEncoding];
        image.alt = altString;
        
        BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
        
        [parser.images addObject:image];
        
        unichar const imageMarker = imageOffset + (unichar)([parser.images count]) - 1;
        NSString *startMarker = [startImageMarker stringByAppendingString:[[NSString alloc] initWithCharacters:(const unichar []){imageMarker} length:1]];
        bufputs(ob, [startMarker UTF8String]);
        bufputs(ob, [@" " UTF8String]); // zero width space
        bufputs(ob, [endImageMarker UTF8String]);
        
        if ((title != NULL) && (0 < title->size)) {
            bufputc(ob, '\n');
            bufputs(ob, [startImageTitleMarker UTF8String]);
            bufput(ob, title->data, title->size);
            bufputs(ob, [endImageTitleMarker UTF8String]);
        }
    } else {
        NSLog(@"Unable to add image.");
    }
    return 1;
}

static int renderLinebreak(struct buf *ob, void * UNUSED opaque)
{
    bufputc(ob, '\r');
    return 1;
}

static int renderAutolink(UNUSED struct buf *ob, struct buf *linkBuffer, enum mkd_autolink type, void *opaque)
{
    struct buf *title = linkBuffer;
    struct buf *link = linkBuffer;
    struct buf *newLink = NULL;
    if (type == MKDA_IMPLICIT_EMAIL) {
        newLink = bufnew(linkBuffer->size + 7);
        bufputs(newLink, "mailto:");
        bufput(newLink, linkBuffer->data, linkBuffer->size);
        link = newLink;
    }
    int result = renderLink(ob, link, NULL, title, opaque);
    if (newLink != NULL) {
        bufrelease(newLink);
    }
    return result;
}

static int renderLink(UNUSED struct buf *ob, struct buf *linkBuffer, struct buf * UNUSED title, struct buf *content, void *opaque)
{
    NSData *linkData = [NSData dataWithBytes:linkBuffer->data length:linkBuffer->size];
    NSString *linkString = [[NSString alloc] initWithData:linkData encoding:NSUTF8StringEncoding];
    if (linkString != nil) {
        BOMarkdownParser * const parser = (__bridge BOMarkdownParser *) opaque;
        NSURL *link = [parser linkURLFromLinkString:linkString];
        [parser.links addObject:(link == nil) ? linkString : link];
        
        unichar const linkMarker = linkOffset + (unichar)([parser.links count]) - 1;
        NSString *startMarker = [startLinkMarker stringByAppendingString:[[NSString alloc] initWithCharacters:(const unichar []){linkMarker} length:1]];
        bufputs(ob, [startMarker UTF8String]);
        bufput(ob, content->data, content->size);
        bufputs(ob, [endLinkMarker UTF8String]);
    } else {
        NSLog(@"Unable to create URL from link '%@'", linkString);
        bufput(ob, content->data, content->size);
    }
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


@implementation BOMarkdownParserImage
@end
