//
//  DeadEndsLib
//  ProgramValue.swift
//
//  ProgramValue is the type of program values during program interpreting. They are the values of expressions
//  and are the values stored in symbol tables.
//
//  Created by Thomas Wetmore on 17 March 2025.
//  Last changed on 20 June 2025.
//

import Foundation
   
// ProgramValue is an enumeration with associated types.
public enum ProgramValue: @unchecked Sendable, Equatable {
	case null
	case any
	case integer(Int)
	case double(Double)
	case boolean(Bool)
	case string(String)
	case gnode(GedcomNode)
	//case person(GedcomNode)
	//case family(GedcomNode)
	//case source(GedcomNode)
	//case event(GedcomNode)
	//case other(GedcomNode)
	case list(List<ProgramValue>)
	case table
	case sequence

	func isNodeType(type: ProgramValue) -> Bool {
		// WRITE ME
		return false
	}

	// description returns a description of a program value.
	var	description: String {
		return "WRITE ME"
	}

	// == conforms PValue to Equatable.
	public static func == (lhs: ProgramValue, rhs: ProgramValue) -> Bool {
		switch (lhs, rhs) {
		case (.null, .null), (.any, .any), (.list, .list), (.table, .table), (.sequence, .sequence):
			return true
		case let (.integer(i1), .integer(i2)):
			return i1 == i2
		case let (.double(f1), .double(f2)):
			return f1 == f2
		case let (.boolean(b1), .boolean(b2)):
			return b1 == b2
		case let (.string(s1), .string(s2)):
			return s1 == s2
		case let (.gnode(n1), .gnode(n2)):
			return n1 === n2 // Reference equality for nodes
		default:
			return false
		}
	}
}

extension ProgramValue {
    static let trueProgramValue: ProgramValue = .boolean(true)
    static let falseProgramValue: ProgramValue = .boolean(false)
}

extension ProgramValue {
    // toBool converts any PValue to a .bool PValue using C-like rules.
    func toBool() -> Bool {
        switch self {
            case .boolean(let value): return value
            case .integer(let value): return value != 0
            case .double(let value): return value != 0.0
            case .string(let value): return !value.isEmpty
            case .null: return false
            default: return true // TODO: Other types default to true.
        }
    }
}

// ProgramValue extension for numeric string operations.
extension ProgramValue {

	// addPValues adds two values and returns the result; string arguments allowed.
	public static func addPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)): return .integer(i1 + i2)
		case let (.double(f1), .double(f2)): return .double(f1 + f2)
		case let (.string(s1), .string(s2)): return .string(s1 + s2)
		default: return .null
		}
	}

	// subPValues subtracts the second value from the first and returns the result.
	static func subPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)): return .integer(i1 - i2)
		case let (.double(f1), .double(f2)): return .double(f1 - f2)
		default: return .null
		}
	}

	// mulPValues multiplies two values and returns the result.
	static func mulPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)): return .integer(i1 * i2)
		case let (.double(f1), .double(f2)): return .double(f1 * f2)
		default: return .null
		}
	}

	// divPValues divides the first value by the second and returns the result; zero divisors not allowed.
	static func divPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)) where i2 != 0: return .integer(i1 / i2)
		case let (.double(f1), .double(f2)) where f2 != 0.0: return .double(f1 / f2)
		default: return .null
		}
	}

	// modPValues takes the modulus of the first value by the second and returns the result; zero modulus not allowed.
	static func modPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)) where i2 != 0: return .integer(i1 % i2)
		default: return .null
		}
	}

	// negPValues negates a value and returns the result.
	static func negPValue(_ val: ProgramValue) -> ProgramValue {
		switch val {
		case let .integer(i): return .integer(-i)
		case let .double(f): return .double(-f)
		default: return .null
		}
	}

	// incrPValue increments a value and returns the result.
	static func incrPValue(_ val: ProgramValue) -> ProgramValue {
		switch val {
		case let .integer(i): return .integer(i + 1)
		default: return .null
		}
	}

	// decrPValue decrements a value and returns the result.
	static func decrPValue(_ val: ProgramValue) -> ProgramValue {
		switch val {
		case let .integer(i): return .integer(i - 1)
		default: return .null
		}
	}

	// expPValue raises the first value by the second and returns the result.
	static func expPValues(_ base: ProgramValue, _ exponent: ProgramValue) -> ProgramValue {
		switch (base, exponent) {
		case let (.integer(b), .integer(e)) where e >= 0: return .integer(Int(pow(Double(b), Double(e))))
		case let (.double(b), .integer(e)) where e >= 0: return .double(pow(b, Double(e)))
		default: return .null
		}
	}
}

// ProgramValue extension for comparison operations.
extension ProgramValue {

	// compare is a generic compare function for ProgramValues.
	static func compare(_ val1: ProgramValue, _ val2: ProgramValue, using comparator: (Int, Int) -> Bool) -> ProgramValue {
		switch (val1, val2) {
		case let (.integer(i1), .integer(i2)): return .boolean(comparator(i1, i2))
		case let (.double(f1), .double(f2)): return .boolean(comparator(Int(f1), Int(f2)))
		case let (.string(s1), .string(s2)): return .boolean(comparator(s1.compare(s2).rawValue, 0))
		default: return .null
		}
	}

	// lessThan checks if the first value is < second and return boolean.
	static func ltPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 < $1 })
	}

	static func lePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 <= $1 })
	}

	static func gtPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 > $1 })
	}

	static func gePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 >= $1 })
	}

	static func eqPValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 == $1 })
	}

	static func nePValues(_ val1: ProgramValue, _ val2: ProgramValue) -> ProgramValue {
		compare(val1, val2, using: { $0 != $1 })
	}
}
// ProgramValue extension for logical operations.
extension ProgramValue {

    static func isNumeric(_ value: ProgramValue) -> Bool {
        switch value {
            case .integer, .double:
                return true
            default:
                return false
        }
    }
}
