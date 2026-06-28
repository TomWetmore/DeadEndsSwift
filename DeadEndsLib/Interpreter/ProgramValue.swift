//
//  ProgramValue.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 28 June 2026.
//
//  ProgramValue is the type of the expressions in the DeadEnds
//  programming language. It is an enumeration with associated types.
//

import Foundation

/// Values of DeadEnds program expressions.
public enum ProgramValue: @unchecked Sendable, Equatable {

    case null
    case ident(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case string(String)
    case gnode(GedcomNode)
    case person(Person)
    case family(Family)
    //case source(GedcomNode)
    //case event(GedcomNode)
    //case other(GedcomNode)
    case list(List)
    case table(ProgramTable)
    case personset(PersonSet<ProgramValue>)
    case traverse(GedcomNode)
    case allPersons
    case allFamilies

    /// Description of a program value.
    var description: String {

        switch self {
        case .null: return "null"
        case .ident(let string): return "\(string))"
        case .integer(let integer): return "\(integer)"
        case .double(let double): return "\(double)"
        case .boolean(let bool): return "\(bool)"
        case .string(let string): return "\"\(string)\""
        case .gnode(let node): return "\(node)"
        case .person(let person): return "\(person)"
        default: return "not implememented yet"
        }
    }

    /// Type name strings for the program value kinds.
    var typeName: String {

        switch self {
        case .null: return "null"
        case .boolean: return "boolean"
        case .integer: return "integer"
        case .double: return "double"
        case .string: return "string"
        case .person: return "person"
        case .family: return "family"
        case .gnode: return "gnode"
        case .personset: return "indiset"
        case .table: return "table"
        case .ident(_): return "ident"
        case .list(_): return "list"
        case .traverse(_): return "traverse"
        case .allPersons: return "allPersons"
        case .allFamilies: return "allFamilies"
        }

    }

    /// Value strings for the program value kinds.
    var displayValue: String {
        switch self {
        case .null:
            return "null"
        case .boolean(let b):
            return b ? "true" : "false"
        case .integer(let i):
            return String(i)
        case .double(let d):
            return String(d)
        case .string(let s):
            return s
        case .person(let p):
            return p.key + " " +  p.displayName()
        case .family(let f):
            return f.key
        case .gnode(let node):
            return node.description
        case .personset(let set):
            return "\(set.count) persons"
        case .table(let table):
            return "\(table.count) entries" // adjust to your table wrapper
        case .ident(_): return "ident"
        case .traverse(_): return "traverse"
        case .allPersons: return "allPersons"
        case .allFamilies: return "allFamilies"
        case .list(let list):
            let maxItems = 10
            var parts: [String] = []
            parts.reserveCapacity(maxItems)

            var shown = 0
            for value in list {
                if shown >= maxItems { break }
                parts.append(value.displayValue)
                shown += 1
            }

            if list.count > maxItems {
                return "[" + parts.joined(separator: ", ") + ", ... (\(list.count) total)]"
            } else {
                return "[" + parts.joined(separator: ", ") + "]"
            }
        }
    }

    /// Conform program values to equatable.
    public static func == (lhs: ProgramValue, rhs: ProgramValue) -> Bool {

        switch (lhs, rhs) {
        case let (.integer(i1), .integer(i2)):
            return i1 == i2
        case let (.double(f1), .double(f2)):
            return f1 == f2
        case let (.boolean(b1), .boolean(b2)):
            return b1 == b2
        case let (.string(s1), .string(s2)):
            return s1 == s2
        case let (.gnode(n1), .gnode(n2)):
            return n1 === n2 // Reference equality.
        case let (.person(p1), .person(p2)):
            return p1.key == p2.key
        case let (.family(f1), .family(f2)):
            return f1.key == f2.key
        default:
            return false
        }
    }
}

/// Constant values for booleans.
extension ProgramValue {

    static let trueProgramValue: ProgramValue = .boolean(true)
    static let falseProgramValue: ProgramValue = .boolean(false)
}

extension ProgramValue {

    /// Convert any ProgramValue to a boolean program value using C rules.
    var toBool: Bool {

        switch self {
        case .boolean(let value): return value
        case .integer(let value): return value != 0
        case .double(let value): return value != 0.0
        case .string(let value): return !value.isEmpty
        case .null: return false
        default: return true // TODO: Other types now default to true; this needs work.
        }
    }
}

/// Numeric string operations.
extension ProgramValue {

    // Add two program values and return the result; works for integers, doubles and strings.
    public static func addPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {

        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)): return .integer(i1 + i2)
        case let (.double(f1), .double(f2)): return .double(f1 + f2)
        case let (.string(s1), .string(s2)): return .string(s1 + s2)
        default: return .null
        }
    }

    /// Subtract the second program value from the first and return the result.
    static func subPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {

        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)): return .integer(i1 - i2)
        case let (.double(f1), .double(f2)): return .double(f1 - f2)
        default: return .null
        }
    }

    /// Multiply two program values and return the result.
    static func mulPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)): return .integer(i1 * i2)
        case let (.double(f1), .double(f2)): return .double(f1 * f2)
        default: return .null
        }
    }

    /// Divides the first program value by the second and return the result;
    /// zero divisors are not allowed.
    static func divPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {

        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)) where i2 != 0: return .integer(i1 / i2)
        case let (.double(f1), .double(f2)) where f2 != 0.0: return .double(f1 / f2)
        default: return .null
        }
    }

    /// Takes the modulus of the first value by the second and returns the result;
    /// a zero modulus is not allowed.
    static func modPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {

        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)) where i2 != 0: return .integer(i1 % i2)
        default: return .null
        }
    }

    /// Negate a program value and return the result; works for integers and doubles.
    static func negPValue(_ val: ProgramValue) -> ProgramValue {
        switch val {
        case let .integer(i): return .integer(-i)
        case let .double(f): return .double(-f)
        default: return .null
        }
    }

    /// Increment a program value and return the result.
    /// THIS METHOD IS NOT USED.
    static func incrPValue(_ val: ProgramValue) -> ProgramValue {

        switch val {
        case let .integer(i): return .integer(i + 1)
        default: return .null
        }
    }

    /// Decrement a program value and return the result.
    /// THIS METHOD IS NOT USED.
    static func decrPValue(_ val: ProgramValue) -> ProgramValue {
        switch val {
        case let .integer(i):
            return .integer(i - 1)
        default:
            return .null
        }
    }

    /// Raise the first program value by the second and return the result.
    static func expPValues(_ base: ProgramValue, _ exponent: ProgramValue) -> ProgramValue {
        switch (base, exponent) {
        case let (.integer(b), .integer(e)) where e >= 0:
            return .integer(Int(pow(Double(b), Double(e))))
        case let (.double(b), .integer(e)) where e >= 0:
            return .double(pow(b, Double(e)))
        default: return .null
        }
    }
}

/// Comparison operations.
extension ProgramValue {

    /// Generic compare function for program values.
    static func compare(_ val1: ProgramValue, _ val2: ProgramValue,
                        using comparator: (Int, Int) -> Bool) -> ProgramValue {

        switch (val1, val2) {
        case let (.integer(i1), .integer(i2)):
            return .boolean(comparator(i1, i2))
        case let (.double(f1), .double(f2)):
            return .boolean(comparator(Int(f1), Int(f2)))
        case let (.string(s1), .string(s2)):
            return .boolean(comparator(s1.compare(s2).rawValue, 0))
        default: return .null
        }
    }

    /// Check that the first program value is less than the second.
    static func ltPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 < $1 })
    }

    /// Check that the first program value is less than or equal to the the second.
    static func lePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 <= $1 })
    }

    /// Check that the first program value is greater than the second.
    static func gtPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 > $1 })
    }

    /// Check that the first program value is greater than or equal to the second.
    static func gePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 >= $1 })
    }

    /// Check that the two programs values are equal.
    static func eqPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 == $1 })
    }

    /// Check that the two program values are not equal.
    static func nePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
        compare(val1, val2, using: { $0 != $1 })
    }
}

/// Logical operations.
extension ProgramValue {

    /// Check that a program value is numeric (integer or double).
    static func isNumeric(_ value: ProgramValue) -> Bool {
        switch value {
        case .integer, .double:
            return true
        default:
            return false
        }
    }
}

extension ProgramValue {
    static var emptyList: ProgramValue {
        .list(List())
    }
}
