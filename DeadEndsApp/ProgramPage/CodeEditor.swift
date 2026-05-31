//
//  CodeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 May 2026.
//  Last changed on 31 May 2026.
//

import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {

        let textView = NSTextView()

        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.font = NSFont.monospacedSystemFont(
            ofSize: 16,
            weight: .regular
        )

        textView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {

        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
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
        }
    }
}
