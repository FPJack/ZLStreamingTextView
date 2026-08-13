//
//  ZLDownBridge.swift
//  ZLStreamingTextView_Example
//
//  Objective-C friendly bridge that uses the `Down` framework to render
//  CommonMark Markdown into an NSAttributedString.
//

import Foundation
import UIKit
import Down

@objcMembers
public class ZLDownBridge: NSObject {

    /// Parse Markdown into an attributed string with a base font size and text color.
    public static func attributedString(fromMarkdown markdown: String,
                                        fontSize: CGFloat,
                                        textColor: UIColor) -> NSAttributedString? {
        var fonts = StaticFontCollection()
        fonts.body = UIFont.systemFont(ofSize: fontSize)
        fonts.heading1 = UIFont.boldSystemFont(ofSize: fontSize + 9)
        fonts.heading2 = UIFont.boldSystemFont(ofSize: fontSize + 6)
        fonts.heading3 = UIFont.boldSystemFont(ofSize: fontSize + 3)
        fonts.code = UIFont(name: "Menlo", size: fontSize - 1) ?? UIFont.systemFont(ofSize: fontSize - 1)
        

        var colors = StaticColorCollection()
        colors.body = textColor
        colors.heading1 = textColor
        colors.heading2 = textColor
        colors.heading3 = textColor

        let configuration = DownStylerConfiguration(fonts: fonts, colors: colors)

        do {
           

            return try Down(markdownString: markdown)
                .toAttributedString(.default, styler: DownStyler(configuration: configuration))
        } catch {
            print("Error converting markdown: \(error)")
            return nil
        }
    }

    /// 递归遍历并打印 AST。
    /// - Parameters:
    ///   - node: 当前节点（Down 的 `Node` 包装类型，其 `children` 已经是子节点数组）
    ///   - indent: 当前缩进，用于体现层级
    static func printAST(_ node: Node, indent: String = "") {
        let cmarkNode = node.cmarkNode

        // 打印当前节点类型（中文）
        print("\(indent)\(chineseTypeName(for: node))")

        // 如果有文字内容，打印出来
        if let literal = cmarkNode.literal {
            print("\(indent)  literal: \(literal)")
        }

        // 递归遍历所有子节点，缩进加深一层
        for child in node.children {
            printAST(child, indent: indent + "  ")
        }
    }

    /// 将 Down 的 AST 节点映射为中文类型名称。
    static func chineseTypeName(for node: Node) -> String {
        switch node {
        case is Document:      return "文档"
        case let heading as Heading:
                               return "标题(H\(heading.headingLevel))"
        case is Paragraph:     return "段落"
        case is Text:          return "文本"
        case is Strong:        return "加粗"
        case is Emphasis:      return "斜体"
        case is Code:          return "行内代码"
        case is CodeBlock:     return "代码块"
        case is BlockQuote:    return "引用"
        case is List:          return "列表"
        case is Item:          return "列表项"
        case is Link:          return "链接"
        case is Image:         return "图片"
        case is ThematicBreak: return "分隔线"
        case is SoftBreak:     return "软换行"
        case is LineBreak:     return "硬换行"
        case is HtmlBlock:     return "HTML 块"
        case is HtmlInline:    return "行内 HTML"
        case is CustomBlock:   return "自定义块"
        case is CustomInline:  return "自定义行内"
        default:               return "未知(\(node.cmarkNode.type))"
        }
    }
}
