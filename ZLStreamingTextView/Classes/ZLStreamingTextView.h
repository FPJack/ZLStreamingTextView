//
//  ZLStreamingTextView.h
//  ZLStreamingTextView
//
//  一个封装了 UITextView 的视图，可逐帧打印文字（打字机 / 流式效果）。
//  同时支持纯文本（NSString）和富文本（NSAttributedString）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZLStreamingTextView;

@protocol ZLStreamingTextViewDelegate <NSObject>
@optional
/// 每当可见文字长度变化（即每帧）时回调。
- (void)streamingTextView:(ZLStreamingTextView *)textView
       didUpdateVisibleLength:(NSUInteger)visibleLength
                  totalLength:(NSUInteger)totalLength;
/// 当所有缓冲文字都显示完毕、流式停止时回调一次。
- (void)streamingTextViewDidFinish:(ZLStreamingTextView *)textView;
/// 当渲染文字的内容尺寸（宽和/或高）发生变化时回调。
- (void)streamingTextView:(ZLStreamingTextView *)textView
     didChangeContentSize:(CGSize)contentSize;
@end

@interface ZLStreamingTextView : UIView

/// 使用外部传入的自定义 UITextView 进行初始化（便于复用已配置好字体 / 颜色 / 内边距等的实例）。
/// 传入的 textView 会被强制设为不可编辑（`editable = NO`），其余配置保持不变。
- (instancetype)initWithTextView:(nullable UITextView  * )textView;

/// 使用指定 frame 与外部传入的自定义 UITextView 进行初始化。
- (instancetype)initWithFrame:(CGRect)frame
                     textView:(UITextView *)textView NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

/// 底层的文本视图。你可以直接配置它（字体、颜色、内边距……）。
@property (nonatomic, strong, readonly) UITextView *textView;

/// 进度 / 完成回调的代理。
@property (nonatomic, weak, nullable) id<ZLStreamingTextViewDelegate> delegate;

/// 每一帧（display link）显示的字符数。默认为 1。
@property (nonatomic, assign) NSUInteger charactersPerFrame;

/// 每隔 N 个屏幕帧显示一帧文字。1 = 每帧都显示（最快）。默认为 1。
@property (nonatomic, assign) NSUInteger frameInterval;

/// 纯文本流式时若未指定属性所使用的默认文字属性。
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *defaultTextAttributes;

/// 是否启用逐帧打字机效果。设为 `NO` 时，任何 `start...` / `append...` 调用都会
/// 立即完整显示其内容（无动画）。默认 `YES`。
@property (nonatomic, assign, getter=isStreamingEnabled) BOOL streamingEnabled;

/// 排版 / 换行所使用的最大宽度。`0` 表示使用视图当前宽度。默认 `0`。
/// 设为固定值可以得到与视图 bounds 无关的稳定内容尺寸测量结果。
@property (nonatomic, assign) CGFloat maxTextWidth;


/// 最大高度。上报的内容尺寸高度会被限制到此值（超出部分由文本视图滚动显示）。
/// `0` 表示不限制。默认 `0`。
@property (nonatomic, assign) CGFloat maxTextHeight;

/// 最小宽度。上报的内容尺寸宽度不会小于此值。`0` 表示不限制。默认 `0`。
@property (nonatomic, assign) CGFloat minTextWidth;

/// 最小高度。上报的内容尺寸高度不会小于此值。`0` 表示不限制。默认 `0`。
@property (nonatomic, assign) CGFloat minTextHeight;

/// 打印过程中（及之后）底层文本视图是否可以滚动。默认 `YES`。
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;

/// 正在逐帧显示文字时为 YES。
@property (nonatomic, assign, readonly) BOOL isStreaming;

/// 当前已显示的字符数。
@property (nonatomic, assign, readonly) NSUInteger visibleLength;

/// 缓冲区中的总字符数（已显示 + 待显示）。
@property (nonatomic, assign, readonly) NSUInteger totalLength;

/// 当前已显示文字在当前宽度下所占用的尺寸。
@property (nonatomic, assign, readonly) CGSize textContentSize;

/// 进度回调（代理的替代方案）。
@property (nonatomic, copy, nullable) void (^onProgress)(NSUInteger visibleLength, NSUInteger totalLength);

/// 完成回调（代理的替代方案）。
@property (nonatomic, copy, nullable) void (^onComplete)(void);

/// 流式过程中，当渲染文字的内容尺寸（宽 / 高）变化时回调。
@property (nonatomic, copy, nullable) void (^onContentSizeChange)(CGSize contentSize);

/// 预计算当前已显示文字在当前宽度下所占用的尺寸。
- (CGSize)textContentSize;
#pragma mark - 纯文本

/// 重置缓冲区，并使用 `defaultTextAttributes` 开始流式显示给定的纯文本。
- (void)startStreamingText:(NSString *)text;

/// 重置缓冲区，并使用指定属性开始流式显示给定的纯文本。
- (void)startStreamingText:(NSString *)text
                attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

#pragma mark - 富文本

/// 重置缓冲区，并开始流式显示给定的富文本。
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText;

#pragma mark - 从指定偏移开始

/// 将缓冲区重置为给定纯文本，立即显示前 `startLength` 个字符，
/// 然后从该处开始流式显示剩余内容。
- (void)startStreamingText:(NSString *)text
               fromLength:(NSUInteger)startLength;

/// 将缓冲区重置为给定富文本，立即显示前 `startLength` 个字符，
/// 然后从该处开始流式显示剩余内容。
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText
                          fromLength:(NSUInteger)startLength;

#pragma mark - 增量追加（例如网络流式分块）

/// 向缓冲区追加纯文本；流式会自动继续 / 开始。
- (void)appendText:(NSString *)text;

/// 向缓冲区追加富文本；流式会自动继续 / 开始。
- (void)appendAttributedText:(NSAttributedString *)attributedText;

#pragma mark - 控制

/// 暂停显示（保留缓冲区）。
- (void)pause;

/// 暂停后继续显示。
- (void)resume;

/// 立即显示全部缓冲文字并停止。
- (void)finishImmediately;

/// 清空所有内容（缓冲区 + 已显示文字）并停止。
- (void)reset;


@end

NS_ASSUME_NONNULL_END
