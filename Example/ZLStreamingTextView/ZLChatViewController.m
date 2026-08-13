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
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"READMETest" ofType:@"md"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"md"];

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

    // Parse the whole Markdown with Down into one rich-text string (keeps tables,
    // code blocks and lists intact), then reveal it with the typewriter effect.
    NSString *markdown = [self readmeMarkdown];
    NSAttributedString *parsed = [ZLDownBridge attributedStringFromMarkdown:markdown
                                                                   fontSize:16.0
                                                                  textColor:[UIColor colorWithWhite:0.15 alpha:1.0]];
    if (parsed.length == 0) {
        self.typingLabel.text = @"解析失败";
        self.isResponding = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        return;
    }

    NSMutableAttributedString *rich = [parsed mutableCopy];

    // Down 默认把 Markdown 图片渲染成「alt 文本 + link 属性」，不会生成 NSTextAttachment；
    // 我们在 Swift 侧的自定义 styler 里把图片改成了带 URL 的占位 NSTextAttachment。
    // 这里找出所有图片附件，读取其上的 ZLImageURL 属性，异步下载后回填图片，再开始流式打印。
    NSString *imageURLKey = ZLDownBridge.imageURLAttributeName;
    NSMutableArray<NSValue *> *attachmentRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *attachmentURLs = [NSMutableArray array];
    [rich enumerateAttribute:NSAttachmentAttributeName
                     inRange:NSMakeRange(0, rich.length)
                     options:0
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (![value isKindOfClass:[NSTextAttachment class]]) { return; }
        NSString *urlStr = [rich attribute:imageURLKey atIndex:range.location effectiveRange:NULL];
        if (urlStr.length == 0) { return; }
        [attachmentRanges addObject:[NSValue valueWithRange:range]];
        [attachmentURLs addObject:urlStr];
    }];

    CGFloat maxImageWidth = MIN([UIScreen mainScreen].bounds.size.width - 32.0, 300.0) - 24.0;
    NSInteger pairCount = attachmentRanges.count;

    if (pairCount > 0) {
        self.typingLabel.text = @"正在加载图片…";
    }

    dispatch_group_t group = dispatch_group_create();
    for (NSInteger i = 0; i < pairCount; i++) {
        NSURL *url = [NSURL URLWithString:attachmentURLs[i]];
        if (!url) { continue; }
        NSRange range = [attachmentRanges[i] rangeValue];

        dispatch_group_enter(group);
        NSURLSessionDataTask *task =
            [[NSURLSession sharedSession] dataTaskWithURL:url
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            UIImage *image = data.length > 0 ? [UIImage imageWithData:data] : nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image && NSMaxRange(range) <= rich.length) {
                    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                    attachment.image = image;
                    // 按气泡宽度等比缩放。
                    CGFloat w = MIN(image.size.width, maxImageWidth);
                    CGFloat h = image.size.width > 0 ? image.size.height * (w / image.size.width) : image.size.height;
                    attachment.bounds = CGRectMake(0, 0, floor(w), floor(h));
                    [rich addAttribute:NSAttachmentAttributeName value:attachment range:range];
                }
                dispatch_group_leave(group);
            });
        }];
        [task resume];
    }

    // 图片全部下载完成（或无图片）后开始逐帧流式打印。
    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.typingLabel.text = @"AI 正在输入…";
        self.streamingView.charactersPerFrame = 1;
        self.streamingView.frameInterval = 2;
        [self.streamingView startStreamingAttributedText:rich];
    });
}

/// 用正则从 Markdown 中按出现顺序提取图片 URL：匹配 `![alt](url)`。
- (NSArray<NSString *> *)imageURLStringsInMarkdown:(NSString *)markdown {
    if (markdown.length == 0) { return @[]; }
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:@"!\\[[^\\]]*\\]\\(\\s*<?([^)>\\s]+)"
                                                  options:0
                                                    error:NULL];
    [re enumerateMatchesInString:markdown
                         options:0
                           range:NSMakeRange(0, markdown.length)
                      usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        if (match.numberOfRanges > 1) {
            [urls addObject:[markdown substringWithRange:[match rangeAtIndex:1]]];
        }
    }];
    return urls;
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
