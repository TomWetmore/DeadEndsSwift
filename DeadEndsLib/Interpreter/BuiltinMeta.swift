//
//  BuiltinMeta.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 April 2026.
//  Last changed on 3 May 2026.
//
//  The built-ins in this file are used to inspect running
//  programs. They are used to help users debug their programs
//  (and the developer to debug the interpreter!)

import Foundation

extension Program {

    /// Builtin function that shows the run time frame.
    func builtinShowFrame(_ args: [ParsedExpr]) throws -> ProgramValue {
        showFrame()
        return .null
    }

    /// Builtin function that shows the run times stack and global symbol table.
    func builtinShowStack(_ args: [ParsedExpr]) throws -> ProgramValue {
        showRuntimeStack()
        return .null
    }

    /// Builtin function that shows the type and value of an expression.
    func builtinValueOf(_ args: [ParsedExpr]) throws -> ProgramValue {
        let value = try evaluate(args[0])
        return .string("\(value.typeName): \(value.displayValue)")
    }
}

extension Program {

    /// Output the contents of the run time stack.
    func showRuntimeStack() {
        guard !callStack.isEmpty else {
            output.writeln("Run Time Stack is empty")
            return
        }

        var buffer = ""
        buffer += "Run Time Stack\n"
        for frame in callStack.reversed() {
            buffer += formatFrame(frame) + "\n"
        }
        buffer += "Global symbols:\n"
        buffer += formatSymbolTable(globalSymbolTable, indent: "    ")
        output.write(buffer)
    }

    /// Format the contents of a frame into a string.
    private func formatFrame(_ frame: RuntimeFrame) -> String {

        var lines: [String] = []

        lines.append("Frame: \(frame.name): defined: \(frame.defnLine) called: \(frame.callLine)")
        let paramSet = Set(frame.params)
        lines.append("  parameters:")
        for param in frame.params {
            let value = frame.symbols[param] ?? .null
            lines.append("    \(param): \(formatProgramValue(value))")
        }
        lines.append("  automatics:")
        for name in frame.symbols.keys.sorted() where !paramSet.contains(name) {
            let value = frame.symbols[name] ?? .null
            lines.append("    \(name): \(formatProgramValue(value))")
        }

        return lines.joined(separator: "\n")
    }

    /// Format the contents of a symbol table into a string.
    private func formatSymbolTable(_ table: SymbolTable, indent: String = "") -> String {
        if table.isEmpty {
            return "\(indent)<empty>"
        }
        return table.keys.sorted().map { name in
            let value = table[name] ?? .null
            return "\(indent)\(name): \(formatProgramValue(value))"
        }
        .joined(separator: "\n")
    }

    /// Format a program value as a string.
    private func formatProgramValue(_ value: ProgramValue?) -> String {
        let v = value ?? .null
        return "\(v.typeName): \(v.displayValue)"
    }

    private func showFrame() {
        guard let frame = callStack.last else { return }
        output.writeln(formatFrame(frame))
    }
}
