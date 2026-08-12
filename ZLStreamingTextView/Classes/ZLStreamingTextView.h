//
//  ZLStreamingTextView.h
//  ZLStreamingTextView
//
//  A UITextView wrapper that prints text frame by frame (typewriter / streaming effect).
//  Supports both plain text (NSString) and rich text (NSAttributedString).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZLStreamingTextView;

@protocol ZLStreamingTextViewDelegate <NSObject>
@optional
/// Called on every frame the visible length changes.
- (void)streamingTextView:(ZLStreamingTextView *)textView
       didUpdateVisibleLength:(NSUInteger)visibleLength
                  totalLength:(NSUInteger)totalLength;
/// Called once all buffered text has been revealed and streaming stops.
- (void)streamingTextViewDidFinish:(ZLStreamingTextView *)textView;
/// Called whenever the rendered text content size (width and/or height) changes.
- (void)streamingTextView:(ZLStreamingTextView *)textView
     didChangeContentSize:(CGSize)contentSize;
@end

@interface ZLStreamingTextView : UIView

/// The underlying text view. You may configure it directly (font, color, insets ...).
@property (nonatomic, strong, readonly) UITextView *textView;

/// Delegate for progress / completion callbacks.
@property (nonatomic, weak, nullable) id<ZLStreamingTextViewDelegate> delegate;

/// Number of characters revealed on every display-link frame. Default is 1.
@property (nonatomic, assign) NSUInteger charactersPerFrame;

/// Reveal a frame every N screen frames. 1 = every frame (fastest). Default is 1.
@property (nonatomic, assign) NSUInteger frameInterval;

/// Default text attributes used for plain-text streaming when none are supplied.
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *defaultTextAttributes;

/// Maximum width used to lay out / wrap the text. `0` means use the view's current width. Default `0`.
/// Setting a fixed value gives a stable content-size measurement independent of the view's bounds.
@property (nonatomic, assign) CGFloat maxTextWidth;


/// Maximum height. The reported content-size height is clamped to this value (the text view scrolls
/// beyond it). `0` means unlimited. Default `0`.
@property (nonatomic, assign) CGFloat maxTextHeight;

/// Minimum width. The reported content-size width is never smaller than this value. `0` means no
/// minimum. Default `0`.
@property (nonatomic, assign) CGFloat minTextWidth;

/// Minimum height. The reported content-size height is never smaller than this value. `0` means no
/// minimum. Default `0`.
@property (nonatomic, assign) CGFloat minTextHeight;

/// Whether the underlying text view can scroll while (and after) printing. Default `YES`.
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;

/// YES while text is actively being revealed.
@property (nonatomic, assign, readonly) BOOL isStreaming;

/// The number of characters currently visible.
@property (nonatomic, assign, readonly) NSUInteger visibleLength;

/// The total number of characters buffered (visible + pending).
@property (nonatomic, assign, readonly) NSUInteger totalLength;

/// The size the currently visible text occupies for the current width.
@property (nonatomic, assign, readonly) CGSize textContentSize;

/// Progress callback (alternative to delegate).
@property (nonatomic, copy, nullable) void (^onProgress)(NSUInteger visibleLength, NSUInteger totalLength);

/// Completion callback (alternative to delegate).
@property (nonatomic, copy, nullable) void (^onComplete)(void);

/// Called whenever the rendered text content size (width / height) changes while streaming.
@property (nonatomic, copy, nullable) void (^onContentSizeChange)(CGSize contentSize);

#pragma mark - Plain text

/// Reset the buffer and start streaming the given plain text using `defaultTextAttributes`.
- (void)startStreamingText:(NSString *)text;

/// Reset the buffer and start streaming the given plain text with explicit attributes.
- (void)startStreamingText:(NSString *)text
                attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

#pragma mark - Rich text

/// Reset the buffer and start streaming the given attributed (rich) text.
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText;

#pragma mark - Start from an offset

/// Reset the buffer to the given plain text, immediately show the first `startLength` characters,
/// then stream-reveal the remainder from there.
- (void)startStreamingText:(NSString *)text
               fromLength:(NSUInteger)startLength;

/// Reset the buffer to the given attributed text, immediately show the first `startLength`
/// characters, then stream-reveal the remainder from there.
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText
                          fromLength:(NSUInteger)startLength;

#pragma mark - Incremental append (e.g. network stream chunks)

/// Append plain text to the buffer; streaming continues/starts automatically.
- (void)appendText:(NSString *)text;

/// Append rich text to the buffer; streaming continues/starts automatically.
- (void)appendAttributedText:(NSAttributedString *)attributedText;

#pragma mark - Control

/// Pause revealing (buffer is kept).
- (void)pause;

/// Resume revealing after a pause.
- (void)resume;

/// Immediately reveal all buffered text and stop.
- (void)finishImmediately;

/// Clear everything (buffer + visible text) and stop.
- (void)reset;

#pragma mark - Size pre-calculation

/// Pre-calculate the size the given text would occupy in THIS view, honoring the receiver's
/// `textView` insets / line padding and `maxTextWidth` (falls back to the current bounds width).
- (CGSize)sizeThatFitsText:(nullable NSString *)text;

/// Pre-calculate the size the given attributed (rich) text would occupy in THIS view.
- (CGSize)sizeThatFitsAttributedText:(nullable NSAttributedString *)attributedText;

/// Pre-calculate the size the given attributed text occupies when laid out within `maxWidth`.
/// `textContainerInset` / `lineFragmentPadding` should mirror the target UITextView so the
/// result matches what will be displayed (UITextView defaults: inset {8,8,8,8}, padding 5).
+ (CGSize)sizeForAttributedText:(nullable NSAttributedString *)attributedText
                       maxWidth:(CGFloat)maxWidth
             textContainerInset:(UIEdgeInsets)textContainerInset
            lineFragmentPadding:(CGFloat)lineFragmentPadding;

/// Pre-calculate the size for plain text with the given attributes within `maxWidth`.
+ (CGSize)sizeForText:(nullable NSString *)text
           attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes
             maxWidth:(CGFloat)maxWidth
   textContainerInset:(UIEdgeInsets)textContainerInset
  lineFragmentPadding:(CGFloat)lineFragmentPadding;

@end

NS_ASSUME_NONNULL_END
