//
//  ZLStreamingTextView.m
//  ZLStreamingTextView
//

#import "ZLStreamingTextView.h"

@interface ZLStreamingTextView ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL isStreaming;

/// Full buffered content (everything we eventually want to show).
@property (nonatomic, strong) NSMutableAttributedString *bufferedText;
/// How many characters of `bufferedText` are currently displayed.
@property (nonatomic, assign) NSUInteger visibleLength;

@property (nonatomic, strong, nullable) CADisplayLink *displayLink;
@property (nonatomic, assign) NSUInteger frameCounter;
/// Last reported text content size, used to detect width/height changes.
@property (nonatomic, assign) CGSize lastContentSize;
@end

@implementation ZLStreamingTextView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _charactersPerFrame = 1;
    _frameInterval = 1;
    _visibleLength = 0;
    _bufferedText = [[NSMutableAttributedString alloc] init];
    _lastContentSize = CGSizeZero;    _defaultTextAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:16.0],
        NSForegroundColorAttributeName: [UIColor blackColor]
    };

    _textView = [[UITextView alloc] initWithFrame:self.bounds];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.editable = NO;
    _textView.scrollEnabled = YES;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [self addSubview:_textView];
}

- (void)dealloc {
    [self stopDisplayLink];
}

#pragma mark - Derived state

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

#pragma mark - Plain text

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

#pragma mark - Rich text

- (void)startStreamingAttributedText:(NSAttributedString *)attributedText {
    [self resetBuffer];
    if (attributedText.length > 0) {
        [self.bufferedText appendAttributedString:attributedText];
    }
    [self startDisplayLinkIfNeeded];
}

#pragma mark - Start from an offset

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
    // Immediately reveal the prefix, then stream the remainder from there.
    self.visibleLength = MIN(startLength, self.bufferedText.length);
    [self applyVisibleText];
    [self startDisplayLinkIfNeeded];
}

#pragma mark - Incremental append

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

#pragma mark - Control

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

#pragma mark - Display link driving

- (void)startDisplayLinkIfNeeded {
    // Nothing left to reveal.
    if (self.visibleLength >= self.bufferedText.length) {
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
        // Caught up with the buffer. Stop until more text arrives.
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

#pragma mark - Rendering

- (void)applyVisibleText {
    NSUInteger length = MIN(self.visibleLength, self.bufferedText.length);
    NSAttributedString *slice = [self.bufferedText attributedSubstringFromRange:NSMakeRange(0, length)];
    self.textView.attributedText = slice;
    [self notifyContentSizeChangeIfNeeded];
}

#pragma mark - Content size tracking

- (void)layoutSubviews {
    [super layoutSubviews];
    // Width may change when the view is resized, which affects wrapped text height.
    [self notifyContentSizeChangeIfNeeded];
}

/// The size the visible text actually occupies (fits the current / max width, clamped to max height).
- (CGSize)textContentSize {
    CGFloat width = self.maxTextWidth > 0 ? self.maxTextWidth : CGRectGetWidth(self.textView.bounds);
    if (width <= 0) {
        width = CGRectGetWidth(self.bounds);
    }
    if (width <= 0) {
        return CGSizeZero;
    }
    CGSize fitting = [self.textView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
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
    [self layoutIfNeeded];
}
- (CGSize)intrinsicContentSize {
    return self.lastContentSize;
}

#pragma mark - Size pre-calculation

/// A shared, reused text view for off-screen measurement (must be used on the main thread).
+ (UITextView *)sharedSizingTextView {
    static UITextView *sizingTextView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    });
    return sizingTextView;
}

- (CGSize)sizeThatFitsAttributedText:(NSAttributedString *)attributedText {
    CGFloat width = self.maxTextWidth > 0 ? self.maxTextWidth : CGRectGetWidth(self.bounds);
    CGSize size = [ZLStreamingTextView sizeForAttributedText:attributedText
                                                    maxWidth:width
                                          textContainerInset:self.textView.textContainerInset
                                         lineFragmentPadding:self.textView.textContainer.lineFragmentPadding];
    if (self.maxTextWidth > 0) { size.width = MIN(size.width, self.maxTextWidth); }
    if (self.maxTextHeight > 0) { size.height = MIN(size.height, self.maxTextHeight); }
    if (self.minTextWidth > 0) { size.width = MAX(size.width, self.minTextWidth); }
    if (self.minTextHeight > 0) { size.height = MAX(size.height, self.minTextHeight); }
    return size;
}

- (CGSize)sizeThatFitsText:(NSString *)text {
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:(text ?: @"")
                                                                     attributes:self.defaultTextAttributes];
    return [self sizeThatFitsAttributedText:attributed];
}

+ (CGSize)sizeForText:(NSString *)text
           attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
             maxWidth:(CGFloat)maxWidth
   textContainerInset:(UIEdgeInsets)textContainerInset
  lineFragmentPadding:(CGFloat)lineFragmentPadding {
    if (text.length == 0) { return CGSizeZero; }
    NSDictionary *attrs = attributes ?: @{ NSFontAttributeName: [UIFont systemFontOfSize:16.0] };
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:text attributes:attrs];
    return [self sizeForAttributedText:attributed
                              maxWidth:maxWidth
                    textContainerInset:textContainerInset
                   lineFragmentPadding:lineFragmentPadding];
}

+ (CGSize)sizeForAttributedText:(NSAttributedString *)attributedText
                       maxWidth:(CGFloat)maxWidth
             textContainerInset:(UIEdgeInsets)textContainerInset
            lineFragmentPadding:(CGFloat)lineFragmentPadding {
    if (attributedText.length == 0 || maxWidth <= 0) { return CGSizeZero; }

    // Measure with a shared, reused UITextView so the result matches exactly what will be
    // rendered (a raw NSLayoutManager / usedRectForTextContainer computes line heights slightly
    //  differently for mixed fonts, which causes a few points of height drift).
    UITextView *sizingTextView = [self sharedSizingTextView];
    sizingTextView.textContainerInset = textContainerInset;
    sizingTextView.textContainer.lineFragmentPadding = lineFragmentPadding;
    sizingTextView.attributedText = attributedText;

    CGSize fitting = [sizingTextView sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];

    // Release the reference so the (potentially large) attributed string isn't retained.
    sizingTextView.attributedText = nil;
    return CGSizeMake(ceil(fitting.width), ceil(fitting.height));
}

@end
