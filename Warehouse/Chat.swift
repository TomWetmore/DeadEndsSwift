//
//  Chat.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 9/16/25.
//

//import Foundation
//import DeadEndsLib
//
//// ALL FROM CHAT GPT SEPTEMBER 16, 2025
//// PUBLIC INTERFACE BETWEEN LIBRARY AND APPLICATION CODE:
//
//// In DeadEndsLib
//
//public extension GedcomNode {
//
//    // MARK: - Basic queries
//
//    /// Returns the last sibling in this node's sibling chain (self if none).
//    var lastSibling: GedcomNode {
//        var n: GedcomNode = self
//        while let s = n.sibling { n = s }
//        return n
//    }
//
//    /// True iff `candidate` is in our ancestor chain (used to prevent cycles).
//    func isAncestor(of candidate: GedcomNode) -> Bool {
//        var p = candidate.parn
//        while let cur = p {
//            if cur === self { return true }
//            p = cur.parn
//        }
//        return false
//    }
//
//    // MARK: - Safe detach
//
//    /// Detaches this node from its parent & sibling chain. Returns `true` if a change occurred.
//    @discardableResult
//    func detachFromParent() -> Bool {
//        guard let p = parn else { return false }
//
//        if p.child === self {
//            // We're the first child
//            p.child = sibling
//        } else {
//            // Find the previous sibling and bypass self
//            var prev = p.child
//            while let cur = prev, cur.sibling !== self { prev = cur.sibling }
//            prev?.sib = sibling
//        }
//
//        // Clear our links
//        self.parn = nil
//        self.sib = nil
//        return true
//    }
//
//    // MARK: - Replace all children (bulk)
//
//    /// Replaces this node's entire children list with `newFirstChild`,
//    /// setting `parent` for every node in the incoming chain.
//    func replaceChildren(with newFirstChild: GedcomNode?) {
//        // Re-parent the incoming chain
//        var c = newFirstChild
//        while let n = c {
//            // defensive: avoid forming a cycle
//            precondition(!n.isAncestor(of: self), "Replacing children would create a cycle")
//            n.parn = self
//            c = n.sibling
//        }
//        self.child = newFirstChild
//    }
//
//    // MARK: - Insert / append children (single-node)
//
//    /// Appends `n` as the last child. `n` must be detached (no parent/sibling).
//    func appendChild(_ n: GedcomNode) {
//        precondition(n.parn == nil && n.sibling == nil, "appendChild requires a detached node")
//        precondition(!isAncestor(of: n), "appendChild would create a cycle")
//
//        n.parn = self
//        if child == nil {
//            child = n
//        } else {
//            child!.lastSibling.sib = n
//        }
//    }
//
//    /// Prepends `n` as the first child. `n` must be detached (no parent/sibling).
//    func prependChild(_ n: GedcomNode) {
//        precondition(n.parn == nil && n.sibling == nil, "prependChild requires a detached node")
//        precondition(!isAncestor(of: n), "prependChild would create a cycle")
//
//        n.parn = self
//        n.sib = child
//        child = n
//    }
//
//    /// Inserts `n` after `prev` within our children. If `prev == nil`, behaves like `prependChild`.
//    func insertChild(_ n: GedcomNode, after prev: GedcomNode?) {
//        precondition(n.parn == nil && n.sibling == nil, "insertChild requires a detached node")
//        precondition(!isAncestor(of: n), "insertChild would create a cycle")
//
//        if let prev {
//            // Sanity: prev must be our child somewhere in the chain
//            #if DEBUG
//            var seen = child; var ok = false
//            while let cur = seen { if cur === prev { ok = true; break }; seen = cur.sibling }
//            assert(ok, "insertChild(after:) 'prev' is not one of this node's children")
//            #endif
//
//            n.parn = self
//            n.sib = prev.sib
//            prev.sib = n
//        } else {
//            prependChild(n)
//        }
//    }
//
//    // MARK: - Remove child (single-node)
//
//    /// Removes the given child from our children list. Returns `true` if removed.
//    @discardableResult
//    func removeChild(_ n: GedcomNode) -> Bool {
//        guard n.parn === self else { return false }
//
//        if child === n {
//            child = n.sibling
//        } else {
//            var prev = child
//            while let cur = prev, cur.sib !== n { prev = cur.sib }
//            prev?.sib = n.sib
//        }
//
//        n.parn = nil
//        n.sib = nil
//        return true
//    }
//
//    /// Removes all children (clears parent on the entire chain).
//    func removeAllChildren() {
//        var c = child
//        while let n = c {
//            n.parn = nil
//            let next = n.sibling
//            n.sib = nil
//            c = next
//        }
//        child = nil
//    }
//}
//
//// Auto-detach to be forgiving:
////if n.parent != nil || n.sibling != nil { _ = n.detachFromParent() ; n.sibling = nil }
//
//
//// Swap all children (your earlier use case)
////old.root.replaceChildren(with: new.root.child)
//
//// Or fine-grained edits
////let child = GedcomNode(tag: "NAME", value: "…")
////personRoot.appendChild(child)
////personRoot.removeChild(child)
//
//
//
////public final class EditService {
////    public init(database: Database) { self.db = database }
////    private let db: Database
////
////    // Persons/Families lifecycle
////    public func createPerson(_ template: PersonInfo) -> Result<Person, EditError>
////    public func createFamily(husband: Person?, wife: Person?) -> Result<Family, EditError>
////    public func deletePerson(_ p: Person) -> Result<Void, EditError>
////    public func deleteFamily(_ f: Family) -> Result<Void, EditError>
////
////    // Relationships
////    public func marry(husband: Person, wife: Person) -> Result<Family, EditError>
////    public func divorce(_ f: Family) -> Result<Void, EditError>
////    public func addChild(_ child: Person, to family: Family) -> Result<Void, EditError>
////    public func moveChild(_ child: Person, from oldFamily: Family, to newFamily: Family) -> Result<Void, EditError>
////    public func setParents(of child: Person, to family: Family?) -> Result<Void, EditError>
////
////    // Attributes
////    public func updatePerson(_ p: Person, with info: PersonInfo) -> Result<Void, EditError>
////    public func updateFamily(_ f: Family, with info: FamilyInfo) -> Result<Void, EditError>
////
////    // Transactions / undo
////    public func begin()                // optional explicit txn
////    public func commit() -> [Delta]    // return concrete deltas for undo stack
////    public func rollback()
////}
////
////public enum EditError: Error {
////    public typealias RawValue = <#type#>
////
////    case notFound(String)                // key/id
////    case invalidKind                     // expected INDI/FAM and got the other
////    case alreadyMarried(Person)          // policy-dependent
////    case childAlreadyInFamily(Person, Family)
////    case cycleDetected                   // invariant protection
////    case sexInconsistent                 // if you enforce SEX vs role
////    case indexViolation(String)          // name/refn uniqueness etc.
////    case validation([String])            // batch of domain errors
////}
////
////public enum Delta {
////    case addNode(key: String, snapshot: GedcomText)       // or a structured snapshot
////    case removeNode(key: String, snapshot: GedcomText)
////    case setParent(child: String, oldParent: String?, newParent: String?)
////    case setSpouses(family: String, oldHusb: String?, oldWife: String?, newHusb: String?, newWife: String?)
////    case setChildList(parent: String, oldFirstChild: String?, newFirstChild: String?)
////    case setValue(node: String, tag: String, old: String?, new: String?)
////    case nameIndexAdd(name: String, key: String)
////    case nameIndexRemove(name: String, key: String)
////    case refnIndexAdd(refn: String, key: String)
////    case refnIndexRemove(refn: String, key: String)
////}
////
////public func marry(husband: Person, wife: Person) -> Result<Family, EditError> {
////    begin(); defer { if case .failure = result { rollback() } }
////    // 1) Validate policies (not already married? sex constraints?)
////    // 2) Create new FAM node (key)
////    let famRoot = db.makeFamilyNode()            // creates a new "0 @F123@ FAM" record
////    famRoot.setValue(husband.key, forTag: "HUSB")
////    famRoot.setValue(wife.key,    forTag: "WIFE")
////
////    // 3) Wire cross references on the persons (FAMS)
////    db.addFAMS(to: husband.node, familyKey: famRoot.key!)
////    db.addFAMS(to: wife.node,    familyKey: famRoot.key!)
////
////    // 4) Update indexes if needed (none for FAM by default)
////    // 5) Emit deltas in order
////    record(.addNode(key: famRoot.key!, snapshot: famRoot.gedcomText()))
////    record(.setSpouses(family: famRoot.key!, oldHusb: nil, oldWife: nil, newHusb: husband.key, newWife: wife.key))
////    // 6) Commit
////    let fam = Family(famRoot)!
////    return commitReturning(.success(fam))
////}
////
////public func addChild(_ child: Person, to family: Family) -> Result<Void, EditError> {
////    begin(); defer { if case .failure = result { rollback() } }
////    // FAMC on child; CHIL on family
////    let famKey = family.key!
////    guard db.addFAMC(to: child.node, familyKey: famKey) else { return .failure(.validation(["child already has FAMC \(famKey)"])) }
////    db.addCHIL(to: family.node, childKey: child.key!)
////
////    record(.setValue(node: child.key!, tag: "FAMC", old: nil, new: famKey))
////    record(.setValue(node: famKey, tag: "CHIL", old: nil, new: child.key))
////    return commitReturning(.success(()))
////}
////
////public func updatePerson(_ p: Person, with info: PersonInfo) -> Result<Void, EditError> {
////    begin(); defer { if case .failure = result { rollback() } }
////
////    // Names diff
////    let added = info.names.subtracting(p.currentNames())
////    let removed = p.currentNames().subtracting(info.names)
////    for n in removed { db.nameIndex.remove(value: n, recordKey: p.key!) ; record(.nameIndexRemove(name: n, key: p.key!)) }
////    for n in added   { db.nameIndex.add(value: n, recordKey: p.key!)    ; record(.nameIndexAdd(name: n, key: p.key!)) }
////
////    // Raw GEDCOM node modifications (e.g., updating NAME, REFN etc.)
////    // Emit .setValue deltas per change
////
////    return commitReturning(.success(()))
////}
////
////private func validate(_ checks: [() -> String?]) -> [String] {
////    checks.compactMap { $0() }
////}
////
////private let q = DispatchQueue(label: "deadends.editservice")
////public func marry(...) -> Result<Family, EditError> {
////    return q.sync { /* perform mutation + deltas */ }
////}
////
////
