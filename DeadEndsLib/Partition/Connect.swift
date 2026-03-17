//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 16 March 2026.
//

import Foundation

struct ConnectData {
    var ancestorsDone: Bool = false
    var numAncestors: Int = 0
    var descendentsDone: Bool = false;
    var numDescendants: Int = 0;
}

typealias ConnectIndex = [RecordKey: ConnectData]


/// Get numbers of ancestors and descendants for persons in a list.
func getConnections(persons: [Root], dataIndex: inout ConnectIndex, index: RecordIndex) {
    for person in persons {
        guard let key = person.key else { fatalError("INDI node must have a key") }
        // TODO: In C code the index already exists; not here. TODO.
        var data = dataIndex[key] ?? ConnectData()
        if !data.ancestorsDone {
            data.numAncestors = getNumAncestors(person, dataIndex: &dataIndex, index: index)
            data.ancestorsDone = true
        }
        if !data.descendentsDone {
            data.numDescendants = getNumDescendants(person, dataIndex: &dataIndex, index: index)
            data.descendentsDone = true
        }
    }
}

/// Return number of ancestors a person has.
func getNumAncestors(_ root: Root, dataIndex: inout ConnectIndex, index: RecordIndex) -> Int {
    guard let key = root.key, var data = dataIndex[key]
    else { fatalError("INDI node must have a key") }
    if data.ancestorsDone { return data.numAncestors } // Memoization.

    var ancestors = 0
    for kid in root.kids(withTag: "FAMC") { // all FAMC nodes in person.
        guard let key = kid.val, let family = index[key], family.tag == "FAM"
        else { fatalError("could not resolve a FAMC link") }
        for pkid in family.kids(withTags: ["HUSB", "WIFE"]) {
            guard let pkey = pkid.val, let parent = index[pkey], parent.key == "INDI"
            else { fatalError("could not resolve a HUSB or WIFE link") }
            ancestors += 1 + getNumAncestors(parent, dataIndex: &dataIndex, index: index)
        }
    }
    data.numAncestors = ancestors
    data.ancestorsDone = true
    dataIndex[key] = data
    return ancestors
}

func getNumDescendants(_ root: Root, dataIndex: inout ConnectIndex, index: RecordIndex) -> Int {
    return 0
}

/// Without memoization.

///
extension Database {

    func numAncestors(person: Person) {
        return numAncestors(root: person.root)
    }

    func numAncestors(root: Root){}
}

// getNumAncestors returns the number of ancestors a person has.
//static int getNumAncestors(GNode* root, GNodeIndex* index) {
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
