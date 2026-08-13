//
//  ZLViewController.m
//  ZLStreamingTextView
//
//  Created by fanpeng on 08/11/2026.
//  Copyright (c) 2026 fanpeng. All rights reserved.
//

#import "ZLViewController.h"
#import <ZLStreamingTextView/ZLStreamingTextView.h>
#import "ZLChatViewController.h"

/// Demo screen that pre-calculates text/rich-text sizes before displaying them.
@interface ZLSizeCalcViewController : UIViewController
@end

@interface ZLViewController () <ZLStreamingTextViewDelegate>
@property (nonatomic, strong) ZLStreamingTextView *streamingView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSLayoutConstraint *streamingWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *streamingHeightConstraint;
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Streaming TextView";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupStreamingView];
    [self setupControls];
}

- (void)setupStreamingView {
    self.streamingView = [[ZLStreamingTextView alloc] init];
    self.streamingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.streamingView.delegate = self;
    self.streamingView.charactersPerFrame = 1;   // reveal 1 char per frame
    self.streamingView.frameInterval = 2;        // ...every 2 screen frames (~30 chars/sec on 60Hz)
    self.streamingView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.streamingView.layer.borderWidth = 1.0;
    self.streamingView.layer.cornerRadius = 8.0;
    self.streamingView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.streamingView.textView.font = [UIFont systemFontOfSize:17.0];

    // Constrain the text layout width, and cap the height so it scrolls when too tall.
    CGFloat maxW = MIN([UIScreen mainScreen].bounds.size.width - 32.0, 320.0);
    self.streamingView.maxTextWidth = [UIScreen mainScreen].bounds.size.width - 32.0;
    self.streamingView.maxTextHeight = 320.0;
    self.streamingView.minTextWidth = 100;
    self.streamingView.minTextHeight = 34;
    [self.view addSubview:self.streamingView];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:12.0];
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = @"Ready";
    [self.view addSubview:self.statusLabel];

    __weak typeof(self) weakSelf = self;
    self.streamingView.onComplete = ^{
        weakSelf.statusLabel.text = @"Done ✅";
    };

    // Width / height constraints are updated live from the content-size callback.
//    self.streamingWidthConstraint = [self.streamingView.widthAnchor constraintEqualToConstant:maxW];
//    self.streamingHeightConstraint = [self.streamingView.heightAnchor constraintEqualToConstant:44];
//    self.streamingWidthConstraint.active = YES;
//    self.streamingHeightConstraint.active = YES;

    if (@available(iOS 11.0, *)) {
        UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [self.streamingView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:16],
            [self.streamingView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
            [self.statusLabel.topAnchor constraintEqualToAnchor:self.streamingView.bottomAnchor constant:8],
            [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
            [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.streamingView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:16],
            [self.streamingView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
            [self.statusLabel.topAnchor constraintEqualToAnchor:self.streamingView.bottomAnchor constant:8],
            [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
            [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        ]];
    }
}

- (void)setupControls {
    UIButton *plainButton = [self buttonWithTitle:@"Plain Text" action:@selector(onPlainText)];
    UIButton *richButton  = [self buttonWithTitle:@"Rich Text"  action:@selector(onRichText)];
    UIButton *streamButton= [self buttonWithTitle:@"Simulate Stream" action:@selector(onSimulateStream)];
    UIButton *skipButton  = [self buttonWithTitle:@"Skip"  action:@selector(onSkip)];
    UIButton *resetButton = [self buttonWithTitle:@"Reset" action:@selector(onReset)];
    UIButton *chatButton  = [self buttonWithTitle:@"AI Chat (Down Markdown)" action:@selector(onOpenChat)];
    UIButton *sizeButton  = [self buttonWithTitle:@"Pre-calc Size" action:@selector(onOpenSizeCalc)];
    UIButton *offsetButton= [self buttonWithTitle:@"Start From Offset" action:@selector(onStartFromOffset)];

    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[plainButton, richButton, streamButton]];
    row1.axis = UILayoutConstraintAxisHorizontal;
    row1.distribution = UIStackViewDistributionFillEqually;
    row1.spacing = 12;

    UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[skipButton, resetButton]];
    row2.axis = UILayoutConstraintAxisHorizontal;
    row2.distribution = UIStackViewDistributionFillEqually;
    row2.spacing = 12;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[row1, row2, chatButton, sizeButton, offsetButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    if (@available(iOS 11.0, *)) {
        UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:16],
            [stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
            [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:16],
            [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
            [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        ]];
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0];
    button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    button.layer.cornerRadius = 6.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(10, 8, 10, 8);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Actions

- (void)onPlainText {
    self.statusLabel.text = @"Streaming plain text...";
    NSString *text = @"这是一个逐帧打印的示例。ZLStreamingTextView 使用 CADisplayLink 按帧逐字显示文本，"
                     @"支持纯文本与富文本，也支持模拟网络流式追加。\n\n"
                     @"Hello! This text is printed frame by frame, character by character, like a typewriter. 🚀";
    [self.streamingView startStreamingText:text];
}

- (void)onRichText {
    self.statusLabel.text = @"Streaming rich text...";
    NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] init];

    NSDictionary *title = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:22],
                             NSForegroundColorAttributeName: [UIColor blueColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"富文本标题\n" attributes:title]];

    NSDictionary *body = @{ NSFontAttributeName: [UIFont systemFontOfSize:17],
                            NSForegroundColorAttributeName: [UIColor darkGrayColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"这段文字是普通正文，" attributes:body]];

    NSDictionary *highlight = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
                                 NSForegroundColorAttributeName: [UIColor whiteColor],
                                 NSBackgroundColorAttributeName: [UIColor magentaColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"这里是高亮" attributes:highlight]];
    
    UIImage *image = [UIImage imageNamed:@"image"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -4, 28, 66);
    NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];
    [rich appendAttributedString:imageString];

    NSDictionary *underline = @{ NSFontAttributeName: [UIFont italicSystemFontOfSize:17],
                                 NSForegroundColorAttributeName: [UIColor greenColor],
                                 NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"，还有下划线斜体。\n" attributes:underline]];

    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"Rich text streams frame by frame too! ✨" attributes:body]];

    [self.streamingView startStreamingAttributedText:rich];
}

- (void)onSimulateStream {
    self.statusLabel.text = @"Simulating network stream...";
    [self.streamingView reset];

    NSArray<NSString *> *chunks = @[ @"正在思考", @"……\n", @"根据你的问题，", @"我认为答案是：",
                                     @"逐帧流式输出", @"可以带来", @"更好的交互体验。", @"\n\n完成。✅" ];
    [self appendChunks:chunks atIndex:0];
}

- (void)appendChunks:(NSArray<NSString *> *)chunks atIndex:(NSUInteger)index {
    if (index >= chunks.count) { return; }
    [self.streamingView appendText:chunks[index]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self appendChunks:chunks atIndex:index + 1];
    });
}

- (void)onSkip {
    [self.streamingView finishImmediately];
}

- (void)onReset {
    [self.streamingView reset];
    self.statusLabel.text = @"Ready";
}

- (void)onOpenChat {
    ZLChatViewController *chat = [[ZLChatViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:chat];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onOpenSizeCalc {
    ZLSizeCalcViewController *vc = [[ZLSizeCalcViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onStartFromOffset {
    // The prefix (before the marker) is shown instantly; streaming begins from `startLength`.
    NSString *prefix = @"【已加载】前面这段文字直接展示，";
    NSString *rest   = @"从这里开始逐帧打字机式地流式输出剩余内容～ ✨\n"
                       @"适合断点续传 / 恢复上次进度的场景。";
    NSString *text = [prefix stringByAppendingString:rest];

    self.statusLabel.text = [NSString stringWithFormat:@"从第 %lu 个字符开始流式", (unsigned long)prefix.length];
    self.streamingView.charactersPerFrame = 1;
    self.streamingView.frameInterval = 2;
    [self.streamingView startStreamingText:text fromLength:prefix.length];
}

#pragma mark - ZLStreamingTextViewDelegate

- (void)streamingTextView:(ZLStreamingTextView *)textView
   didUpdateVisibleLength:(NSUInteger)visibleLength
              totalLength:(NSUInteger)totalLength {
    self.statusLabel.text = [NSString stringWithFormat:@"%lu / %lu",
                             (unsigned long)visibleLength, (unsigned long)totalLength];
}

- (void)streamingTextViewDidFinish:(ZLStreamingTextView *)textView {
    self.statusLabel.text = @"Done ✅";
}

- (void)streamingTextView:(ZLStreamingTextView *)textView
     didChangeContentSize:(CGSize)contentSize {
    self.title = [NSString stringWithFormat:@"W %.0f  H %.0f",
                  contentSize.width, contentSize.height];

    // Dynamically resize the bordered view so it hugs the streamed text.
    CGFloat width = MAX(contentSize.width, 60.0);
    CGFloat height = MAX(contentSize.height, 44.0);
    self.streamingWidthConstraint.constant = contentSize.width;
    self.streamingHeightConstraint.constant = contentSize.height;

//    [UIView animateWithDuration:0.15
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseOut
//                     animations:^{
//        [self.view layoutIfNeeded];
//    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

#pragma mark - Pre-calculate size demo

@implementation ZLSizeCalcViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pre-calc Size";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self action:@selector(close)];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 20;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    UILayoutGuide *guide = self.view.layoutMarginsGuide;
    if (@available(iOS 11.0, *)) {
        guide = self.view.safeAreaLayoutGuide;
    }
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-16],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-32],
    ]];

    CGFloat maxWidth = MIN([UIScreen mainScreen].bounds.size.width - 32.0, 320.0);

    // Case 1: short plain text.
    [stack addArrangedSubview:[self cardWithTitle:@"纯文本（短）"
                                       attributed:[self plainAttributed:@"Hello 世界 👋"]
                                         maxWidth:maxWidth]];

    // Case 2: long plain text that wraps to multiple lines.
    [stack addArrangedSubview:[self cardWithTitle:@"纯文本（换行）"
                                       attributed:[self plainAttributed:
        @"提前计算宽高：先用 sizeForAttributedText:maxWidth:... 得到尺寸，再据此布局，避免闪动。"]
                                         maxWidth:maxWidth]];

    // Case 3: rich text with mixed fonts / sizes.
    [stack addArrangedSubview:[self cardWithTitle:@"富文本（混排）"
                                       attributed:[self richAttributed]
                                         maxWidth:maxWidth]];
    
    
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Sample content

- (NSAttributedString *)plainAttributed:(NSString *)text {
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:17.0],
                                                         NSForegroundColorAttributeName: [UIColor darkGrayColor] }];
}

- (NSAttributedString *)richAttributed {
    NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] init];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"标题大字\n"
        attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:22], NSForegroundColorAttributeName: [UIColor blueColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"正文加上"
        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor darkGrayColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"高亮"
        attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16], NSForegroundColorAttributeName: [UIColor whiteColor], NSBackgroundColorAttributeName: [UIColor magentaColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"，混排富文本也能精确测量。"
        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor darkGrayColor] }]];
    return rich;
}

#pragma mark - Card

/// Build a card that shows the pre-calculated size and a streaming view sized EXACTLY to it,
/// proving the measured size matches the rendered content.
- (UIView *)cardWithTitle:(NSString *)title
               attributed:(NSAttributedString *)attributed
                 maxWidth:(CGFloat)maxWidth {
    UIEdgeInsets inset = UIEdgeInsetsMake(8, 8, 8, 8);
    CGFloat padding = 5.0;

    // 1) Pre-calculate the size BEFORE creating / displaying the view.
    CGSize size = CGSizeZero;
    {
        ZLStreamingTextView *textView = [[ZLStreamingTextView alloc] initWithTextView:nil];
        textView.maxTextWidth = maxWidth;
        textView.textView.attributedText = attributed;
        textView.textView.textContainerInset = inset;
        textView.textView.textContainer.lineFragmentPadding = padding;
        size = [textView textContentSize];
        NSLog(@"Pre-calculated size for '%@': %.0f × %.0f", title, size.width, size.height);
    }

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *caption = [[UILabel alloc] init];
    caption.translatesAutoresizingMaskIntoConstraints = NO;
    caption.numberOfLines = 0;
    caption.font = [UIFont systemFontOfSize:13.0];
    caption.textColor = [UIColor grayColor];
    caption.text = [NSString stringWithFormat:@"%@\n预计算尺寸(maxWidth=%.0f): %.0f × %.0f",
                    title, maxWidth, size.width, size.height];
    [card addSubview:caption];

    // 2) Create a streaming view constrained to the pre-calculated size and show the content.
    ZLStreamingTextView *view = [[ZLStreamingTextView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.textView.textContainerInset = inset;
    view.textView.textContainer.lineFragmentPadding = padding;
    view.textView.scrollEnabled = NO;
    view.layer.borderColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0].CGColor;
    view.layer.borderWidth = 1.0;
    view.layer.cornerRadius = 6.0;
    view.charactersPerFrame = 2;
    view.maxTextWidth = size.width;
    [view startStreamingAttributedText:attributed];
    [card addSubview:view];

    [NSLayoutConstraint activateConstraints:@[
        [caption.topAnchor constraintEqualToAnchor:card.topAnchor],
        [caption.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [caption.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],

        [view.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:6],
        [view.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [view.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        // The exact pre-calculated size:
        [view.widthAnchor constraintEqualToConstant:size.width],
        [view.heightAnchor constraintEqualToConstant:size.height],
    ]];
    return card;
}

@end
