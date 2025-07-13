//
//  Test.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 30 December 2025.
//  Last changed on 13 July 2025.
//

import Foundation

private let sharedDateFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
	formatter.locale = Locale(identifier: "en_US_POSIX")
	return formatter
}()

func currentTimeWithMilliseconds() -> String {
	let date = Date()
	return sharedDateFormatter.string(from: date)
}

@main
struct DeadEndsMain {

	static func main() {
		realMain()
	}

	static func realMain() {
		let path = "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged"
		var errlog = ErrorLog()
		print("Creating Database from \(path)")
		guard let database = getDatabaseFromPath(path, errlog: &errlog) else {
			print(errlog)
			return
		}
		// Check name processing stuff. The extension below for nameValues should move elsewhere.
//		for person in database.persons {
//			let names = person.nameValues()
//			print("person \(person.key!) has the names \(names)")
//			for name in names {
//				print("\(name): \(gedcomNameOf(name)!)")
//			}
//		}
		print("Database created!")
		print("Number of persons: \(database.personCount)")
		print("Number of families: \(database.familyCount)")
		var count = 0
		for person in database.persons {
			count += person.count()
		}
		print("Number of nodes in persons: \(count)")
		count = 0
		for family in database.families {
			count += family.count()
		}
		print("Number of nodes in families: \(count)")
        for person in database.persons.prefix(5) {
			print("Person: \(person.tag) \(person.key ?? "No Key")")
		}
        let persons = database.persons(withName: "t t/wtmr/iv")
		for person in persons {
			person.printTree()
		}
		persons[0].traverse { node in
			let line = node.offset() + 1
			let level = node.level()
			print("\(line)\t\(level) \(node)")
		}
	}
}


extension GedcomNode {

	// nameValues returns the non-empty values of all 1 NAME nodes in a person.
	func nameValues() -> [String] {
		var names: [String] = []
		self.traverseChildren { node in
			if node.tag == "NAME" {
				if let value = node.value {
					names.append(value)
				}
			}
		}
		return names
	}
}
