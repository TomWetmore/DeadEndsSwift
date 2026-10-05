//
//  BuiltinRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 2 October 2026.
//  Last changed on 2 October 2026.
//

import Foundation


/// Built-ins for children, sons, daughters, brothers, sisters, parents, fathers,
/// mothers, father, and mother.

extension Program {

    /// Return the children of a Person, Family, or PersonSet.
    /// children(person|family) -> list<person>
    /// children(personset) -> personset
    /// children(null) -> empty list
    ///
    func bltinChildren(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let children = person.children(in: recordIndex)
            return .list(ListValue(children.map { ProgramValue.person($0) }))

        case .family(let family):
            let children = family.children(in: recordIndex)
            return .list(ListValue(children.map { ProgramValue.person($0) }))

        case .personset(let set):
            return .personset(set.children(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("children: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the sons of a Person, Family, or PersonSet.
    /// sons(person|family) -> list<person>
    /// sons(personset) -> personset
    /// sons(null) -> empty list
    ///
    func bltinSons(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let sons = person.sons(in: recordIndex)
            return .list(ListValue(sons.map {ProgramValue.person($0)}))

        case .family(let family):
            let sons = family.sons(in: recordIndex)
            return .list(ListValue(sons.map {ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.sons(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("sons: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the daughters of a Person, Family, or PersonSet.
    /// daughters(person|family) -> list<person>
    /// daughters(personset) -> personset
    /// daughters(null) -> empty list
    ///
    func bltinDaughters(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let daughters = person.daughters(in: recordIndex)
            return .list(ListValue(daughters.map {ProgramValue.person($0)}))

        case .family(let family):
            let daughters = family.daughters(in: recordIndex)
            return .list(ListValue(daughters.map {ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.daughters(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("daughters: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the brothers of a Person or PersonSet.
    /// brothers(person) -> list<person>
    /// brothers(personset) -> personset
    /// brothers(null) -> empty list
    ///
    func bltinBrothers(_ args: [ParsedExpr]) async throws -> ProgramValue {
        switch try await evaluate(args[0]) {

        case .person(let person):
            let brothers = person.brothers(in: recordIndex)
            return .list(ListValue(brothers.map {ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.brothers(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("brothers: arg must be a person or personset",
                               line: args[0].line)
        }
    }

    /// Return the sisters of a Person or PersonSet.
    /// sisters(person) -> list<person>
    /// sisters(personset) -> personset
    /// sisters(null) -> empty list
    ///
    func bltinSisters(_ args: [ParsedExpr]) async throws -> ProgramValue {
        switch try await evaluate(args[0]) {

        case .person(let person):
            let sisters = person.sisters(in: recordIndex)
            return .list(ListValue(sisters.map {ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.sisters(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("sisters: arg must be a person or personset",
                               line: args[0].line)
        }
    }

    /// Return the parents of a Person, Family, or PersonSet.
    /// parents(person|family) -> list<person>
    /// parents(personset) -> personset
    /// parents(null) -> empty list
    ///
    func bltinParents(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line

        switch try await evaluate(args[0]) {

        case .person(let person):
            let parents = person.parents(in: recordIndex)
            return .list(ListValue(parents.map { ProgramValue.person($0) }))

        case .family(let family):
            let parents = family.spouses(in: recordIndex) // Define parents of a family and the spouses.
            return .list(ListValue(parents.map { ProgramValue.person($0) }))

        case .personset(let set):
            let parents = PersonSet()
            for element in set.elements {
                for parent in element.person.parents(in: recordIndex) {
                    parents.insert(parent)
                }
            }
            return .personset(parents)

        case .null:
            return .emptyList

        default:
            throw RuntimeError("parents: arg must be a person, family, or personset",
                               line: line)
        }
    }

    /// Return the fathers of a Person, Family, or PersonSet.
    /// fathers(person|family) -> list<person>
    /// fathers(personset) -> personset
    /// fathers(null) -> empty list
    ///
    func bltinFathers(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value = try await evaluate(args[0])
        switch value {

        case .person(let person):
            let values = person.fathers(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .family(let family):
            let values = family.fathers(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .personset(let set):
            return .personset(set.fathers(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("fathers: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the mothers of a person, family, or personset.
    /// mothers(person|family) -> list<person>
    /// mothers(personset) -> personset
    /// mother(null) -> empty list
    ///
    func bltinMothers(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let values = person.mothers(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .family(let family):
            let values = family.mothers(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .personset(let set):
            return .personset(set.mothers(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("mothers: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the first father of a Person. For now, do not add a version for PersonSet
    /// father(person|family) -> person|null
    /// father(null) -> null
    ///
    func bltinFather(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            if let father = person.father(in: recordIndex) {
                return .person(father)
            } else {
                return .null
            }
        case .family(let family):
            if let father = family.father(in: recordIndex) {
                return .person(father)
            } else {
                return .null
            }
        case .null:
            return .null

        default: throw RuntimeError("father: arg must be a person, family, or null",
                                    line: args[0].line)
        }
    }

    /// Return the first mother of a Person. For now, do not add a version for PersonSet
    /// mother(person|family) -> person|null
    /// mother(null) -> null
    ///
    func bltinMother(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            if let mother = person.mother(in: recordIndex) {
                return .person(mother)
            } else {
                return .null
            }
        case .family(let family):
            if let mother = family.mother(in: recordIndex) {
                return .person(mother)
            } else {
                return .null
            }
        case .null:
            return .null

        default: throw RuntimeError("mother: arg must be a person, family, or null",
                                    line: args[0].line)
        }
    }
}

/// Built-ins for spouses, husbands, wives, husband, and wife.
///
extension Program {

    /// Return the spouses of a Person, Family, or Personset.
    /// spouses(person|family) -> list<person>
    /// spouses(personset) -> personset
    /// spouses(null) -> empty list
    ///
    func bltinSpouses(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let spouses = person.spouses(in: recordIndex)
            return .list(ListValue(spouses.map { ProgramValue.person($0) }))

        case .family(let family):
            let spouses = family.spouses(in: recordIndex)
            return .list(ListValue(spouses.map { ProgramValue.person($0) }))

        case .personset(let set):
            return .personset(set.spouses(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("spouses: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the husbands of a Person, Family, or Personset.
    /// husbands(person|family) -> list<person>
    /// husbands(personset) -> personset
    /// husbands(null) -> empty list
    ///
    func bltinHusbands(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let husbands = person.husbands(in: recordIndex)
            return .list(ListValue(husbands.map { ProgramValue.person($0)}))

        case .family(let family):
            let husbands = family.husbands(in: recordIndex)
            return .list(ListValue(husbands.map { ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.husbands(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("husbands: arg must be a person, family, or personset",
                               line: args[0].line)
        }
    }

    /// Return the wives of a Person, Family or PersonSet.
    /// wives(person|family) -> list<person>
    /// wives(personset) -> personset
    /// wives(null) -> empty list
    ///
    func bltinWives(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let wives = person.wives(in: recordIndex)
            return .list(ListValue(wives.map { ProgramValue.person($0)}))

        case .family(let family):
            let wives = family.wives(in: recordIndex)
            return .list(ListValue(wives.map { ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.wives(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("wives: arg must be a person, family, or person set",
                               line: args[0].line)
        }
    }

    /// Return the first husband of a Person or Family.
    /// husband(person|family) -> person|null
    /// husband(null) -> null
    ///
    func bltinHusband(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            return person.husband(in: recordIndex).map { .person($0) } ?? .null

        case .family(let family):
            return family.husband(in: recordIndex).map { .person($0) } ?? .null

        case .null:
            return .null
            
        default:
            throw RuntimeError("husband: arg must be a person or family",
                               line: args[0].line)
        }
    }

    /// Return the first wife of a Person or Family.
    /// wife(person|family) -> person|null
    /// wife(null) -> null
    ///
    func bltinWife(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            return person.wife(in: recordIndex).map { .person($0) } ?? .null

        case .family(let family):
            return family.wife(in: recordIndex).map { .person($0) } ?? .null

        case .null:
            return .null

        default:
            throw RuntimeError("wife: arg must be a person or family",
                               line: args[0].line)
        }
    }
}

extension Program {

    /// Return the siblings of a Person or PersonSet.
    /// siblings(person) -> list<person>
    /// siblings(personset) -> personset
    /// siblings(null) -> empty list
    ///
    func bltinSiblings(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let siblings = person.siblings(in: recordIndex)
            return .list(ListValue(siblings.map { ProgramValue.person($0)}))

        case .personset(let set):
            return .personset(set.siblings(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("siblings: arg must be a person",
                               line: args[0].line)
        }
    }

    /// Returns the ancestors of a Person or PersonSet.
    /// ancestors(person) -> list<person>
    /// ancestors(personset) -> personset
    /// ancestors(null) -> empty list
    ///
    func bltinAncestors(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let values = person.ancestors(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .personset(let set):
            return .personset(set.ancestors(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("ancestors: arg must be a person or personset",
                               line: args[0].line)
        }
    }

    /// Returns the descendants of a Person or PersonSet.
    /// descendants(person) -> list<person>
    /// descendants(personset) -> personset
    /// descendants(null) -> empty list
    ///
    func bltinDescendants(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .person(let person):
            let values = person.descendants(in: recordIndex).map { ProgramValue.person($0) }
            return .list(ListValue(values))

        case .personset(let set):
            return .personset(set.descendants(in: recordIndex))

        case .null:
            return .emptyList

        default:
            throw RuntimeError("descendants: arg must be a person or personset",
                               line: args[0].line)
        }
    }
}
