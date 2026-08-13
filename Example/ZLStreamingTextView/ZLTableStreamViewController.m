//
//  ZLTableStreamViewController.m
//  ZLStreamingTextView
//

#import "ZLTableStreamViewController.h"
#import <ZLStreamingTextView/ZLStreamingTextView.h>
#import "ZLStreamingTextView_Example-Swift.h"

static CGFloat const kCellHInset = 12.0;   // 气泡与 cell 左右间距
static CGFloat const kCellVInset = 10.0;   // 气泡与 cell 上下间距

#pragma mark - Model

/// 一条流式消息
@interface ZLStreamItem : NSObject
@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic, assign) CGFloat cachedHeight;   // 已知的 cell 高度
@property (nonatomic, assign) BOOL started;           // 是否已经开始过流式（避免复用时重启）
@property (nonatomic, assign) BOOL finished;          // 是否已经打印完成
@end

@implementation ZLStreamItem
@end

#pragma mark - Cell

@interface ZLStreamCell : UITableViewCell
@property (nonatomic, strong) ZLStreamingTextView *streamingView;
/// 当内部文字内容高度变化时回调（用于驱动 tableView 更新行高）
@property (nonatomic, copy) void (^onContentHeightChange)(CGFloat height);
@end

@implementation ZLStreamCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _streamingView = [[ZLStreamingTextView alloc] init];
        _streamingView.translatesAutoresizingMaskIntoConstraints = NO;
        _streamingView.textView.scrollEnabled = NO;      // 由 cell 承载高度，textView 不自己滚动
        _streamingView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        _streamingView.layer.cornerRadius = 10.0;
        _streamingView.layer.borderWidth = 1.0;
        _streamingView.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
        _streamingView.maxTextWidth = [UIScreen mainScreen].bounds.size.width - kCellHInset * 2.0;   // 默认宽度，后续在 cellForRow 中更新
        [self.contentView addSubview:_streamingView];

        [NSLayoutConstraint activateConstraints:@[
            [_streamingView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kCellVInset],
            [_streamingView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-kCellVInset],
            [_streamingView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kCellHInset],
        ]];

        __weak typeof(self) weakSelf = self;
        _streamingView.onContentSizeChange = ^(CGSize size) {
            // cell 高度 = 文字高度 + 上下内边距
            if (weakSelf.onContentHeightChange) {
                weakSelf.onContentHeightChange(ceil(size.height) + kCellVInset * 2.0);
            }
        };
    }
    return self;
}

@end

#pragma mark - Controller

@interface ZLTableStreamViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<ZLStreamItem *> *items;
/// 待逐条流式输出的“剧本”消息。
@property (nonatomic, strong) NSMutableArray<NSAttributedString *> *scriptedMessages;
@property (nonatomic, assign) NSInteger nextScriptIndex;
/// 是否自动跟随到底部（用户手动上滑离开底部后暂停跟随，回到底部附近后恢复）。
@property (nonatomic, assign) BOOL autoScrollToBottom;
@end

@implementation ZLTableStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TableView 流式";
    self.view.backgroundColor = [UIColor whiteColor];

    self.autoScrollToBottom = YES;

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self action:@selector(addItem)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[ZLStreamCell class] forCellReuseIdentifier:@"ZLStreamCell"];
    [self.view addSubview:self.tableView];

    // 逐条流式输出的“剧本”：一条打印完再追加下一条，内容足够长以便超出屏幕、演示跟随滚动。
    self.items = [NSMutableArray array];
    self.scriptedMessages = [self buildScriptedMessages];
    self.nextScriptIndex = 0;
    [self appendNextScriptedMessage];
}

- (NSMutableArray<NSAttributedString *> *)buildScriptedMessages {
    NSMutableArray *list = [NSMutableArray array];
    [list addObject:[self plainAttributed:@"你好，我是流式助手 👋，下面用 tableView 逐条演示打字效果。"]];
    [list addObject:[self sampleRichText]];
    [list addObject:[self plainAttributed:
        @"这是一条较长的消息：ZLStreamingTextView 使用 CADisplayLink 逐帧打印文字，"
        @"随着内容变多，所在 cell 的高度会自动增长，tableView 会实时刷新行高，"
        @"并在打印过程中自动向上滚动，始终把最新文字保持在可视区域底部。"]];
    [list addObject:[self plainAttributed:
        @"你可以在打印过程中手动向上滑动查看历史消息，此时会暂停自动跟随；"
        @"当你重新滑动回底部附近，自动跟随会恢复。"]];
    [list addObject:[self plainAttributed:
        @"再来一条更长的内容，确保总高度超过一屏：\n"
        @"1. 支持纯文本与富文本；\n2. 支持从指定偏移开始；\n3. 支持模拟网络分块追加；\n"
        @"4. 支持最大/最小宽高；\n5. 支持内容尺寸变化回调，从而驱动 cell 高度与列表滚动。\n"
        @"到这里演示基本结束啦，点击右上角“+”还能继续追加新的流式消息。✨"]];
    [list addObject:[self onRichText]];
    
    NSAttributedString *rich = [ZLDownBridge attributedStringFromMarkdown:[self readmeMarkdown]
                                                                 fontSize:16.0
                                                                textColor:[UIColor colorWithWhite:0.15 alpha:1.0]];
    [list addObject:rich];
    return list;
}
- (NSString *)readmeMarkdown {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"READMETest" ofType:@"md"];
    NSString *content = path ? [NSString stringWithContentsOfFile:path
                                                         encoding:NSUTF8StringEncoding
                                                            error:NULL] : nil;
    return content.length > 0 ? content : @"# READMETest.md 未找到";
}
- (NSAttributedString *)onRichText {
    NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] init];

    NSDictionary *title = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:22],
                             NSForegroundColorAttributeName: [UIColor blueColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"富文本标题\n" attributes:title]];

    NSDictionary *body = @{ NSFontAttributeName: [UIFont systemFontOfSize:17],
                            NSForegroundColorAttributeName: [UIColor darkGrayColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"这段文字是普通正文这段文字是普通正文这段文字是普通正文这段文字是普通正文这段文字是普通正文这段文字是普通正文，" attributes:body]];

    NSDictionary *highlight = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
                                 NSForegroundColorAttributeName: [UIColor whiteColor],
                                 NSBackgroundColorAttributeName: [UIColor magentaColor] };
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"这里是高亮这里是高亮这里是高亮这里是高亮这里是高亮" attributes:highlight]];
    
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
    [rich appendAttributedString:imageString];

    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"Rich text streams frame by frame too! ✨" attributes:body]];
    [rich appendAttributedString:imageString];

    return rich;
}


- (void)close {
    // 兼容 push 与 present 两种进入方式。
    if (self.navigationController && self.navigationController.viewControllers.firstObject != self) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Data

- (CGFloat)contentWidth {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (width <= 0) { width = CGRectGetWidth([UIScreen mainScreen].bounds); }
    return width - kCellHInset * 2.0;   // 减去气泡左右间距
}

- (ZLStreamItem *)itemWithText:(NSString *)text {
    return [self itemWithAttributedText:[self plainAttributed:text]];
}

- (NSAttributedString *)plainAttributed:(NSString *)text {
    return [[NSAttributedString alloc] initWithString:text
        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:17.0],
                      NSForegroundColorAttributeName: [UIColor darkTextColor] }];
}

- (ZLStreamItem *)itemWithAttributedText:(NSAttributedString *)attr {
    ZLStreamItem *item = [ZLStreamItem new];
    item.attributedText = attr;
    item.cachedHeight = 0;   // 未知，首帧回调后填充
    item.started = NO;
    item.finished = NO;
    return item;
}

- (NSAttributedString *)sampleRichText {
    NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] init];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"富文本消息\n"
        attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
                      NSForegroundColorAttributeName: [UIColor systemBlueColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"支持"
        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:17],
                      NSForegroundColorAttributeName: [UIColor darkGrayColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"高亮"
        attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
                      NSForegroundColorAttributeName: [UIColor whiteColor],
                      NSBackgroundColorAttributeName: [UIColor systemPinkColor] }]];
    [rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"与下划线，逐帧打印同样保留样式。"
        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:17],
                      NSForegroundColorAttributeName: [UIColor darkGrayColor],
                      NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) }]];
    return rich;
}

- (void)addItem {
    NSString *text = [NSString stringWithFormat:
        @"手动新增第 %lu 条：点击右上角“+”会追加一条新的流式消息，"
        @"每条都会边打字边把所在的 cell 撑高，并让列表跟随滚动到底部。✨每条都会边打字边把所在的 cell 撑高，并让列表跟随滚动到底部。✨每条都会边打字边把所在的 cell 撑高，并让列表跟随滚动到底部。✨每条都会边打字边把所在的 cell 撑高，并让列表跟随滚动到底部。✨",
        (unsigned long)(self.items.count + 1)];
    [self appendItem:[self itemWithText:text]];
}

/// 追加一条消息并插入到列表底部（自动开始流式在 cellForRow 中触发）。
- (void)appendItem:(ZLStreamItem *)item {
    [self.items addObject:item];
    self.autoScrollToBottom = YES;   // 有新消息时恢复跟随

    NSIndexPath *ip = [NSIndexPath indexPathForRow:self.items.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
    [self scrollToBottomAnimated:YES];
}

/// 逐条追加“剧本”消息：当前一条打印完成后再追加下一条。
- (void)appendNextScriptedMessage {
    if (self.nextScriptIndex >= (NSInteger)self.scriptedMessages.count) { return; }
    NSAttributedString *attr = self.scriptedMessages[self.nextScriptIndex];
    self.nextScriptIndex += 1;
    [self appendItem:[self itemWithAttributedText:attr]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZLStreamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZLStreamCell" forIndexPath:indexPath];
    ZLStreamItem *item = self.items[indexPath.row];

    cell.streamingView.maxTextWidth = [self contentWidth];

    __weak typeof(self) weakSelf = self;
    __weak ZLStreamItem *weakItem = item;
    cell.onContentHeightChange = ^(CGFloat height) {
        [UIView performWithoutAnimation:^{
            [weakSelf.tableView beginUpdates];
            [weakSelf.tableView endUpdates];
        }];
        // 文字变长导致内容变高时，跟随滚动到底部（除非用户手动上滑离开了底部）。
        if (weakSelf.autoScrollToBottom) {
            [weakSelf scrollToBottomAnimated:YES];
        }
    };
    cell.streamingView.onComplete = ^{
        [weakSelf handleFinishForItem:weakItem];
    };

    // 仅首次开始流式，避免复用 / 行高刷新时重启动画
    if (!item.started) {
        item.started = YES;
        cell.streamingView.charactersPerFrame = 1;
        cell.streamingView.frameInterval = 2;
        [cell.streamingView startStreamingAttributedText:item.attributedText];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
//    ZLStreamItem *item = self.items[indexPath.row];
//    return item.cachedHeight > 0 ? item.cachedHeight : UITableViewAutomaticDimension;
}

#pragma mark - Height driving


/// 某条消息打印完成 -> 追加下一条“剧本”消息（形成逐条流式的聊天效果）。
- (void)handleFinishForItem:(ZLStreamItem *)item {
    if (!item || item.finished) { return; }
    item.finished = YES;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weakSelf appendNextScriptedMessage];
    });
}

#pragma mark - Auto scroll

/// 兼容 iOS 11 以下的内容内边距。
- (UIEdgeInsets)effectiveContentInset {
    if (@available(iOS 11.0, *)) {
        return self.tableView.adjustedContentInset;
    }
    return self.tableView.contentInset;
}

/// 滚动到内容底部。
- (void)scrollToBottomAnimated:(BOOL)animated {
    // 先确保布局与 contentSize 是最新的，否则算出的底部偏移会滞后一帧。
    [self.tableView layoutIfNeeded];

    UIEdgeInsets inset = [self effectiveContentInset];
    CGFloat minOffset = -inset.top;
    CGFloat bottomOffset = self.tableView.contentSize.height
        - self.tableView.bounds.size.height
        + inset.bottom;
    // 内容不足一屏时钳制到顶部，避免出现负偏移的空白。
    bottomOffset = MAX(bottomOffset, minOffset);
    [self.tableView setContentOffset:CGPointMake(0, bottomOffset) animated:animated];
}

/// 判断当前是否已接近底部。
- (BOOL)isNearBottom {
    CGFloat distanceToBottom = self.tableView.contentSize.height
        - (self.tableView.contentOffset.y + self.tableView.bounds.size.height)
        + [self effectiveContentInset].bottom;
    return distanceToBottom <= 44.0;   // 距底部 44pt 内视为“在底部”
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 仅在用户手动拖动 / 惯性滑动时更新跟随状态，避免程序化滚动被误判。
    if (scrollView.isDragging || scrollView.isDecelerating) {
        self.autoScrollToBottom = [self isNearBottom];
    }
}

@end
