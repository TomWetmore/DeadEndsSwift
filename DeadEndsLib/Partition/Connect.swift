//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 16 March 2026.
//

import Foundation

struct ConnectData {
    var numAncestors: Int? = nil
    var numDescendants: Int? = nil
}

typealias ConnectIndex = [RecordKey: ConnectData]


/// Get numbers of ancestors and descendants for persons in a list.
extension RecordIndex {

//    func getConnections(personRoots: [Root], dataIndex: inout ConnectIndex, index: RecordIndex) {
//        var connectIndex = ConnectIndex()
//
//        // For each person root
//        for root in personRoots {
//            guard let key = root.key
//            else { fatalError("person node must have a key") }
//            let data = ConnectData()
//
//            //
//            var data = dataIndex[key] ?? ConnectData()
//            if data.numAncestors == nil {
//                data.numAncestors = index.numAncestors(person)}
//            if !data.ancestorsDone {
//                data.numAncestors = getNumAncestors(person, dataIndex: &dataIndex, index: index)
//                data.ancestorsDone = true
//            }
//            if !data.descendentsDone {
//                data.numDescendants = getNumDescendants(person, dataIndex: &dataIndex, index: index)
//                data.descendentsDone = true
//            }
//        }
//    }

//    func numAncestors(_ root: Root, index: inout ConnectIndex) {
//
//        guard let key = root.key
//        else { fatalError("person root does not have a key") }
//        if index[key] != nil { return }  // Memoized.
//        var data = ConnectData()
//        index[key] = data
//        data.numAncestors
//    }
}

/// Return number of ancestors a person has.
//func getNumAncestors(_ root: Root, dataIndex: inout ConnectIndex, index: RecordIndex) -> Int {
//    guard let key = root.key, var data = dataIndex[key]
//    else { fatalError("INDI node must have a key") }
//    if data.ancestorsDone { return data.numAncestors } // Memoization.
//
//    var ancestors = 0
//    for kid in root.kids(withTag: "FAMC") { // all FAMC nodes in person.
//        guard let key = kid.val, let family = index[key], family.tag == "FAM"
//        else { fatalError("could not resolve a FAMC link") }
//        for pkid in family.kids(withTags: ["HUSB", "WIFE"]) {
//            guard let pkey = pkid.val, let parent = index[pkey], parent.key == "INDI"
//            else { fatalError("could not resolve a HUSB or WIFE link") }
//            ancestors += 1 + getNumAncestors(parent, dataIndex: &dataIndex, index: index)
//        }
//    }
//    data.numAncestors = ancestors
//    data.ancestorsDone = true
//    dataIndex[key] = data
//    return ancestors
//}


/// TRYOUT

extension RecordIndex {

    /// Find all ancestors of a person; argument and results are root nodes.
    public func ancestors(of personRoot: Root) -> [Root] {
        guard let startKey = personRoot.key
        else { fatalError("INDI record must have a key") }
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = parentKeys(of: startKey)
        var next = 0
        var result: [Root] = []
        
        while next < queue.count {
            let key = queue[next]
            next += 1
            guard !visited.contains(key) else { continue }
            visited.insert(key)
            // Look up the record root that this key refers to.
            guard let root = self[key] else {
                fatalError("cannot lookup up a record in the index")
            }
            // Append that record root to the results list.
            result.append(root)
            queue.append(contentsOf: parentKeys(of: key))
        }
        return result
    }

    /// Find all ancestors of a person. Argument and results are person structures.
    public func ancestors(of person: Person) -> [Person] {
        let roots = ancestors(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of ancestors of a person; argument is a person root.
    public func numAncestors(of personRoot: Root) -> Int {
        return ancestors(of: personRoot).count
    }

    /// Return number of ancestors of a person; argument is a person structure.
    public func numAncestors(of person: Person) -> Int {
        ancestors(of: person.root).count
    }
}

extension RecordIndex {

    /// Find all descendants of a person; argument and results are person roots.
    public func descendants(of personRoot: Root) -> [Root] {
        guard let startKey = personRoot.key else {
            fatalError("INDI node must have a key")
        }
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = childrenKeys(of: startKey)
        var next = 0
        var result: [Root] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            guard !visited.contains(key) else { continue }
            visited.insert(key)

            guard let root = self[key]
            else { fatalError("cannot lookup up a record in the index") }

            result.append(root)
            queue.append(contentsOf: childrenKeys(of: key))
        }
        return result
    }

    /// Find all descendants of a person; argument and results are person structures.
    public func descendants(of person: Person) -> [Person] {
        let roots = descendants(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of descendants of a person; argument is a person root.
    public func numDescendants(of personRoot: Root) -> Int {
        return descendants(of: personRoot).count
    }

    /// Return number of descendanta of a person; argument is a person structure.
    public func numDescendants(of person: Person) -> Int {
        descendants(of: person.root).count
    }
}

extension RecordIndex {

    /// Return the keys of the parents of a person.
    func parentKeys(of personKey: RecordKey) -> [RecordKey] {
        guard let root = self[personKey], root.tag == GedcomTag.INDI
        else { fatalError("parentKeys called with non-person key") }
        var result: [RecordKey] = []

        for famc in root.kids(withTag: GedcomTag.FAMC) {
            guard let famKey = famc.val,
                  let famRoot = self[famKey],
                  famRoot.tag == GedcomTag.FAM
            else { fatalError("invalid FAMC link") }

            for parentNode in famRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                if let parentKey = parentNode.val {
                    result.append(parentKey)
                }
            }
        }
        return result
    }

    /// Return the keys of the children of a person.
    func childrenKeys(of personKey: RecordKey) -> [RecordKey] {
        guard let root = self[personKey], root.tag == GedcomTag.INDI
        else { fatalError("childrenKeys called with non-person key") }
        var result: [RecordKey] = []
        for fams in root.kids(withTag: GedcomTag.FAMS) {
            guard let famKey = fams.val,
                  let famRoot = self[famKey],
                  famRoot.tag == GedcomTag.FAM
            else { fatalError("invalid FAMS link") }

            for childNode in famRoot.kids(withTag: GedcomTag.CHIL) {
                if let childKey = childNode.val {
                    result.append(childKey)
                }
            }
        }
        return result
    }
}

extension RecordIndex {

    /// Return parent persons of a given person.
    func parents(of person: Person) -> [Person] {
        guard let key = person.root.key
        else { fatalError("INDI record must have a key") }
        return parentKeys(of: key).compactMap { self.person(for: $0) }
    }
}

//// createConnectData creates the data field used in GNodeIndexEls in the Partition program.
//ConnectData* createConnectData(void) {
//    ConnectData* data = (ConnectData*) stdalloc(sizeof(ConnectData));
//    data->ancestorsDone = data->descendentsDone = false;
//    data->numAncestors = data->numDescendents = 0;
//    return data;
//}

// getConnections finds the numbers of ancestors and descendents of the persons in a list. The
// numbers are kept in ConnectData structs in the GNodeIndex. list is a List of GNode* roots,
// and index is an index of all all persons and families.
//void getConnections(List* list, GNodeIndex* index) {
//    FORLIST(list, el)
//        GNode* root = (GNode*) el;
//        GNodeIndexEl* el  = (GNodeIndexEl*) searchHashTable(index, root->key);
//        ConnectData* data = el->data;
//        if (!data->ancestorsDone) getNumAncestors(root, index);
//        if (!data->descendentsDone) getNumDescendents(root, index);
//    ENDLIST
//}
//
//// getNumAncestors returns the number of ancestors a person has.
//static int getNumAncestors(GNode* root, GNodeIndex* index) {
//    GNodeIndexEl* element = searchHashTable(index, root->key);
//    ConnectData* data = element->data;
//    if (data->ancestorsDone) return data->numAncestors; // Memoized.
//
//    // Find number of ancestors.
//    int ancestors = 0;
//    for (GNode* pnode = root->child; pnode; pnode = pnode->sibling) {
//        if (eqstr("FAMC", pnode->tag)) { // Families this person is a child in.
//            GNodeIndexEl* felement = searchHashTable(index, pnode->value);
//            GNode* family = felement->root;
//            for (GNode* fnode = family->child; fnode; fnode = fnode->sibling) {
//                if (eqstr("HUSB", fnode->tag) || eqstr("WIFE", fnode->tag)) {
//                    GNodeIndexEl* pelement = searchHashTable(index, fnode->value);
//                    ancestors += 1 + getNumAncestors(pelement->root, index);
//                }
//            }
//        }
//    }
//    data->ancestorsDone = true;
//    data->numAncestors = ancestors;
//    return ancestors;
//}
//
//// getNumDescendents returns the number of descendents a person has.
//static int getNumDescendents(GNode* root, GNodeIndex* index) {
//    GNodeIndexEl* element = searchHashTable(index, root->key);
//    ConnectData* data = element->data;
//    if (data->descendentsDone) return data->numDescendents; // Memoized.
//
//    // Find number of descendents.
//    int descendents = 0;
//    for (GNode* pnode = root->child; pnode; pnode = pnode->sibling) {
//        if (eqstr("FAMS", pnode->tag)) { // Families this person is a spouse/parent in.
//            GNodeIndexEl* felement = searchHashTable(index, pnode->value);
//            GNode* family = felement->root;
//            for (GNode* fnode = family->child; fnode; fnode = fnode->sibling) {
//                if (eqstr("CHIL", fnode->tag)) { // Children in this family are descendents.
//                    GNodeIndexEl* pelement = searchHashTable(index, fnode->value);
//                    descendents += 1 + getNumDescendents(pelement->root, index);
//                }
//            }
//        }
//    }
//    data->descendentsDone = true;
//    data->numDescendents = descendents;
//    return descendents;
//}
//
//// createConnectData creates the data field used in GNodeIndexEls in the Partition program.
//ConnectData* createConnectData(void) {
//    ConnectData* data = (ConnectData*) stdalloc(sizeof(ConnectData));
//    data->ancestorsDone = data->descendentsDone = false;
//    data->numAncestors = data->numDescendents = 0;
//    return data;
//}
//
//// show is a static function passed to showGNodeIndex in order to show the ConnectData struct.
//static void show(void* data) {
//    ConnectData* connectData = data;
//    if (connectData->ancestorsDone) printf("%d : ", connectData->numAncestors);
//    else printf("- : ");
//    if (connectData->descendentsDone) printf("%d\n", connectData->numDescendents);
//    else printf("-\n : ");
//}
//
//// debugGNodeIndex prints the contents of a GNodeIndex.
//void debugGNodeIndex(GNodeIndex* index) {
//    showGNodeIndex(index, show);
//}
//
