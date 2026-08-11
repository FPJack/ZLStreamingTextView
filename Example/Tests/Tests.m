//
//  ZLStreamingTextViewTests.m
//  ZLStreamingTextViewTests
//
//  Created by fanpeng on 08/11/2026.
//  Copyright (c) 2026 fanpeng. All rights reserved.
//

@import XCTest;
#import <ZLStreamingTextView/ZLStreamingTextView.h>

@interface Tests : XCTestCase
@property (nonatomic, strong) ZLStreamingTextView *view;
@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    self.view = [[ZLStreamingTextView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
}

- (void)tearDown
{
    self.view = nil;
    [super tearDown];
}

- (void)testInitialState
{
    XCTAssertNotNil(self.view.textView);
    XCTAssertFalse(self.view.isStreaming);
    XCTAssertEqual(self.view.visibleLength, (NSUInteger)0);
    XCTAssertEqual(self.view.totalLength, (NSUInteger)0);
}

- (void)testStartStreamingBuffersFullText
{
    NSString *text = @"Hello 逐帧打印";
    [self.view startStreamingText:text];
    XCTAssertEqual(self.view.totalLength, text.length);
    XCTAssertTrue(self.view.isStreaming);
}

- (void)testFinishImmediatelyRevealsEverything
{
    NSString *text = @"Frame by frame text.";
    [self.view startStreamingText:text];
    [self.view finishImmediately];

    XCTAssertEqual(self.view.visibleLength, text.length);
    XCTAssertFalse(self.view.isStreaming);
    XCTAssertEqualObjects(self.view.textView.text, text);
}

- (void)testAppendGrowsBuffer
{
    [self.view reset];
    [self.view appendText:@"AAA"];
    [self.view appendText:@"BBB"];
    XCTAssertEqual(self.view.totalLength, (NSUInteger)6);
}

- (void)testResetClearsState
{
    [self.view startStreamingText:@"Some content"];
    [self.view reset];
    XCTAssertEqual(self.view.totalLength, (NSUInteger)0);
    XCTAssertEqual(self.view.visibleLength, (NSUInteger)0);
    XCTAssertFalse(self.view.isStreaming);
    XCTAssertEqualObjects(self.view.textView.text, @"");
}

- (void)testAttributedTextPreservedAfterFinish
{
    NSDictionary *attrs = @{ NSForegroundColorAttributeName: [UIColor redColor] };
    NSAttributedString *rich = [[NSAttributedString alloc] initWithString:@"Rich" attributes:attrs];
    [self.view startStreamingAttributedText:rich];
    [self.view finishImmediately];

    XCTAssertEqual(self.view.textView.attributedText.length, (NSUInteger)4);
    UIColor *color = [self.view.textView.attributedText attribute:NSForegroundColorAttributeName
                                                          atIndex:0
                                                   effectiveRange:NULL];
    XCTAssertEqualObjects(color, [UIColor redColor]);
}

- (void)testStreamingCompletesOverTime
{
    self.view.charactersPerFrame = 5;
    self.view.frameInterval = 1;
    XCTestExpectation *exp = [self expectationWithDescription:@"streaming completes"];
    self.view.onComplete = ^{ [exp fulfill]; };
    [self.view startStreamingText:@"Streaming completion callback test."];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqual(self.view.visibleLength, self.view.totalLength);
}

@end

