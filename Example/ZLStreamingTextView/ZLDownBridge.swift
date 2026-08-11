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
            return nil
        }
    }
}
