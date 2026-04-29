//
//  BuiltinMeta.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 April 2026.
//  Last changed on 28 April 2026.
//
//  The built-ins in this file are used to inspect running
//  programs. They are used to help users debug their programs
//  (and the developer to debug the interpreter!)

import Foundation

/* showframe, showstack, valueof, typeof, showexpr */

extension Program {

    func builtinShowFrame(_ args: [ParsedExpr]) -> ProgramValue {
        return .null
    }

    func builtinShowStack(_ args: [ParsedExpr]) throws -> ProgramValue {
        showRuntimeStack()
        return .null
    }

    func builtInTypeOf(_ args: [ParsedExpr]) -> ProgramValue {
        return .null
    }

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
        output.writeln("Run Time Stack")
        for frame in callStack.reversed() {
            output.writeln(formatFrame(frame))
        }
        output.writeln("Global symbols:")
        output.writeln(formatSymbolTable(globalSymbolTable, indent: "    "))
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
}
