//
//  main.swift
//  ParsingTest
//
//  Created by Thomas Wetmore on 4/3/26.
//

import Foundation
import DeadEndsLib
import Parsing

testLexer()
testParser()
try testInterpreter()

let parser: some Parser<Substring.UTF8View, Int> = Int.parser()

var input = "142"[...].utf8

if let result = try? parser.parse(&input) {
    print(result)
}

func testLexer() {

    guard let text = readFile(at: "/Users/ttw4/Desktop/DeadEndsVScode/Scripts/eol.ll")
    else { fatalError("Could not read test.txt") }
    showTokens(from: text)
    print("Second Test")
    var testString = "- . -. 129. .5 -.5 \"abc\n\" / \""
    showTokens(from: testString)
    testString = "- . -. 132. .5 -.5 \"abc\\n\" / \""
    showTokens(from: testString)
}

func showTokens(from text: String) {
    var lexer = Lexer(source: text)
    while true {
        let token = lexer.nextToken()
        print(token)
        if token.kind == .eof { break }
    }
}

func readFile(at path: String) -> String? {
    guard let contents = try? String(contentsOfFile: path, encoding: .utf8)
    else { return nil }
    return contents
}

func loadDatabase() -> Database {
    print("Reading Gedcom File in database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else { fatalError("Could not load database") }
    print("Database loaded successfully\n\(database)")
    return database
}


func testInterpreter() throws {
    print("test interpreter")
    
    let database = loadDatabase()
    let program =
        """
        proc main ()
        {
            set(i, indi("@I1@"))
            "hello, world\n"
            name(i)  "; " name(i)  "\n" name(i) nl()
        }
        """
    try runProgram(source: program, database: database, output: ConsoleOutput())
}




