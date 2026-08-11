//
//  ZLChatViewController.m
//  ZLStreamingTextView
//

#import "ZLChatViewController.h"
#import <ZLStreamingTextView/ZLStreamingTextView.h>
// Generated header exposing the app-target Swift bridge (ZLDownBridge) to Objective-C.
#import "ZLStreamingTextView_Example-Swift.h"

@interface ZLChatViewController () <ZLStreamingTextViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *userBubble;
@property (nonatomic, strong) UIView *assistantBubble;
@property (nonatomic, strong) UILabel *typingLabel;
@property (nonatomic, strong) ZLStreamingTextView *streamingView;
@property (nonatomic, strong) NSLayoutConstraint *assistantHeightConstraint;

@property (nonatomic, assign) BOOL isResponding;
@end

@implementation ZLChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AI Chat";
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Regenerate" style:UIBarButtonItemStylePlain
                                        target:self action:@selector(startStreaming)];

    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isResponding && self.streamingView.totalLength == 0) {
        [self startStreaming];
    }
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    // User message bubble (blue, right aligned).
    self.userBubble = [self bubbleWithColor:[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]];
    UILabel *userLabel = [[UILabel alloc] init];
    userLabel.translatesAutoresizingMaskIntoConstraints = NO;
    userLabel.numberOfLines = 0;
    userLabel.textColor = [UIColor whiteColor];
    userLabel.font = [UIFont systemFontOfSize:17.0];
    userLabel.text = @"用 Markdown 介绍一下这个流式文本组件";
    [self.userBubble addSubview:userLabel];
    [self.contentView addSubview:self.userBubble];

    // Assistant bubble (white, left aligned) containing the streaming rich text.
    self.assistantBubble = [self bubbleWithColor:[UIColor whiteColor]];
    self.assistantBubble.layer.borderWidth = 1.0;
    self.assistantBubble.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;

    self.streamingView = [[ZLStreamingTextView alloc] init];
    self.streamingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.streamingView.delegate = self;
    self.streamingView.charactersPerFrame = 1;
    self.streamingView.frameInterval = 60;
    self.streamingView.textView.scrollEnabled = NO;
    self.streamingView.textView.textContainerInset = UIEdgeInsetsZero;
    self.streamingView.textView.textContainer.lineFragmentPadding = 0;
    [self.assistantBubble addSubview:self.streamingView];
    [self.contentView addSubview:self.assistantBubble];

    self.typingLabel = [[UILabel alloc] init];
    self.typingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.typingLabel.font = [UIFont systemFontOfSize:12.0];
    self.typingLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.typingLabel];

    CGFloat bubbleContentWidth = MIN([UIScreen mainScreen].bounds.size.width - 32.0, 300.0) - 24.0;
    self.streamingView.maxTextWidth = bubbleContentWidth;

    [userLabel.topAnchor constraintEqualToAnchor:self.userBubble.topAnchor constant:10].active = YES;
    [userLabel.bottomAnchor constraintEqualToAnchor:self.userBubble.bottomAnchor constant:-10].active = YES;
    [userLabel.leadingAnchor constraintEqualToAnchor:self.userBubble.leadingAnchor constant:12].active = YES;
    [userLabel.trailingAnchor constraintEqualToAnchor:self.userBubble.trailingAnchor constant:-12].active = YES;

    [self.streamingView.topAnchor constraintEqualToAnchor:self.assistantBubble.topAnchor constant:10].active = YES;
    [self.streamingView.bottomAnchor constraintEqualToAnchor:self.assistantBubble.bottomAnchor constant:-10].active = YES;
    [self.streamingView.leadingAnchor constraintEqualToAnchor:self.assistantBubble.leadingAnchor constant:12].active = YES;
    [self.streamingView.trailingAnchor constraintEqualToAnchor:self.assistantBubble.trailingAnchor constant:-12].active = YES;
    [self.streamingView.widthAnchor constraintEqualToConstant:bubbleContentWidth].active = YES;
    self.assistantHeightConstraint = [self.streamingView.heightAnchor constraintEqualToConstant:22];
    self.assistantHeightConstraint.active = YES;

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

        [self.userBubble.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [self.userBubble.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.userBubble.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:60],

        [self.typingLabel.topAnchor constraintEqualToAnchor:self.userBubble.bottomAnchor constant:12],
        [self.typingLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],

        [self.assistantBubble.topAnchor constraintEqualToAnchor:self.typingLabel.bottomAnchor constant:6],
        [self.assistantBubble.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.assistantBubble.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
    ]];
}

- (UIView *)bubbleWithColor:(UIColor *)color {
    UIView *bubble = [[UIView alloc] init];
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    bubble.backgroundColor = color;
    bubble.layer.cornerRadius = 14.0;
    bubble.layer.masksToBounds = YES;
    return bubble;
}

#pragma mark - Streaming simulation

/// Read the Markdown from the bundled READMETest.md resource.
- (NSString *)readmeMarkdown {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"READMETest" ofType:@"md"];
    NSString *content = path ? [NSString stringWithContentsOfFile:path
                                                         encoding:NSUTF8StringEncoding
                                                            error:NULL] : nil;
    return content.length > 0 ? content : @"# READMETest.md 未找到";
}

- (void)startStreaming {
    if (self.isResponding) { return; }
    self.isResponding = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.typingLabel.text = @"AI 正在输入…";
    [self.streamingView reset];

    // Parse the whole README with Down into one rich-text string (keeps tables,
    // code blocks and lists intact), then reveal it with the typewriter effect.
    NSString *markdown = [self readmeMarkdown];
    NSAttributedString *rich = [ZLDownBridge attributedStringFromMarkdown:markdown
                                                                 fontSize:16.0
                                                                textColor:[UIColor colorWithWhite:0.15 alpha:1.0]];
    if (rich.length == 0) {
        self.typingLabel.text = @"解析失败";
        self.isResponding = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        return;
    }

    // A slightly faster reveal since the README is long.
    self.streamingView.charactersPerFrame = 1;
    self.streamingView.frameInterval = 2;

    // Simulate a short "thinking" delay before the stream begins.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.streamingView startStreamingAttributedText:rich];
    });
}

#pragma mark - ZLStreamingTextViewDelegate

- (void)streamingTextView:(ZLStreamingTextView *)textView
     didChangeContentSize:(CGSize)contentSize {
    self.assistantHeightConstraint.constant = MAX(contentSize.height, 22.0);
    [self.view layoutIfNeeded];
    [self scrollToBottom];
}

- (void)streamingTextViewDidFinish:(ZLStreamingTextView *)textView {
    self.isResponding = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.typingLabel.text = @"完成 ✅";
}

- (void)scrollToBottom {
    CGFloat bottom = self.scrollView.contentSize.height - self.scrollView.bounds.size.height;
    if (bottom > 0) {
        [self.scrollView setContentOffset:CGPointMake(0, bottom) animated:NO];
    }
}

@end
