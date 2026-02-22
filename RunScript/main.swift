//
//  main.swift
//  ReadPNodes
//  This is the test  program that checks the C-PNode to S-Expression to Swift-ProgramNode process.
//
//  Created by Thomas Wetmore on 7 March 2025.
//  Last changed on 19 February 2026.
//

import Foundation
import DeadEndsLib

// Main program.
do {
    try runPipeline()
} catch {
    print("Top level catch")
    print("Fatal error: \(error.localizedDescription)")
    exit(1)
}

// runPipeline runs the top level sequence of steps that 1) reads a file with a program-level SExpression;
// 2) builds the internal SExpression program; 3) builds the ProgramNode AST of the program  from the SExpression;
// 4) reads a Database; and 5) runs the program with the Database.
func runPipeline() throws {
    print("Begin pipeline execution")

    // Read a DeadEnds program as an s-expression from a text file.
    let fileURL = URL(fileURLWithPath: "/Users/ttw4/xfer")
    let sexprString: String
    do {
        sexprString = try String(contentsOf: fileURL, encoding: .utf8)
        print("Read S-expression from file:\n\(sexprString)")
    } catch {
        throw RuntimeError.io("Could not read S-expression file: \(error)")
    }

    // Tokenize the string.
    var parser = SExpressionParser(sexprString)
    print("Tokenizing input")
    let tokens = parser.tokenArray()
    print("Token count: \(tokens.count)")
    for (i, token) in tokens.enumerated() {
        print("\(i + 1): \(token)")
    }

    // Parse the tokens into the top level program s-expression.
    let programSExpression: SExpression
    do {
        print("Parsing the program SExpressionr")
        programSExpression = try parser.parseProgramSExpression()
    } catch {
        throw RuntimeError.syntax("Failed to parse program s-expression: \(error)")
    }

    // Create the program nodes making up the AST of the DeadEnds program.
    print("Building the DeadEnds program node AST from the s-expression")
    guard case .list(_) = programSExpression else {
        throw RuntimeError.syntax("Top-level s-expression must be a list")
    }
    let procedures: [String : ProgramNode]
    let functions: [String : ProgramNode]
    let globals: [String : ProgramValue?]
    do {
        (procedures, functions, globals) = try convertToTables(programSExpression)
    } catch {
        throw RuntimeError.syntax("Failed to convert SExpr to ProgramNodes: \(error)")
    }
    if !procedures.isEmpty { print("Procedures:"); procedures.forEach { print($0) } } // DEBUG
    if !functions.isEmpty  { print("Functions:");  functions.forEach  { print($0) } } // DEBUG
    if !globals.isEmpty    { print("Globals:");    globals.forEach    { print($0) } } // DEBUG

    // Load a database from a Gedcom file.
    print("Reading Gedcom file into database")
    var errLog: [Error] = []
    let database = loadDatabase("/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let db = database else {
        throw RuntimeError.missingDatabase("Could not load Gedcom file into database.")
    }
    print("Database loaded successfully")

    // Create a Program and run it.
    print("Creating and running program")
    let program = Program(procTable: procedures, funcTable: functions, globalTable: globals)
    do {
        try program.interpretProgram(database: db)
        print("Program execution complete")
    } catch {
        throw RuntimeError.executionFailed("Script execution failed: \(error)")
    }
}

//// Functions below are waiting to be used when test futher along.
//// runCScriptParser runs the C executable that parses scripts and generates S-Expressions.
//func runParserOnInput(filePath: String) throws -> String {
//    let process = Process()
//    let outputPipe = Pipe()
//
//    process.executableURL = URL(fileURLWithPath: "/Users/ttw4/bin/gensexpr")
//    process.arguments = [filePath]
//    process.standardOutput = outputPipe
//    process.standardError = FileHandle.nullDevice // Optional: suppress stderr
//
//    try process.run()
//    process.waitUntilExit()
//
//    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//    guard let outputString = String(data: outputData, encoding: .utf8) else {
//        throw RuntimeError.executionFailed("Parser did not return valid UTF-8 text")
//    }
//    return outputString
//}
