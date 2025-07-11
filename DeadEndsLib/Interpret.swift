//
//  Interpret.swift
//  This file has many of the functions that interpret DeadEnds program.
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 March 2025.
//  Last changed on 21 April 2025.
//

import Foundation

public enum InterpResult {
    case okay
    case returning(ProgramValue?)
    case breaking
    case continuing
    case error
}

public func runProgram(program: Program) throws {
    // Create a database.
}


extension Program {

    // interpret is the top level interpreter. Its parameter is a ProgramNode. It handles some kinds of ProgramNodes directly,
    // and call separate functions for others.
    func interpret(_ node: ProgramNode) throws -> InterpResult {
        switch node.kind {
            case let .string(string): // Output string value.
                print(string, terminator: "")
            case .integer, .double: // Ignore numbers.
                break
            case .identifier: // Output identifer value if it is a string.
                let value = try evaluateIdent(node)
                if case let .string(output) = value {
                    print(output, terminator: "")
                }
            case .builtinCall: // Call builtin function.
                let result = try evaluateBuiltin(node)
                if case let .string(output) = result {
                    print(output, terminator: "")
                }
            case let .procedureCall(name, _): // Call user defined procedure.
                switch try interpretProcedure(node) {
                    case .okay:
                        break
                    case .error:
                        throw RuntimeError.runtimeError("Error calling procedure: \(name)")
                    case .returning(let value):
                        return .returning(value)
                    case .breaking:
                        return .breaking
                    case .continuing:
                        return .continuing
                }
            case .functionCall:
                let result = try evaluateFunction(node)
                if case let .string(output) = result {
                    print(output, terminator: "")
                }
            case let .ifState(condition, thenc, elsec):
                let result: Bool = try evaluateCondition(condition)
                let blockToExecute = result ? thenc : elsec
                if let block = blockToExecute {
                    return try interpret(block)
                }
                return .okay
            case let .whileState(condition, body):
                while true {
                    if !(try evaluateCondition(condition)) { break } // Break this while loop.
                    let result = try interpret(body)
                    switch result {
                    case .breaking:
                        break
                    case .returning:
                        return result
                    case .error:
                        return .error
                    case .continuing, .okay:
                        continue // Continue this loop.
                    }
                }
                return .okay
            case .breakState:
                return .breaking
            case .continueState:
                return .continuing
            case let .returnState(resultExpr):
                let returnValue = try resultExpr.map { try evaluate($0) }
                return .returning(returnValue)
            case .block:
                return try interpretBlock(node)
            default:
                throw RuntimeError.runtimeError("Unhandled statement type: \(node.kind)")
        }
        return .okay // TODO: Can this be reached? Or does it just keep the compiler happy?
    }

    // interpretBlock interperts a .block PNode.
    func interpretBlock(_ pnode: ProgramNode) throws -> InterpResult {
        guard case let .block(statements) = pnode.kind else {
            throw RuntimeError.invalidSyntax("Expected a block node")
        }
        for statement in statements {
            let result = try interpret(statement)
            switch result { // Handle control flow.
            case .okay:
                continue // No control flow break, keep going
            case .returning, .breaking, .continuing:
                return result // Propagate return/break/continue upward
            case .error:
                return .error
            }
        }
        return .okay
    }

    // interpretProcedure interprets a .procedureCall ProgramNode.
    func interpretProcedure(_ pnode: ProgramNode) throws -> InterpResult {
        guard case let .procedureCall(name, args) = pnode.kind else { // pnode must be a .procedureCall.
            throw RuntimeError.invalidSyntax("Expected a procedure call")
        }
        guard let procDef = procedureTable[name] else { // Procedure called must exit.
            throw RuntimeError.undefinedSymbol("Procedure '\(name)' not found")
        }
        guard case let .procedureDef(_, params, body) = procDef.kind else { // Overkill?
            throw RuntimeError.invalidSyntax("Expected a procedure definition for '\(name)'")
        }
        guard args.count == params.count else { // Numbers of args and params must be the same.
            throw RuntimeError.invalidArguments("Procedure '\(name)' expects \(params.count) arguments, got \(args.count)")
        }
        var table: SymbolTable = [:] // Create symbol table for the procedure.
        for (param, arg) in zip(params, args) { // Bind the evaluated args to the params in the symbol table.
            let value = try evaluate(arg) // Evaluate the argument.
            table[param] = value // Bind the argument's value to the parameter.
        }
        pushCallFrame(table) // Push and pop the call frame.
        defer { popCallFrame() }

        return try interpret(body) // Interpret the procedure body.
    }
}

//// interpChildren interprets the children loop statement, looping through the children of a family.
//// usage: children(FAM, INDI_V, INT_V) {...}
//// fields: pFamilyExpr, pChildIden, pCountIden, pLoopState
//InterpType interpChildren (ProgramNode* pnode, Context* context, PValue* pval) {
//    bool eflg = false;
//    GNode *fam =  evaluateFamily(pnode->familyExpr, context, &eflg);
//    if (eflg || !fam || nestr(fam->tag, "FAM")) {
//        scriptError(pnode, "the first argument to children must be a family");
//        return InterpError;
//    }
//    FORCHILDREN(fam, chil, key, nchil, context->database->recordIndex) {
//        assignValueToSymbol(context->symbolTable, pnode->childIden, PVALUE(PVPerson, uGNode, chil));
//        assignValueToSymbol(context->symbolTable, pnode->countIden, PVALUE(PVInt, uInt, nchil));
//        InterpType irc = interpret(pnode->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto a;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    a:    ;
//    } ENDCHILDREN
//    return InterpOkay;
//}
//
//// interpSpouses interpret the spouses statement looping through the spouses of a person.
//// usage: spouses(INDI, INDI_V, FAM_V, INT_V) {...}
//// fields: pPersonExpr, pSpouseIden, pFamilyIden, pCountIden, pLoopState
//InterpType interpSpouses(ProgramNode* pnode, Context* context, PValue *pval) {
//    bool eflg = false;
//    GNode *indi = evaluatePerson(pnode->personExpr, context, &eflg);
//    if (eflg || !indi || nestr(indi->tag, "INDI")) {
//        scriptError(pnode, "the first argument to spouses must be a person");
//        return InterpError;
//    }
//    FORSPOUSES(indi, spouse, fam, nspouses, context->database->recordIndex) {
//        assignValueToSymbol(context->symbolTable, pnode->spouseIden, PVALUE(PVPerson, uGNode, spouse));
//        assignValueToSymbol(context->symbolTable, pnode->familyIden, PVALUE(PVFamily, uGNode, fam));
//        assignValueToSymbol(context->symbolTable, pnode->countIden, PVALUE(PVInt, uInt, nspouses));
//
//        InterpType irc = interpret(pnode->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto b;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    b:    ;
//    } ENDSPOUSES
//    return InterpOkay;
//}
//
//// interpFamilies interprets the families statement looping through the families a person is a spouse in.
//// usage: families(INDI, FAM_V, INDI_V, INT_V) {...}
//// fields: pPersonExpr, pFamilyIden, pSpouseIden, pCountIden, pLoopState
////--------------------------------------------------------------------------------------------------
//InterpType interpFamilies(ProgramNode* node, Context* context, PValue *pval) {
//    bool eflg = false;
//    GNode *indi = evaluatePerson(node->personExpr, context, &eflg);
//    if (eflg || !indi || nestr(indi->tag, "INDI")) {
//        scriptError(node, "the first argument to families must be a person");
//        return InterpError;
//    }
//    GNode *spouse = null;
//    int count = 0;
//    //Database *database = context->database;
//    RecordIndex* index = context->database->recordIndex;
//    FORFAMSS(indi, fam, key, index) {
//        assignValueToSymbol(context->symbolTable, node->familyIden, PVALUE(PVFamily, uGNode, fam));
//        SexType sex = SEXV(indi);
//        if (sex == sexMale) spouse = familyToWife(fam, index);
//        else if (sex == sexFemale) spouse = familyToHusband(fam, index);
//        else spouse = null;
//        assignValueToSymbol(context->symbolTable, node->spouseIden, PVALUE(PVPerson, uGNode, spouse));
//        assignValueToSymbol(context->symbolTable, node->countIden, PVALUE(PVInt, uInt, ++count));
//        InterpType irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto c;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    c:    ;
//    }
//    ENDFAMSS
//    return InterpOkay;
//}
//
//// interpFathers interprets the father loop statement. Most persons will only have one father in a
//// database, so most of the time the loop body is interpreted once.
//InterpType interpFathers(ProgramNode* node, Context* context, PValue *pval) {
//    bool eflg = false;
//    GNode *indi = evaluatePerson(node->personExpr, context, &eflg);
//    if (eflg || !indi || nestr(indi->tag, "INDI")) {
//        scriptError(node, "the first argument to fathers must be a person");
//        return InterpError;
//    }
//    int nfams = 0;
//    FORFAMCS(indi, fam, key, context->database->recordIndex)
//        GNode *husb = familyToHusband(fam, context->database->recordIndex);
//        if (husb == null) goto d;
//        assignValueToSymbol(context->symbolTable, node->familyIden, PVALUE(PVFamily, uGNode, fam));
//        assignValueToSymbol(context->symbolTable, node->fatherIden, PVALUE(PVFamily, uGNode, husb));
//        assignValueToSymbol(context->symbolTable, node->countIden, PVALUE(PVInt, uInt, ++nfams));
//        InterpType irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto d;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    d:        ;
//    ENDFAMCS
//    return InterpOkay;
//}
//
//// interpMothers interprets the mother loop statement. Most persons will only have one mother in a
//// database, so most of the time the loop body is interpreted once.
//InterpType interpMothers (PNode* node, Context* context, PValue *pval) {
//    bool eflg = false;
//    GNode *indi = evaluatePerson(node->personExpr, context, &eflg);
//    if (eflg || !indi || nestr(indi->tag, "INDI")) {
//        scriptError(node, "the first argument to mothers must be a person");
//        return InterpError;;
//    }
//    int nfams = 0;
//    FORFAMCS(indi, fam, key, context->database->recordIndex) {
//        GNode *wife = familyToWife(fam, context->database->recordIndex);
//        if (wife == null) goto d;
//        //  Assign the current loop identifier valujes to the symbol table.
//        assignValueToSymbol(context->symbolTable, node->familyIden, PVALUE(PVFamily, uGNode, fam));
//        assignValueToSymbol(context->symbolTable, node->motherIden, PVALUE(PVFamily, uGNode, wife));
//        assignValueToSymbol(context->symbolTable, node->countIden, PVALUE(PVInt, uInt, ++nfams));
//
//        // Intepret the body of the loop.
//        InterpType irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto d;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    d:        ;
//    }  ENDFAMCS
//    return InterpOkay;
//}
//
//// interpParents -- Interpret parents loop; this loops over all families a person is a child in.
//// TODO: Does this exist in LifeLines?
//InterpType interpParents(PNode* node, Context* context, PValue *pval) {
//    bool eflg = false;
//    InterpType irc;
//    GNode *indi = evaluatePerson(node->personExpr, context, &eflg);
//    if (eflg || !indi || nestr(indi->tag, "INDI")) {
//        scriptError(node, "the first argument to parents must be a person");
//        return InterpError;
//    }
//    int nfams = 0;
//    FORFAMCS(indi, fam, key, context->database->recordIndex) {
//        assignValueToSymbol(context->symbolTable, node->familyIden, PVALUE(PVFamily, uGNode, fam));
//        assignValueToSymbol(context->symbolTable, node->countIden,  PVALUE(PVInt, uInt, ++nfams));
//        irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay: goto f;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    f:    ;
//    }
//    ENDFAMCS
//    return InterpOkay;
//}
//
//// interp_fornotes -- Interpret NOTE loop
//InterpType interp_fornotes(ProgramNode* node, Context* context, PValue *pval) {
//    ASSERT(node && context);
//    bool eflg = false;
//    InterpType irc;
//    GNode *root = evaluateGedcomNode(node, context, &eflg);
//    if (eflg) {
//        scriptError(node, "1st arg to fornotes must be a record line");
//        return InterpError;
//    }
//    if (!root) return InterpOkay;
//    FORTAGVALUES(root, "NOTE", sub, vstring) {
//        assignValueToSymbol(context->symbolTable, node->gnodeIden, PVALUE(PVString, uString, vstring));
//        irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay:
//                goto g;
//            case InterpBreak:
//                return InterpOkay;
//            default:
//                return irc;
//        }
//    g:      ;
//    } ENDTAGVALUES
//    return InterpOkay;
//}
//
//// interp_fornodes interpret the fornodes statement looping though the children of a GNode.
//// usage: fornodes(NODE, NODE_V) {...}; fields: pGNodeExpr, pNodeIden, pLoopState
//InterpType interp_fornodes(PNode* node, Context* context, PValue *pval) {
//    bool eflg = false;
//    GNode *root = evaluateGedcomNode(node->gnodeExpr, context, &eflg);
//    if (eflg || !root) {
//        scriptError(node, "the first argument to fornodes must be a Gedcom node/line");
//        return InterpError;
//    }
//    GNode *sub = root->child;
//    while (sub) {
//        assignValueToSymbol(context->symbolTable, node->gnodeIden, PVALUE(PVGNode, uGNode, sub));
//        InterpType irc = interpret(node->loopState, context, pval);
//        switch (irc) {
//            case InterpContinue:
//            case InterpOkay:
//                sub = sub->sibling;
//                continue;
//            case InterpBreak: return InterpOkay;
//            default:
//                return irc;
//        }
//    }
//    return InterpOkay;
//}
//
//// interpForindi interprets the forindi statement looping through all persons in the Database.
//// Usage: forindi(INDI_V, INT_V) {...}; Fields: personIden, countIden, loopState.
//InterpType interpForindi (ProgramNode* pnode, Context* context, PValue* pvalue) {
//    RootList *rootList = context->database->personRoots;
//    sortList(rootList); // Sort by key.
//    int numPersons = lengthList(rootList);
//    for (int i = 0; i < numPersons; i++) {
//        String key = rootList->getKey(getListElement(rootList, i));
//        GNode* person = keyToPerson(key, context->database->recordIndex);
//        if (person) {
//            assignValueToSymbol(context->symbolTable, pnode->personIden, PVALUE(PVPerson, uGNode, person));
//            assignValueToSymbol(context->symbolTable, pnode->countIden, PVALUE(PVInt, uInt, i));
//            InterpType irc = interpret(pnode->loopState, context, pvalue);
//            switch (irc) {
//                case InterpContinue:
//                case InterpOkay: continue;
//                case InterpBreak:
//                case InterpReturn: goto e;
//                case InterpError: return InterpError;
//            }
//        } else {
//            printf("HIT THE ELSE IN INTERPFORINDI--PROBABLY NOT GOOD\n");
//        }
//    }
//e:  removeFromHashTable(context->symbolTable, pnode->personIden);
//    removeFromHashTable(context->symbolTable, pnode->countIden);
//    return InterpOkay;
//}
///////*========================================+
////// * interp_forsour -- Interpret forsour loop
////// *  usage: forsour(SOUR_V,INT_V) {...}
////// *=======================================*/
//InterpType interp_forsour (ProgramNode *node, Context *context, PValue *pval)
//{
//////    NODE sour;
//////    static char key[MAXKEYWIDTH];
//////    STRING record;
//////    INTERPTYPE irc;
//////    INT len, count = 0;
//////    INT scount = 0;
//////    insert_pvtable(stab, inum(node), PINT, 0);
//////    while (TRUE) {
//////        printkey(key, 'S', ++count);
//////        if (!(record = retrieve_record(key, &len))) {
//////            if(scount < num_sours()) continue;
//////            break;
//////        }
//////        if (!(sour = stringToGNodeTree(record))) continue;
//////        scount++;
//////        insert_pvtable(stab, ielement(node), PSOUR,
//////                       sour_to_cacheel(sour));
//////        insert_pvtable(stab, inum(node), PINT, (VPTR)count);
//////        irc = interpret((PNODE) ibody(node), stab, pval);
//////        free_nodes(sour);
//////        stdfree(record);
//////        switch (irc) {
//////            case INTCONTINUE:
//////            case INTOKAY:
//////                continue;
//////            case INTBREAK:
//////                return INTOKAY;
//////            default:
//////                return irc;
//////        }
//////    }
//////    return INTOKAY;
//    return InterpOkay;
//}
////
//
//// interp_foreven interpret the foreven statement looping through all events in the Database.
//// usage: foreven(EVEN_V,INT_V) {...}
//// THIS IS BASED ON LIFELINES ASSUMPTIONS AND DOES NOT YET WORK IN DEADENDS.
//InterpType interp_foreven (ProgramNode* node, Context* context, PValue *pval) {
//    int numEvents = numberEvents(context->database);
//    int numMisses = 0;
//    char scratch[10];
//    for (int i = 1; i <= numEvents; i++) {
//        sprintf(scratch, "E%d", i);
//        GNode *event = keyToEvent(scratch, context->database->recordIndex);
//        if (event) {
//            assignValueToSymbol(context->symbolTable, node->eventIden, PVALUE(PVEvent, uGNode, event));
//            assignValueToSymbol(context->symbolTable, node->countIden, PVALUE(PVInt, uInt, i));
//            InterpType irc = interpret(node->loopState, context, pval);
//            switch (irc) {
//                case InterpContinue:
//                case InterpOkay: continue;
//                case InterpBreak:
//                case InterpReturn: goto e;
//                case InterpError: return InterpError;
//            }
//        } else {
//            numMisses++;
//        }
//    }
//e:  removeFromHashTable(context->symbolTable, node->personIden);
//    removeFromHashTable(context->symbolTable, node->countIden);
//    return InterpOkay;
//}
//
//// interp_forothr Interprets the forothr statement looping through all events in the Database.
//// usage: forothr(OTHR_V,INT_V) {...}
//// THIS IS BASED ON LIFELINES ASSUMPTIONS AND DOES NOT YET WORK IN DEADENDS.
//InterpType interp_forothr(ProgramNode *node, Context *context, PValue *pval) {
//    int numOthers = numberOthers(context->database);
//    int numMisses = 0;
//    char scratch[10];
//    for (int i = 1; i <= numOthers; i++) {
//        sprintf(scratch, "X%d", i);
//        GNode *event = keyToEvent(scratch, context->database->recordIndex);
//        if (event) {
//            assignValueToSymbol(context->symbolTable, node->otherIden, PVALUE(PVEvent, uGNode, event));
//            assignValueToSymbol(context->symbolTable, node->countIden, PVALUE(PVInt, uInt, i));
//            InterpType irc = interpret(node->loopState, context, pval);
//            switch (irc) {
//                case InterpContinue:
//                case InterpOkay: continue;
//                case InterpBreak:
//                case InterpReturn: goto e;
//                case InterpError: return InterpError;
//            }
//        } else {
//            numMisses++;
//        }
//    }
//e:  removeFromHashTable(context->symbolTable, node->personIden);
//    removeFromHashTable(context->symbolTable, node->countIden);
//    return InterpOkay;
//    return InterpOkay;
//}
//
//// interpForFam interprets thr forfam statement looping through all families in the Database.
//// usage: forfam(FAM_V,INT_V) {...}
//// THIS IS BASED ON LIFELINES ASSUMPTIONS AND DOES NOT YET WORK IN DEADENDS.
//InterpType interpForFam (ProgramNode* node, Context* context, PValue* pval)
//{
//////    NODE fam;
//////    static char key[MAXKEYWIDTH];
//////    STRING record;
//////    INTERPTYPE irc;
//////    INT len, count = 0;
//////    INT fcount = 0;
//////    insert_pvtable(stab, inum(node), PINT, (VPTR)count);
//////    while (TRUE) {
//////        printkey(key, 'F', ++count);
//////        if (!(record = retrieve_record(key, &len))) {
//////            if(fcount < num_fams()) continue;
//////            break;
//////        }
//////        if (!(fam = stringToGNodeTree(record))) continue;
//////        fcount++;
//////        insert_pvtable(stab, ielement(node), PFAM,
//////                       (VPTR) fam_to_cacheel(fam));
//////        insert_pvtable(stab, inum(node), PINT, (VPTR)count);
//////        irc = interpret((PNODE) ibody(node), stab, pval);
//////        free_nodes(fam);
//////        stdfree(record);
//////        switch (irc) {
//////            case INTCONTINUE:
//////            case INTOKAY:
//////                continue;
//////            case INTBREAK:
//////                return INTOKAY;
//////            default:
//////                return irc;
//////        }
//////    }
//////    return INTOKAY;
//    return InterpOkay;
//}
//
//// interpretSequenceLoop interprets a script sequence loop.
//// usage: forindiset(SET, INDI_V, ANY_V, INT_V) { }
//// fields: sequenceExpr, pElementIden, pCountIden, pLoopState
//InterpType interpretSequenceLoop(ProgramNode* pnode, Context* context, PValue* pval) {
//    bool eflg = false;
//    InterpType irc;
//    PValue val = evaluate(pnode->sequenceExpr, context, &eflg);
//    if (eflg || val.type != PVSequence) {
//        scriptError(pnode, "the first argument to forindiset must be a set");
//        return InterpError;
//    }
//    Sequence *seq = val.value.uSequence;
//    RecordIndex* index = context->database->recordIndex;
//    FORSEQUENCE(seq, el, ncount) {
//        GNode *indi = keyToPerson(el->root->key, index); // Update person in symbol table.
//        assignValueToSymbol(context->symbolTable, pnode->elementIden, PVALUE(PVPerson, uGNode, indi));
//        PValue pvalue = (PValue) {PVInt, el->value}; // Update person's value in symbol table.
//        assignValueToSymbol(context->symbolTable, pnode->valueIden, pvalue);
//        assignValueToSymbol(context->symbolTable, pnode->countIden, PVALUE(PVInt, uInt, ncount));
//        switch (irc = interpret(pnode->loopState, context, pval)) {
//            case InterpContinue:
//            case InterpOkay: goto h;
//            case InterpBreak: return InterpOkay;
//            default: return irc;
//        }
//    h:    ;
//    }
//    ENDSEQUENCE
//    return InterpOkay;
//}
//// interpTraverse interprets the traverse statement. It adds two entries to the symbol table.
//// Usage: traverse(GNode expr, GNode ident, int ident) {...}.
//// Fields: gnodeExpr, levelIden, gNodeIden.
//#define MAXTRAVERSEDEPTH 100
//InterpType interpTraverse(PNode* traverseNode, Context* context, PValue* returnValue) {
//    ASSERT(traverseNode && context);
//    bool errorFlag = false;
//    GNode* root = evaluateGedcomNode(traverseNode->gnodeExpr, context, &errorFlag); // Root of traverse.
//    if (errorFlag || !root) {
//        scriptError(traverseNode, "the first argument to traverse must be a Gedcom line");
//        return InterpError;
//    }
//    assignValueToSymbol(context->symbolTable, traverseNode->levelIden, PVALUE(PVInt, uInt, 0));
//    assignValueToSymbol(context->symbolTable, traverseNode->gnodeIden, PVALUE(PVGNode, uGNode, root));
//    // Normally getValueOfIden gets values of idens in the SymbolTables. But here we use
//    // searchHashTable to get direct access to the PValues to simplify updating them.
//    PValue* level = ((Symbol*) searchHashTable(context->symbolTable, traverseNode->levelIden))->value;
//    PValue* node = ((Symbol*) searchHashTable(context->symbolTable, traverseNode->gnodeIden))->value;
//    ASSERT(node && level);
//    GNode *snode, *nodeStack[MAXTRAVERSEDEPTH]; // Stack of GNodes.
//    InterpType irc;
//    InterpType returnIrc = InterpOkay;
//
//    int lev = 0;
//    nodeStack[lev] = snode = root; // Init stack.
//    while (true) {
//        node->value.uGNode = snode; // Update symbol table.
//        level->value.uInt = lev;
//        switch (irc = interpret(traverseNode->loopState, context, returnValue)) { // Interpret.
//            case InterpContinue:
//            case InterpOkay: break;
//            case InterpBreak:
//                returnIrc = InterpOkay;
//                goto a;
//            default:
//                returnIrc = irc;
//                goto a;
//        }
//        if (snode->child) { // Traverse child.
//            snode = nodeStack[++lev] = snode->child;
//            continue;
//        }
//        if (snode->sibling) { // Traverse sibling.
//            snode = nodeStack[lev] = snode->sibling;
//            continue;
//        }
//        while (--lev >= 0 && !(nodeStack[lev])->sibling) // Pop
//            ;
//        if (lev < 0) break;
//        snode = nodeStack[lev] = (nodeStack[lev])->sibling;
//    }
//a:  removeFromHashTable(context->symbolTable, traverseNode->levelIden); // Remove loop idens.
//    removeFromHashTable(context->symbolTable, traverseNode->gnodeIden);
//    return returnIrc;
//}
