//
//  PersonSetGedcom.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 April 2026.
//  Last changed on 18 April 2026.
//

import Foundation

/// Goal is generate a Gedcom file from a person set of persons. Only persons in
/// the set are included. Families the persons link to are included, but persons
/// the families refer to who are not in the original set are not included and
/// their links are removed from the families.
///

//func PersonSetToRecordIndex<Payload>(in index: RecordIndex,
//                                     personSet: PersonSet<Payload>) -> RecordIndex {
//
//    // Create a record index.
//    var localIndex = RecordIndex()
//    // Add the persons in the set to that index.
//    for element in personSet {
//        localIndex[element.key] = element.root
//    }
//    // Iterate all families referred to by all persons.
//    for element in personSet {
//        let famNodes = element.root.kids(withTags: [GedcomTag.FAMC, GedcomTag.FAMS])
//        for famNode in famNodes {
//            // famNode is a FAMC or FAMS node from the current person from the set.
//            // Get the families and make a deep copy.
//            let famRoot = index.requireRoot(from: famNode, tag: GedcomTag.FAM).deepCopy()
//            // Look at all the HUSB, WIFE, and CHIL links and keep the ones that refer to
//            // persons in the local index.
//            let nodes = famRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE,
//                                                GedcomTag.CHIL])
//            for node in nodes {
//                let key = node.requireKey
//            }
//        }
//    }
//    return localIndex
//}








//void sequenceToGedcom(Sequence *sequence, FILE *fp) {
//    if (!sequence) return;
//    RecordIndex* index = sequence->index;
//    if (!fp) fp = stdout;
//    personSequence = sequence;  // Yuck. External access to these two sequences are required.
//    familySequence = createSequence(index);
//    StringTable *personTable = createStringTable(numBucketsInSequenceTables); // Table of person keys.
//    StringTable *familyTable = createStringTable(numBucketsInSequenceTables); // Table of family keys.
//
//    // Add all person keys to the person key hash table.
//    FORSEQUENCE(sequence, element, num)
//        addToStringTable(personTable, element->root->key, null);
//    ENDSEQUENCE
//    FORSEQUENCE(sequence, element, num) // For each person in the sequence ...
//        GNode *person = keyToPerson(element->root->key, index);  // Get the person ...
//        SexType sex = SEXV(person);  //  ... and the person's sex.
//        //  Check the person's parent families to see if any FAMC families should be output.
//        FORFAMCS(person, family, key, index)
//            if (isInHashTable(familyTable, family->key)) goto a;
//            normalizeFamily(family);
//            GNode *husband = HUSB(family);
//            if (husband && isInHashTable(personTable, husband->value)) {
//                appendToSequence(familySequence, familyToKey(family), 0);
//                addToStringTable(familyTable, familyToKey(family), null);
//                goto a;
//            }
//            GNode *wife = WIFE(family);
//            if (wife && isInHashTable(personTable, wife->value)) {
//                appendToSequence(familySequence, familyToKey(family), 0);
//                addToStringTable(familyTable, familyToKey(family), null);
//                goto a;
//            }
//            // Check if any of the children in this family are in the sequence.
//            FORCHILDREN(family, child, chilKey, count, index)
//                String childKey = personToKey(child);
//                if (isInHashTable(personTable, childKey)) {
//                    appendToSequence(familySequence, familyToKey(family), 0);
//                    addToStringTable(familyTable, familyToKey(family), null);
//                    goto a;
//                }
//            ENDCHILDREN
//        ENDFAMCS
//
//        //  Check the person's as parent families to see if they should output.
//    a:    FORFAMSS(person, family, key, index)
//            if (isInHashTable(familyTable, familyToKey(family))) goto b;
//            GNode *spouse = familyToSpouse(family, oppositeSex(sex), index);
//            if (spouse && isInHashTable(personTable, personToKey(spouse))) {
//                appendToSequence(familySequence, familyToKey(family), 0);
//                addToStringTable(familyTable, familyToKey(family), null);
//            }
//    b:;    ENDFAMSS
//    ENDSEQUENCE
//
//    FORSEQUENCE(personSequence, element, count)
//        writeLimitedPerson(keyToPerson(element->root->key, index));
//    ENDSEQUENCE
//
//    FORSEQUENCE(familySequence, element, count)
//        writeLimitedFamily(keyToFamily(element->root->key, index));
//    ENDSEQUENCE
//    deleteSequence(familySequence);
//    deleteHashTable(personTable);
//    deleteHashTable(familyTable);
//}
//
