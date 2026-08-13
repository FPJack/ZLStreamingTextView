# ZLStreamingTextView

[![CI Status](https://img.shields.io/travis/fanpeng/ZLStreamingTextView.svg?style=flat)](https://travis-ci.org/fanpeng/ZLStreamingTextView)
[![Version](https://img.shields.io/cocoapods/v/ZLStreamingTextView.svg?style=flat)](https://cocoapods.org/pods/ZLStreamingTextView)
[![License](https://img.shields.io/cocoapods/l/ZLStreamingTextView.svg?style=flat)](https://cocoapods.org/pods/ZLStreamingTextView)
[![Platform](https://img.shields.io/cocoapods/p/ZLStreamingTextView.svg?style=flat)](https://cocoapods.org/pods/ZLStreamingTextView)

`ZLStreamingTextView` 是一个封装了 `UITextView` 的视图，可以**逐帧、逐字**地把文字“打印”出来（打字机 / 流式效果），非常适合用来实现类似 **AI 聊天流式输出**的界面。

它同时支持 **纯文本（`NSString`）** 和 **富文本（`NSAttributedString`）**，内置基于 `CADisplayLink` 的逐帧驱动、内容尺寸变化回调、最大 / 最小宽高约束、从指定偏移开始打印、模拟网络分块追加等能力。

---

## 目录

- [特性](#特性)
- [效果预览](#效果预览)
- [环境要求](#环境要求)
- [安装](#安装)
- [快速开始](#快速开始)
- [核心概念](#核心概念)
- [API 详解](#api-详解)
  - [初始化](#初始化)
  - [属性](#属性)
  - [开始 / 追加文字](#开始--追加文字)
  - [从指定偏移开始](#从指定偏移开始)
  - [流式控制](#流式控制)
  - [代理与回调](#代理与回调)
  - [内容尺寸](#内容尺寸)
- [使用场景与示例](#使用场景与示例)
  - [1. 逐帧打印纯文本](#1-逐帧打印纯文本)
  - [2. 逐帧打印富文本](#2-逐帧打印富文本)
  - [3. 模拟网络流式追加](#3-模拟网络流式追加)
  - [4. 根据内容动态调整气泡尺寸](#4-根据内容动态调整气泡尺寸)
  - [5. 提前计算宽高](#5-提前计算宽高)
  - [6. 从指定偏移开始（断点续传）](#6-从指定偏移开始断点续传)
  - [7. 关闭流式，直接整段显示](#7-关闭流式直接整段显示)
  - [8. 使用自定义 UITextView](#8-使用自定义-uitextview)
  - [9. 结合 Down 渲染 Markdown（AI 聊天）](#9-结合-down-渲染-markdownai-聊天)
- [运行示例工程](#运行示例工程)
- [实现原理](#实现原理)
- [常见问题](#常见问题)
- [作者](#作者)
- [许可证](#许可证)

---

## 特性

- ⌨️ **逐帧打字机效果**：基于 `CADisplayLink`，可控制“每帧显示几个字”和“每隔几帧显示一次”。
- 🅰️ **同时支持纯文本与富文本**：富文本的所有属性（字体、颜色、背景高亮、下划线、图片附件等）在逐字揭示过程中都被完整保留。
- 🌊 **模拟网络流式**：`appendText:` / `appendAttributedText:` 可以像网络分块一样不断追加，视图会自动继续播放。
- 📐 **内容尺寸回调**：文字宽 / 高变化时实时回调，方便让聊天气泡等容器动态适应内容。
- 📏 **最大 / 最小宽高约束**：`maxTextWidth` / `maxTextHeight` / `minTextWidth` / `minTextHeight`，超出最大高度可自动滚动。
- ⏩ **从指定偏移开始**：前缀直接整段显示，从某个位置开始继续打字机（适合断点续传 / 恢复进度）。
- 🎛 **完整控制**：暂停、继续、立即完成、重置。
- 🔧 **可注入自定义 `UITextView`**：复用你已经配置好的文本视图。
- 🔁 **可开关流式**：`streamingEnabled = NO` 时任何调用都会立即整段显示。
- 🧩 **代理 + Block 双通道回调**：进度、完成、尺寸变化都提供两种写法。

---

## 效果预览

示例工程演示了以下场景：

| 场景 | 说明 |
| --- | --- |
| Plain Text | 逐帧打印中英混排纯文本 |
| Rich Text | 逐帧打印富文本（标题、高亮、下划线、图片附件等） |
| Simulate Stream | `dispatch_after` 分块追加，模拟网络流式返回 |
| Start From Offset | 前缀直接显示，从指定长度开始打字机 |
| Pre-calc Size | 先预计算宽高，再按精确尺寸布局 |
| AI Chat (Down Markdown) | 读取 `READMETest.md`，用 Down 解析成富文本后流式展示 |

---

## 环境要求

- iOS 10.0+
- Xcode 12+
- 纯 Objective-C 组件（示例工程中的 Markdown 解析额外依赖 Swift 的 [Down](https://github.com/johnxnguyen/Down)，仅示例需要，组件本身不依赖）

---

## 安装

`ZLStreamingTextView` 通过 [CocoaPods](https://cocoapods.org) 分发。在 `Podfile` 中加入：

```ruby
pod 'ZLStreamingTextView'
```

然后执行：

```bash
pod install
```

导入头文件：

```objc
#import <ZLStreamingTextView/ZLStreamingTextView.h>
```

---

## 快速开始

```objc
ZLStreamingTextView *view = [[ZLStreamingTextView alloc] initWithFrame:CGRectMake(16, 100, 300, 200)];
view.charactersPerFrame = 1;   // 每帧显示 1 个字
view.frameInterval = 2;        // 每隔 2 个屏幕帧显示一次（60Hz 时约 30 字/秒）
[self.view addSubview:view];

[view startStreamingText:@"你好，这是逐帧打印的文字～"];
```

---

## 核心概念

- **缓冲区（buffer）**：组件内部维护一份完整的目标富文本 `bufferedText`，以及“当前已显示到第几个字符”的 `visibleLength`。
- **逐帧揭示**：每一帧只把 `bufferedText` 的前 `visibleLength` 个字符切片赋给底层 `UITextView`，因此富文本属性天然被正确切片保留。
- **追平即停止**：当已显示长度追平缓冲区时自动停止并触发完成回调；一旦有新内容被 `append`，会自动“复活”继续播放。

---

## API 详解

### 初始化

```objc
// 使用默认内置 UITextView
- (instancetype)initWithFrame:(CGRect)frame;

// 注入自定义 UITextView（会被强制设为不可编辑，其余配置保留）
- (instancetype)initWithTextView:(nullable UITextView *)textView;
- (instancetype)initWithFrame:(CGRect)frame textView:(UITextView *)textView;
```

### 属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `textView` | `UITextView *` (readonly) | — | 底层文本视图，可直接配置字体 / 颜色 / 内边距等 |
| `delegate` | `id<ZLStreamingTextViewDelegate>` | `nil` | 进度 / 完成 / 尺寸变化代理 |
| `charactersPerFrame` | `NSUInteger` | `1` | 每帧显示的字符数 |
| `frameInterval` | `NSUInteger` | `1` | 每隔 N 个屏幕帧显示一次（1 = 每帧，最快） |
| `defaultTextAttributes` | `NSDictionary *` | 16pt 黑色 | 纯文本未指定属性时的默认样式 |
| `streamingEnabled` | `BOOL` | `YES` | 是否启用打字机；`NO` 时立即整段显示 |
| `maxTextWidth` | `CGFloat` | `0` | 排版 / 换行最大宽度；`0` 表示用视图当前宽度 |
| `maxTextHeight` | `CGFloat` | `0` | 内容高度上限，超出后滚动；`0` 表示不限制 |
| `minTextWidth` | `CGFloat` | `0` | 上报内容尺寸的最小宽度；`0` 表示不限制 |
| `minTextHeight` | `CGFloat` | `0` | 上报内容尺寸的最小高度；`0` 表示不限制 |
| `scrollEnabled` | `BOOL` | `YES` | 底层文本视图是否可滚动 |
| `isStreaming` | `BOOL` (readonly) | — | 是否正在逐帧显示 |
| `visibleLength` | `NSUInteger` (readonly) | — | 当前已显示字符数 |
| `totalLength` | `NSUInteger` (readonly) | — | 缓冲区总字符数（已显示 + 待显示） |
| `textContentSize` | `CGSize` (readonly) | — | 当前已显示文字实际占用尺寸 |
| `onProgress` | `^(NSUInteger, NSUInteger)` | `nil` | 进度回调（代理替代方案） |
| `onComplete` | `^(void)` | `nil` | 完成回调（代理替代方案） |
| `onContentSizeChange` | `^(CGSize)` | `nil` | 尺寸变化回调（代理替代方案） |

> `maxTextWidth` 设为固定值后，内容尺寸测量将独立于视图 `bounds`，可避免布局反馈循环，得到稳定结果。

### 开始 / 追加文字

```objc
// 纯文本（使用 defaultTextAttributes）
- (void)startStreamingText:(NSString *)text;

// 纯文本（指定属性）
- (void)startStreamingText:(NSString *)text
                attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

// 富文本
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText;

// 增量追加（会自动继续 / 开始播放）
- (void)appendText:(NSString *)text;
- (void)appendAttributedText:(NSAttributedString *)attributedText;
```

### 从指定偏移开始

```objc
// 立即完整显示前 startLength 个字符，然后从该处开始打字机
- (void)startStreamingText:(NSString *)text fromLength:(NSUInteger)startLength;
- (void)startStreamingAttributedText:(NSAttributedString *)attributedText
                          fromLength:(NSUInteger)startLength;
```

### 流式控制

```objc
- (void)pause;             // 暂停（保留缓冲区）
- (void)resume;            // 继续
- (void)finishImmediately; // 立即显示全部并停止（跳过动画）
- (void)reset;             // 清空缓冲区与已显示内容并停止
```

### 代理与回调

```objc
@protocol ZLStreamingTextViewDelegate <NSObject>
@optional
// 每帧可见长度变化
- (void)streamingTextView:(ZLStreamingTextView *)textView
   didUpdateVisibleLength:(NSUInteger)visibleLength
              totalLength:(NSUInteger)totalLength;
// 全部显示完毕
- (void)streamingTextViewDidFinish:(ZLStreamingTextView *)textView;
// 内容尺寸变化
- (void)streamingTextView:(ZLStreamingTextView *)textView
     didChangeContentSize:(CGSize)contentSize;
@end
```

代理与 Block 可任选其一或同时使用。

### 内容尺寸

`textContentSize` 会根据 `maxTextWidth` 计算 `sizeThatFits:`，并把宽 / 高分别 clamp 到 `[minTextWidth, maxTextWidth]` / `[minTextHeight, maxTextHeight]`。该组件同时实现了 `intrinsicContentSize`，会随内容变化自动 `invalidateIntrinsicContentSize`。

---

## 使用场景与示例

### 1. 逐帧打印纯文本

```objc
[view startStreamingText:@"这是一个逐帧打印的示例，像打字机一样逐字显示。🚀"];
```

### 2. 逐帧打印富文本

```objc
NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] init];
[rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"富文本标题\n"
    attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:22],
                  NSForegroundColorAttributeName: [UIColor blueColor] }]];
[rich appendAttributedString:[[NSAttributedString alloc] initWithString:@"这里是高亮"
    attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
                  NSBackgroundColorAttributeName: [UIColor magentaColor] }]];

[view startStreamingAttributedText:rich];
```

> 富文本里也可以插入 `NSTextAttachment` 图片附件，同样会随打字机逐步出现。

### 3. 模拟网络流式追加

```objc
[view reset];
NSArray<NSString *> *chunks = @[ @"正在思考", @"……\n", @"根据你的问题，",
                                 @"我认为答案是：", @"逐帧流式输出体验更好。", @"\n\n完成。✅" ];

__block NSUInteger i = 0;
void (^__block feed)(void);
__weak __block void (^weakFeed)(void);
weakFeed = feed = ^{
    if (i >= chunks.count) { return; }
    [view appendText:chunks[i++]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), weakFeed);
};
feed();
```

### 4. 根据内容动态调整气泡尺寸

```objc
view.maxTextWidth = 280;
view.maxTextHeight = 320;   // 超出后内部滚动
view.minTextHeight = 34;

view.onContentSizeChange = ^(CGSize size) {
    self.bubbleHeightConstraint.constant = size.height;
    [self.view layoutIfNeeded];
};
[view startStreamingText:longText];
```

### 5. 提前计算宽高

在真正显示前，用一个临时实例测量目标内容的尺寸，然后据此布局，避免闪动：

```objc
CGSize size;
{
    ZLStreamingTextView *sizing = [[ZLStreamingTextView alloc] initWithTextView:nil];
    sizing.maxTextWidth = maxWidth;
    sizing.textView.attributedText = attributed;
    sizing.textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    sizing.textView.textContainer.lineFragmentPadding = 5.0;
    size = [sizing textContentSize];   // ← 预计算结果
}

// 再用 size 约束真正要显示的视图
[realView.widthAnchor constraintEqualToConstant:size.width].active = YES;
[realView.heightAnchor constraintEqualToConstant:size.height].active = YES;
realView.maxTextWidth = size.width;
[realView startStreamingAttributedText:attributed];
```

> 由于测量用的是同一套 `UITextView` 的 `sizeThatFits:` 逻辑，预计算尺寸与实际渲染尺寸一致（对混排富文本也精确）。

### 6. 从指定偏移开始（断点续传）

```objc
NSString *prefix = @"【已加载】前面这段直接展示，";
NSString *rest   = @"从这里开始逐帧流式输出剩余内容～ ✨";
NSString *text   = [prefix stringByAppendingString:rest];

// 前 prefix.length 个字符立即整段显示，其后打字机
[view startStreamingText:text fromLength:prefix.length];
```

### 7. 关闭流式，直接整段显示

```objc
view.streamingEnabled = NO;                 // 关闭打字机
[view startStreamingAttributedText:rich];   // 立即整段显示

// 或在打字过程中途关闭 —— 会立即补全剩余文字
view.streamingEnabled = NO;
```

### 8. 使用自定义 UITextView

```objc
UITextView *tv = [[UITextView alloc] init];
tv.font = [UIFont boldSystemFontOfSize:18];
tv.textColor = [UIColor darkGrayColor];
tv.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);

ZLStreamingTextView *view = [[ZLStreamingTextView alloc] initWithTextView:tv];
[view startStreamingText:@"使用自定义 TextView 的流式打印…"];
```

### 9. 结合 Down 渲染 Markdown（AI 聊天）

示例工程中的 `ZLChatViewController` 演示了完整的流式聊天：读取 `READMETest.md`，用 [Down](https://github.com/johnxnguyen/Down) 把 Markdown 解析成一整段 `NSAttributedString`（保留标题、代码块、列表、引用等），再交给本组件逐字揭示。

```objc
NSString *markdown = [self readmeMarkdown];
NSAttributedString *rich = [ZLDownBridge attributedStringFromMarkdown:markdown
                                                             fontSize:16.0
                                                            textColor:[UIColor darkGrayColor]];
self.streamingView.charactersPerFrame = 1;
self.streamingView.frameInterval = 2;
[self.streamingView startStreamingAttributedText:rich];
```

> Down 是 Swift 库，示例把它封装成一个对 Objective-C 友好的 `ZLDownBridge`（放在 App target 里）。组件本身是纯 Objective-C，不依赖 Down。

---

## 运行示例工程

克隆仓库后，在 `Example` 目录执行：

```bash
cd Example
pod install
open ZLStreamingTextView.xcworkspace
```

主界面提供多个按钮，分别对应上文的各个使用场景。

---

## 实现原理

1. 所有 `start.../append...` 方法最终都汇聚到内部的 `startDisplayLinkIfNeeded`。
2. 若 `streamingEnabled == NO`，直接 `finishImmediately` 一次性显示全部并触发完成回调。
3. 否则创建 `CADisplayLink`（`NSRunLoopCommonModes`）逐帧回调 `handleDisplayLink:`。
4. 每 `frameInterval` 帧，把 `visibleLength` 增加 `charactersPerFrame`，取 `bufferedText` 的前缀切片赋给 `UITextView`。
5. 每次渲染后调用 `notifyContentSizeChangeIfNeeded`，用 `sizeThatFits:` 计算尺寸并与上次比较，仅在**真正变化**时回调（去重）。
6. `visibleLength` 追平 `bufferedText.length` 时 `stopStreaming`，触发完成回调；若之后 `append` 了新内容会自动复活。

---

## 常见问题

**Q：为什么富文本预计算的高度和实际显示略有偏差？**
A：内容尺寸测量与实际渲染都基于同一个 `UITextView` 的 `sizeThatFits:`，因此结果一致。测量必须在**主线程**进行。

**Q：内容超出高度后怎么办？**
A：设置 `maxTextHeight` 后，超出部分由底层 `UITextView` 滚动显示；若不希望滚动可设 `scrollEnabled = NO` 并让容器随 `onContentSizeChange` 增高。

**Q：如何加快 / 减慢速度？**
A：`charactersPerFrame` 越大越快（每帧显示更多字），`frameInterval` 越大越慢（隔更多帧才显示一次）。

---

## 作者

fanpeng, peng.fan@ukelink.com

## 许可证

ZLStreamingTextView is available under the MIT license. See the LICENSE file for more info.
