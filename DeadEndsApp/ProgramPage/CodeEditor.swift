//
//  CodeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 May 2026.
//  Last changed on 1 June 2026.
//

import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        textView.delegate = context.coordinator

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        scrollView.documentView = textView

        // Ruler view connection.
        let ruler = LineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        // Keep the ruler in sync while the editor scrolls.
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
            scrollView.verticalRulerView?.needsDisplay = true
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {

        var parent: CodeEditor

        init(_ parent: CodeEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {

            guard let textView =
                notification.object as? NSTextView else { return }

            parent.text = textView.string
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
            //textView.enclosingScrollView?.verticalRulerView?.invalidateRuleThickness()
        }

        @objc func boundsDidChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView,
                  let scrollView = clipView.superview as? NSScrollView
            else { return }

            scrollView.verticalRulerView?.needsDisplay = true
        }
    }
}

/// This object is responsible for drawing line numbers.
final class LineNumberRulerView: NSRulerView {

    weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 60
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard
            let textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else { return }

        // Following two lines removed to see if the text becomes visible.
        //NSColor.textBackgroundColor.setFill()
        //rect.fill()

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(
            forBoundingRect: visibleRect,
            in: textContainer
        )

        let text = textView.string as NSString
        var lineNumber = text.substring(
            to: layoutManager.characterIndexForGlyph(at: glyphRange.location)
        )
        .components(separatedBy: "\n")
        .count

        var glyphIndex = glyphRange.location

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        while glyphIndex < NSMaxRange(glyphRange) {
            var effectiveRange = NSRange()
            let lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex,
                effectiveRange: &effectiveRange
            )

            let y = lineRect.minY
                + textView.textContainerOrigin.y
                - visibleRect.minY

            let numberString = "\(lineNumber)" as NSString

            numberString.draw(
                in: NSRect(
                    x: 0,
                    y: y,
                    width: ruleThickness - 6,
                    height: lineRect.height
                ),
                withAttributes: attributes
            )

            glyphIndex = NSMaxRange(effectiveRange)
            lineNumber += 1
        }
    }
}

