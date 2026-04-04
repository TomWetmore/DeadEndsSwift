//
//  Lexer.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 3 April 2026.
//  Last changed on 3 April 2026.
//

import Foundation

/// Lexer for the DeadEnds programming language.
struct Lexer {
    let source: String
    var index: String.Index
    var line: Int = 1
}

extension Lexer {
//    func getToken() -> Token {
//        while let token = nextToken() {
//            return token
//        }
//        return Token(kind: .eof, line: line)
//    }

    /// Peek at the next character in the program.
    func peek() -> Character? {
        guard index < source.endIndex else { return nil }
        return source[index]
    }

    /// Advance one character in the program.
    @discardableResult mutating func advance() -> Character? {
        guard let c = peek() else { return nil }
        index = source.index(after: index)
        if c.isNewline { line += 1 }
        return c
    }

    /// Backup one character in the program; currently needed.
    mutating func backup() {
        index = source.index(before: index)
        if peek() == "\n" { line -= 1 }
    }

    mutating func skipWhiteSpaceAndComments() {
        while true {
            // Skip ordinary whitespace.
            while let c = peek(), c.isWhitespace {
                advance()
            }

            // If we're not looking at '/', we're done.
            guard peek() == "/" else { return }

            // Consume the '/' and see whether this is really a comment.
            advance()

            if peek() != "*" {
                // Not a comment. Put the '/' back and stop.
                backup()
                return
            }

            // Consume the '*'; now we are inside a /* ... */ comment.
            advance()

            // Scan until we find the closing */
            while let c = advance() {
                if c == "*" && peek() == "/" {
                    advance()   // consume the '/'
                    break
                }
            }

            // If advance() returned nil, we hit end-of-input.
            // In either case, loop back and skip any following whitespace/comments.
            if peek() == nil { return }
        }
    }

    /// Lex an identifier or reserved word.
    /// Assumes the current character is the first letter of the token.
    mutating func lexIdentifierOrKeyword() -> Token {
        let startLine = line
        var text = ""

        while let c = peek(), c.isLetter || c.isNumber || c == "_" {
            text.append(advance()!)
        }

        let kind = keywordKind(for: text) ?? .identifier(text)
        return Token(kind: kind, line: startLine)
    }

}  // End of extension with lexing functions.

        //        while (true) {
        //            while ((c = inchar()) != '*' && c != 0) ;  // Read to a *.
        //            if (c == 0) return 0;
        //            while ((c = inchar()) == '*') ;  // Allow multiple *'s.
        //            if (c == '/') break;
        //            if (c == 0) return 0;
        //            // Anything else continues the comment finding loop.
        //        }

enum TokenKind: Equatable {
    case identifier(String)
    case intConst(Int)
    case floatConst(Double)
    case stringConst(String)

    case proc
    case funcTok
    case children
    case spouses
    case ifTok
    case elseTok
    case elsif
    case families
    case whileTok
    case call
    case forindiset
    case forindi
    case fornotes
    case traverse
    case fornodes
    case forlist
    case forfam
    case forsour
    case foreven
    case forothr
    case breakTok
    case continueTok
    case returnTok
    case fathers
    case mothers
    case parents

    case lParen
    case rParen
    case lBrace
    case rBrace
    case comma
    case slash
    case minus
    case period

    case eof
}

struct Token: Equatable {
    let kind: TokenKind
    let line: Int
}

func keywordKind(for word: String) -> TokenKind? {
    switch word {
    case "break": return .breakTok
    case "call": return .call
    case "children": return .children
    case "continue": return .continueTok
    case "else": return .elseTok
    case "elsif": return .elsif
    case "families": return .families
    case "fathers": return .fathers
    case "foreven": return .foreven
    case "forfam": return .forfam
    case "forindiset": return .forindiset
    case "forindi": return .forindi
    case "forlist": return .forlist
    case "fornodes": return .fornodes
    case "fornotes": return .fornotes
    case "forothr": return .forothr
    case "forsour": return .forsour
    case "func": return .funcTok
    case "if": return .ifTok
    case "mothers": return .mothers
    case "Parents": return .parents
    case "proc": return .proc
    case "return": return .returnTok
    case "spouses": return .spouses
    case "traverse": return .traverse
    case "while": return .whileTok
    default: return nil
    }
}

//static int inchar(void);      // Get the next character from the current file.
//static void unreadchar(int c);  // Unread a character to the current file.
//static bool reserved(String word, int *pval);  // Check whether an identifier is reserved.
//extern int curLine;; // Current line number in file being parsed.
//extern SemanticValue yylval;  // Defined in y.tab.c
//int yylex(void) { return getToken(); }
//
//// getTokenLow is the real lexer.
//static int getTokenLow(void) {
//    int retval;
//    CharType t; // Type of current character.
//    int c; // Current character.
//    static char tokbuf[512]; // Buffer where tokens accumulate.
//
//    char* p = tokbuf; // Pointer to current point in tokbuf.
//    // Get by white space, including comments.
//    while (true) {
//        while ((t = characterType(c = inchar())) == White)
//            ;
//        if (c != '/') break; // Passed any whitespace not followed by a comment.
//        // Handle comment if there.
//        if ((c = inchar()) != '*') {
//            // Not in comment. Unread last character and return /.
//            unreadchar(c);
//            return '/';
//        }
//        // Found the start of a comment. Read to its end.
//        while (true) {
//            while ((c = inchar()) != '*' && c != 0) ;  // Read to a *.
//            if (c == 0) return 0;
//            while ((c = inchar()) == '*') ;  // Allow multiple *'s.
//            if (c == '/') break;
//            if (c == 0) return 0;
//            // Anything else continues the comment finding loop.
//        }
//    }
//
//    // Got by any white space and/or comments. Now at the first character of a token.
//    if (t == Letter) {
//        p = (String) tokbuf;
//        while (t == Letter || t == Digit || c == '_') {
//            *p++ = c;
//            t = characterType(c = inchar());
//        }
//        *p = 0;
//        unreadchar(c);
//        //printf("in lexer.c -- IDEN is %s\n", tokbuf);
//        yylval.string = strsave((String) tokbuf);  // TODO: RESERVED WORDS GETTING IN THERE TOO
//        // See if the IDEN is a reserved word.
//        if (reserved((String) tokbuf, &retval)) return retval;
//        return IDEN;
//    }
//
//    // Handle numbers. They can be positive or negative. They can be integers or floating point.
//    if (c == '-' || t == Digit || c == '.') {
//        bool whole = false;
//        bool frac = false;
//        int mul = 1;
//        if (c == '-') {  // Hyphen could be a hypnen or a minus sign in front of a number.
//            t = characterType(c = inchar());  // Read the next character to find out.
//            if (c != '.' && t != Digit) {
//                unreadchar(c);
//                return '-';
//            }
//            mul = -1;
//        }
//        int ivalue = 0;
//        while (t == Digit) {
//            whole = true;
//            ivalue = ivalue*10 + c - '0';  // Accumulate the integer part of the number.
//            t = characterType(c = inchar());
//        }
//
//        // If the next character is not Period an integer was read.
//        if (c != '.') {
//            unreadchar(c);
//            ivalue *= mul;
//            yylval.integer = ivalue;
//            return ICONS;
//        }
//
//        // Just read . at end of integer. Read next character to see what's up.
//        t = characterType(c = inchar());
//        float fvalue = 0.0;
//        float fdiv = 1.0;
//        while (t == Digit) {
//            frac = true;
//            fvalue = fvalue*10 + c - '0';
//            fdiv *= 10;
//            t = characterType(c = inchar());
//        }
//
//        // Unread character after last digit.
//        unreadchar(c);
//        if (!whole && !frac) {  // Is this possible.
//            unreadchar(c);
//            if (mul == -1) {
//                unreadchar('.');
//                return '-';
//            } else
//                return '.';
//        }
//        yylval.floating = mul*(ivalue + fvalue/fdiv);
//        return FCONS;
//    }
//
//    // Handle string constants.
//    if (c == '"') {
//        p = tokbuf;
//        while (true) {
//            c = inchar();
//            if (c == 0 || c == '"') {
//                *p = 0;
//                yylval.string = strsave(tokbuf);
//                return SCONS;
//            }
//            if (c == '\\') {
//                // Escape sequence
//                c = inchar();
//                switch (c) {
//                    case 'n': *p++ = '\n'; break;
//                    case 't': *p++ = '\t'; break;
//                    case 'v': *p++ = '\v'; break;
//                    case 'r': *p++ = '\r'; break;
//                    case 'b': *p++ = '\b'; break;
//                    case 'f': *p++ = '\f'; break;
//                    case '"': *p++ = '"'; break;
//                    case '\\': *p++ = '\\'; break;
//                    case 0:
//                        *p = 0;
//                        yylval.string = strsave(tokbuf);
//                        return SCONS;
//                    default:
//                        *p++ = c; break;
//                }
//            } else {
//                // Normal character
//                *p++ = c;
//            }
//        }
//    }
//    if (c == 0) return 0;
//    return c;
//}
//
//// inchar gets the next character from the Lexer.
//static int inchar(void) {
//    int c = getc(currentFile);
//    if (c == '\n') curLine++;
//    if (debugging) printf("+: '%c'\n", c);
//    return c == EOF ? 0 : c;
//}
//
//// unreadchar returns a character to the lexer.
//static void unreadchar(int c) {
//    if (c == 0) return;
//    if (debugging) printf("-: '%c'\n", c);
//    ungetc(c, currentFile);
//    if (c == '\n') curLine--;
//}
//
//// rwordtable is the reserved word table.
//static struct {
//    char* rword;
//    int val;
//} rwordtable[] = {
//    { "break",    BREAK },
//    { "call",     CALL },
//    { "children",  CHILDREN },
//    { "continue",  CONTINUE },
//    { "else",     ELSE },
//    { "elsif",    ELSIF },
//    { "families", FAMILIES },
//    { "fathers",  FATHERS },
//    { "foreven",  FOREVEN },
//    { "forfam",   FORFAM },
//    { "forindiset",  FORINDISET },
//    { "forindi",  FORINDI },
//    { "forlist",  FORLIST_TOK },
//    { "fornodes", FORNODES },
//    { "fornotes", FORNOTES },
//    { "forothr",  FOROTHR },
//    { "forsour",  FORSOUR },
//    { "func",     FUNC_TOK },
//    { "if",       IF },
//    { "mothers",  MOTHERS },
//    { "Parents",  PARENTS },
//    { "proc",     PROC },
//    { "return",   RETURN },
//    { "spouses",  SPOUSES },
//    { "traverse", TRAVERSE },
//    { "while",    WHILE },
//};
//
//static const int nrwords = ARRAYSIZE(rwordtable);
//
//// reserved checks if a String is a reserved word.
//static bool reserved (String word, int* pval) {
//    for (int i = 0; i < nrwords; i++) {
//        if (eqstr(word, rwordtable[i].rword)) {
//            *pval = rwordtable[i].val;
//            return true;
//        }
//    }
//    return false;
//}
//
