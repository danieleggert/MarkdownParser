//
//  MarkdownParserTests.m
//  MarkdownParserTests
//
//  Created by Daniel Eggert on 10/5/12.
//  Copyright (c) 2012 Bödewadt. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

#import "BOMarkdownParser.h"


#define BOAssertEqualRanges(a1, a2, description, ...) \
do { \
    @try {\
        if (strcmp(@encode(__typeof__(a1)), @encode(NSRange)) != 0) { \
            [self failWithException:([NSException failureInFile:[NSString stringWithUTF8String:__FILE__] \
                                                         atLine:__LINE__ \
                                                withDescription:@"%@", [@"Not a range -- " stringByAppendingString:STComposeString(description, ##__VA_ARGS__)]])]; \
        } \
        else if (strcmp(@encode(__typeof__(a2)), @encode(NSRange)) != 0) { \
            [self failWithException:([NSException failureInFile:[NSString stringWithUTF8String:__FILE__] \
                                                         atLine:__LINE__ \
                                                withDescription:@"%@", [@"Not a range -- " stringByAppendingString:STComposeString(description, ##__VA_ARGS__)]])]; \
        } \
        else { \
            NSRange const a1value = (a1); \
            NSRange const a2value = (a2); \
            NSValue *a1encoded = [NSValue value:&a1value withObjCType:@encode(__typeof__(a1))]; \
            NSValue *a2encoded = [NSValue value:&a2value withObjCType:@encode(__typeof__(a2))]; \
            if (!NSEqualRanges(a1value, a2value)) { \
                [self failWithException:([NSException failureInEqualityBetweenValue:a1encoded \
                                                                           andValue:a2encoded \
                                                                       withAccuracy:nil \
                                                                             inFile:[NSString stringWithUTF8String:__FILE__] \
                                                                             atLine:__LINE__ \
                                                                    withDescription:@"%@", STComposeString(description, ##__VA_ARGS__)])]; \
            } \
        } \
    } \
    @catch (id anException) {\
        [self failWithException:([NSException \
                 failureInRaise:[NSString stringWithFormat:@"(%s) == (%s)", #a1, #a2] \
                      exception:anException \
                         inFile:[NSString stringWithUTF8String:__FILE__] \
                         atLine:__LINE__ \
                withDescription:@"%@", STComposeString(description, ##__VA_ARGS__)])]; \
    }\
} while(0)





@interface MarkdownParserTests : SenTestCase
@end



@implementation MarkdownParserTests
{
    BOMarkdownParser *parser;
}

- (void)setUp
{
    [super setUp];
    parser = [NSClassFromString(@"BOMarkdownParser") parser];
    
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testEmphasis;
{
    NSAttributedString *output = [parser parseString:@"foo *bar* baz"];
    STAssertNotNil(output, @"");
    STAssertEquals([output length], (NSUInteger) 12, @"");
    STAssertEqualObjects([output string], @"foo bar baz\n", @"");
    
    NSRange range;
    NSDictionary *attr = [output attributesAtIndex:0 longestEffectiveRange:&range inRange:NSMakeRange(0, [output length])];
    NSDictionary *should = @{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont systemFontOfSize:14.]};
    STAssertEqualObjects(attr, should, @"");
    BOAssertEqualRanges(range, NSMakeRange(0, 4), @"");

    attr = [output attributesAtIndex:6 longestEffectiveRange:&range inRange:NSMakeRange(0, [output length])];
    should = @{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont italicSystemFontOfSize:14.]};
    STAssertEqualObjects(attr, should, @"");
    BOAssertEqualRanges(range, NSMakeRange(4, 3), @"");

    attr = [output attributesAtIndex:8 longestEffectiveRange:&range inRange:NSMakeRange(0, [output length])];
    should = @{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont systemFontOfSize:14.]};
    STAssertEqualObjects(attr, should, @"");
    BOAssertEqualRanges(range, NSMakeRange(7, 5), @"");
}

@end
