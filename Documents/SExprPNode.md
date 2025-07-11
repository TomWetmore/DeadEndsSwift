###  SExpressions and ProgramNodes

This document is about how DeadEnds handles SExpessions and how it converts SExpressions into the tables and ProgramNodes needed to run DeadEnds programs. Overall outline:

1. There is a C program that reads DeadEnds programs into ProgramNode-based structures, and then writes out those ProgramNode structures as an SExpression. At some point I will add to DeadEnds the ability to call this program in order to generate the SExpressions as a textual file. Presently I run the C program, write the SExpressions to a file, and then run a DeadEnds test program that reads that file into an internal SExpression.

2. The Swift program reads the text SExpressions into internal form using the enum SExpr defined as:

   ```
   public enum SExpr {
     case atom(String) // Atoms (constants, identifiers, strings)
     case list([SExpr]) // Lists (nested expressions)
   }
   ```

   

