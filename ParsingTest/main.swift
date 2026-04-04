//
//  main.swift
//  ParsingTest
//
//  Created by Thomas Wetmore on 4/3/26.
//

import Foundation
import Parsing

let parser: some Parser<Substring.UTF8View, Int> = Int.parser()

var input = "123"[...].utf8

if let result = try? parser.parse(&input) {
    print(result)
}
