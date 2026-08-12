//
//  ZLStreamingTextView.m
//  ZLStreamingTextView
//

#import "ZLStreamingTextView.h"

@interface ZLStreamingTextView ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL isStreaming;

/// 完整的缓冲内容（最终要显示的全部文字）。
@property (nonatomic, strong) NSMutableAttributedString *bufferedText;
/// `bufferedText` 中当前已显示的字符数。
@property (nonatomic, assign) NSUInteger visibleLength;

@property (nonatomic, strong, nullable) CADisplayLink *displayLink;
@property (nonatomic, assign) NSUInteger frameCounter;
/// 上一次上报的内容尺寸，用于检测宽 / 高变化。
@property (nonatomic, assign) CGSize lastContentSize;
@end

@implementation ZLStreamingTextView

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitWithTextView:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInitWithTextView:nil];
    }
    return self;
}

- (instancetype)initWithTextView:(UITextView *)textView {
    return [self initWithFrame:CGRectZero textView:textView];
}

- (instancetype)initWithFrame:(CGRect)frame
                     textView:(UITextView *)textView {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitWithTextView:textView];
    }
    return self;
}

- (void)commonInitWithTextView:(nullable UITextView *)textView {
    _charactersPerFrame = 1;
    _frameInterval = 1;
    _visibleLength = 0;
    _streamingEnabled = YES;
    _bufferedText = [[NSMutableAttributedString alloc] init];
    _lastContentSize = CGSizeZero;
    _defaultTextAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:16.0],
        NSForegroundColorAttributeName: [UIColor blackColor]
    };

    if (textView) {
        // 采用外部传入的自定义文本视图，尽量保留其原有配置。
        _textView = textView;
        _textView.frame = self.bounds;
        _textView.editable = NO; // 流式展示视图不可编辑
    } else {
        _textView = [[UITextView alloc] initWithFrame:self.bounds];
        _textView.editable = NO;
        _textView.scrollEnabled = YES;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    }
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_textView];
}

- (void)dealloc {
    [self stopDisplayLink];
}

#pragma mark - 派生状态

- (NSUInteger)totalLength {
    return self.bufferedText.length;
}

- (void)setMaxTextWidth:(CGFloat)maxTextWidth {
    if (_maxTextWidth == maxTextWidth) { return; }
    _maxTextWidth = maxTextWidth;
    [self notifyContentSizeChangeIfNeeded];
}

- (void)setMaxTextHeight:(CGFloat)maxTextHeight {
    if (_maxTextHeight == maxTextHeight) { return; }
    _maxTextHeight = maxTextHeight;
    [self notifyContentSizeChangeIfNeeded];
}

- (void)setMinTextWidth:(CGFloat)minTextWidth {
    if (_minTextWidth == minTextWidth) { return; }
    _minTextWidth = minTextWidth;
    [self notifyContentSizeChangeIfNeeded];
}

- (void)setMinTextHeight:(CGFloat)minTextHeight {
    if (_minTextHeight == minTextHeight) { return; }
    _minTextHeight = minTextHeight;
    [self notifyContentSizeChangeIfNeeded];
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    self.textView.scrollEnabled = scrollEnabled;
}

- (BOOL)isScrollEnabled {
    return self.textView.scrollEnabled;
}

- (void)setStreamingEnabled:(BOOL)streamingEnabled {
    if (_streamingEnabled == streamingEnabled) { return; }
    _streamingEnabled = streamingEnabled;
    // 若在文字仍未显示完时关闭流式，则立即显示剩余内容。
    if (!streamingEnabled && self.visibleLength < self.bufferedText.length) {
        [self finishImmediately];
    }
}

#pragma mark - 纯文本

- (void)startStreamingText:(NSString *)text {
    [self startStreamingText:text attributes:self.defaultTextAttributes];
}

- (void)startStreamingText:(NSString *)text
                attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSDictionary *attrs = attributes ?: self.defaultTextAttributes;
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:(text ?: @"")
                                                                     attributes:attrs];
    [self startStreamingAttributedText:attributed];
}

#pragma mark - 富文本

- (void)startStreamingAttributedText:(NSAttributedString *)attributedText {
    [self resetBuffer];
    if (attributedText.length > 0) {
        [self.bufferedText appendAttributedString:attributedText];
    }
    [self startDisplayLinkIfNeeded];
}

#pragma mark - 从指定偏移开始

- (void)startStreamingText:(NSString *)text
                fromLength:(NSUInteger)startLength {
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:(text ?: @"")
                                                                     attributes:self.defaultTextAttributes];
    [self startStreamingAttributedText:attributed fromLength:startLength];
}

- (void)startStreamingAttributedText:(NSAttributedString *)attributedText
                          fromLength:(NSUInteger)startLength {
    [self resetBuffer];
    if (attributedText.length > 0) {
        [self.bufferedText appendAttributedString:attributedText];
    }
    // 立即显示前缀，然后从该处开始流式显示剩余内容。
    self.visibleLength = MIN(startLength, self.bufferedText.length);
    [self applyVisibleText];
    [self startDisplayLinkIfNeeded];
}

#pragma mark - 增量追加

- (void)appendText:(NSString *)text {
    if (text.length == 0) { return; }
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:text
                                                                     attributes:self.defaultTextAttributes];
    [self appendAttributedText:attributed];
}

- (void)appendAttributedText:(NSAttributedString *)attributedText {
    if (attributedText.length == 0) { return; }
    [self.bufferedText appendAttributedString:attributedText];
    [self startDisplayLinkIfNeeded];
}

#pragma mark - 控制

- (void)pause {
    self.isStreaming = NO;
    [self stopDisplayLink];
}

- (void)resume {
    [self startDisplayLinkIfNeeded];
}

- (void)finishImmediately {
    self.visibleLength = self.bufferedText.length;
    [self applyVisibleText];
    [self stopStreaming];
}

- (void)reset {
    [self stopDisplayLink];
    [self resetBuffer];
    self.visibleLength = 0;
    self.textView.attributedText = [[NSAttributedString alloc] init];
    self.isStreaming = NO;
    [self notifyContentSizeChangeIfNeeded];
}

- (void)resetBuffer {
    [self stopDisplayLink];
    self.bufferedText = [[NSMutableAttributedString alloc] init];
    self.visibleLength = 0;
    self.textView.attributedText = [[NSAttributedString alloc] init];
    [self notifyContentSizeChangeIfNeeded];
}

#pragma mark - Display Link 驱动

- (void)startDisplayLinkIfNeeded {
    // 没有可显示的剩余内容。
    if (self.visibleLength >= self.bufferedText.length) {
        return;
    }
    // 流式已关闭：一次性显示全部并立即完成。
    if (!self.streamingEnabled) {
        self.isStreaming = YES; // 保证完成回调依然会触发
        [self finishImmediately];
        return;
    }
    self.isStreaming = YES;
    if (self.displayLink) {
        return;
    }
    self.frameCounter = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopDisplayLink {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)handleDisplayLink:(CADisplayLink *)link {
    NSUInteger interval = MAX(self.frameInterval, 1);
    self.frameCounter += 1;
    if (self.frameCounter < interval) {
        return;
    }
    self.frameCounter = 0;

    NSUInteger step = MAX(self.charactersPerFrame, 1);
    NSUInteger newVisible = MIN(self.visibleLength + step, self.bufferedText.length);
    if (newVisible == self.visibleLength) {
        // 已追平缓冲区。停止，等待更多文字到达。
        [self stopStreaming];
        return;
    }
    self.visibleLength = newVisible;
    [self applyVisibleText];

    if ([self.delegate respondsToSelector:@selector(streamingTextView:didUpdateVisibleLength:totalLength:)]) {
        [self.delegate streamingTextView:self
                  didUpdateVisibleLength:self.visibleLength
                             totalLength:self.bufferedText.length];
    }
    if (self.onProgress) {
        self.onProgress(self.visibleLength, self.bufferedText.length);
    }

    if (self.visibleLength >= self.bufferedText.length) {
        [self stopStreaming];
    }
}

- (void)stopStreaming {
    [self stopDisplayLink];
    if (self.isStreaming) {
        self.isStreaming = NO;
        if ([self.delegate respondsToSelector:@selector(streamingTextViewDidFinish:)]) {
            [self.delegate streamingTextViewDidFinish:self];
        }
        if (self.onComplete) {
            self.onComplete();
        }
    }
}

#pragma mark - 渲染

- (void)applyVisibleText {
    NSUInteger length = MIN(self.visibleLength, self.bufferedText.length);
    NSAttributedString *slice = [self.bufferedText attributedSubstringFromRange:NSMakeRange(0, length)];
    self.textView.attributedText = slice;
    [self notifyContentSizeChangeIfNeeded];
}

#pragma mark - 内容尺寸跟踪

- (void)layoutSubviews {
    [super layoutSubviews];
    // 视图缩放时宽度可能变化，进而影响换行后的文字高度。
    [self notifyContentSizeChangeIfNeeded];
}

/// 已显示文字实际占用的尺寸（适配当前 / 最大宽度，并限制到最大高度）。
- (CGSize)textContentSize {
    CGFloat width = self.maxTextWidth > 0 ? self.maxTextWidth : CGRectGetWidth(self.textView.bounds);
    if (width <= 0) {
        width = CGRectGetWidth(self.bounds);
    }
    if (width <= 0) {
        width = CGFLOAT_MAX;
    }
    
    CGFloat height = self.maxTextHeight > 0 ? self.maxTextHeight : CGRectGetHeight(self.textView.bounds);
    
    if (height <= 0) {
        height = CGRectGetHeight(self.bounds);;
    }
    if (height <= 0) {
        height = CGFLOAT_MAX;
    }
    
    
    
    CGSize fitting = [self.textView sizeThatFits:CGSizeMake(width, height)];
    CGFloat w = ceil(fitting.width);
    CGFloat h = ceil(fitting.height);
    if (self.maxTextWidth > 0) {
        w = MIN(w, self.maxTextWidth);
    }
    if (self.maxTextHeight > 0) {
        h = MIN(h, self.maxTextHeight);
    }
    if (self.minTextWidth > 0) {
        w = MAX(w, self.minTextWidth);
    }
    if (self.minTextHeight > 0) {
        h = MAX(h, self.minTextHeight);
    }
    return CGSizeMake(w, h);
}

- (void)notifyContentSizeChangeIfNeeded {
    CGSize size = [self textContentSize];
    if (CGSizeEqualToSize(size, self.lastContentSize)) {
        return;
    }
    self.lastContentSize = size;
    [self invalidateContentSize];
    if ([self.delegate respondsToSelector:@selector(streamingTextView:didChangeContentSize:)]) {
        [self.delegate streamingTextView:self didChangeContentSize:size];
    }
    if (self.onContentSizeChange) {
        self.onContentSizeChange(size);
    }
}
- (void)invalidateContentSize {
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}
- (CGSize)intrinsicContentSize {
    return self.lastContentSize;
}
@end
