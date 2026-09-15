## DeadEnds Programming Language

DeadEnds has a programming language for writing *genealogical programs*. Originally intended for report generation, it soon became clear that it was a general-purpose programming language with special features for genealogy. Features that make it particularly useful for genealogy are its full support for the collection types needed for genealogical operations (e.g., lists, tables, and person sets), and its rich set of built-in library functions devoted to genealogy. In addition to standard data types, the language has genealogical data types such as persons, families, and Gedcom tree nodes; they can be operated on directly rather than being represented indirectly.

DeadEnds programs are stored in files. You can edit them with a text editor, but the DeadEnds application has an IDE page that makes it simple to create, edit, compile, debug, and run programs.

#### Procedures and Functions

A DeadEnds program is a sequence of *top level* structures that include *proc* and *func* definitions. A proc has format:

​    proc *name* ( *params* ) { *statements* }

where *name* is the name of the proc, *params* is an optional list of parameters (identifiers) separated by commas, and *statements* is the list of statements making up the body. Every program must have a proc named *main* --- program execution begins at the first statement in that proc. Procs may call other procs and funcs to any depth.

Procs are called with *call* statements.

A func has format:

​    func *name* ( *params* ) { *statements* }

where *name*, *params* and *statements* are defined as in procs. Funcs may call other procs and funcs. A func differs from a proc by returning a value to the proc or func that calls it. Values are returned by the *return* statement. Recursive funcs and procs are allowed and are often good choices for genealogical algorithms. Funcs are called by invoking them in expressions.

#### Comments

DeadEnds comments begin with `/*` and end with ```*/```.

#### Include Statements

The *include* statement is used at the top level, outside the bodies of any proc or func. Its format is:

​    include(*filename*)

where *filename* is a string. The contents of the file are read and and made part of the program. An included file may include other files, to any depth. This feature is useful for common routines and *user libraries*.

#### Global Statements

The global statement is also used at the top level. Its format is:

​    global(*identifier*)

It declares the identifier to be a variable with global scope. Global variables are accessible from any point in a program unless the name is *hidden* by a local parameter or variable. A global variable provides a way for all activations of a recursive function to access the same variable. Included files can also contain global statements.

#### Expression Statements

The DeadEnds language has several kinds statements. The simplest is the *expression* statement, an expression that is not part of any other statement or expression.

When an expression statement is evaluated, if its value is a string it is written directly to the output stream. This is part of DeadEnds's legacy. The original language was intended as a report generator where it was natural to have string expressions written directly to output. This behavior is convenient and was kept as the language became more general. As a consequence the language does not have print statements.

For example, the expression *name(person)*, where *person* is a person, returns the person’s name as a string, so it is written to the output stream. On the other hand, the expression *set(n, nspouses(person))* assigns the identifier *n* the number of spouses that the *person* has; *set* returns *null*, so nothing is written.

#### If and While Statements

The language includes *if* and *while* statements with formats:

​    if ([*varb*,] *expr*) { *statements* } [ elsif ([*varb*], *expr*) { *statements* } ]\* [ else { *statements* } ]

​    while ([*varb*,] *expr* ) { *statements* }

Square brackets means optional, and the asterisk means zero or more. An *if* statement is run by evaluating the conditional expression before the *if* clause statements. If true the *if* clause is run, and the rest of the *if* statement is ignored. If the value is false, and there are *elsif* clauses, their conditionals are evaluated until the one returns true, and its clause is run. If no conditional is true, and if the *if* statement ends with an *else* clause, that clause is executed.

There are two forms of conditional expression. If it is a single expression, it is just evaluated. If it is a identifier followed by an expression, the expression is evaluated and assigned to the identifier.

The *while* statement provides a looping mechanism. The conditional is evaluated, and if true, the body of the loop is run. After each iteration the expression is reevaluated; as long as it remains true, the loop is repeated.

#### Call Statement

The call statement provides procedure calls. Its format is:

​    call *name* ( *args* )

 where *name* must match one of the procedures defined in the program. *args* is a list of expressions separated by commas. Recursion is allowed. When a call is run, the args are evaluated and used to initialize the proc's params. The proc is then run. When it completes, execution resumes in the caller.

#### Foreach Statement

The LifeLines language had seperate iterators for different data structures and data sources. DeadEnds consolidates those iterators into a single *foreach* statement. It has the format:

​    foreach (*source, element[, value], index*) { *statements* }

The statement iterates over each element in the *source*. *Element*, *value*, and *index* are identifiers. During each iteration they are assigned to the current element, its value (in the case of tables and person sets), and its index relative to one. Value is optional. The *foreach* statement can iterate over lists, tables, pesonsets, all persons or families in the database, all nodes at and below a node, and all characters in a string. Here are the forms the statement can take.



| Source | Element      | Value            |
| --------- | ------------ | ---------------- |
| list expression | list element | —                |
| table expression | key (string) | value (any) |
| personset expression | person       | value (any) |
| allpersons() |person|—|
| allfamilies() |family|—|
|traverse(node expression)|Gedcom node|—|
|string expression|character|—|

#### Continue, Break, and Return Statements

The language also has these statements:

​    continue()

​    break()

​    return([*expr*])

The *continue* statement jumps to the bottom of the current loop, but does not leave the loop.

The *break* statement breaks out of the most closely nested loop.

The *return* statement returns from the current procedure or function. Procedures can have *return* statements without expressions; functions have *return* statements with expressions.

#### Expressions

There are three forms of expressions: *literals*, *identifiers* (variables), and *function calls*. Function calls may contain other expressions as arguments, allowing expressions to be nested to arbitrary depth.

A *literal* is an integer constant, floating-point number, or Unicode string enclosed in quotes. A literal evaluates to its value.

An *identifier* names a location in a local or global symbol table. Values are assigned to identifiers during execution, and an identifier evaluates to the last value assigned to it. Identifiers do not have fixed types; however, every value has a known type.

A *function call* consists of a function name followed by a comma-separated list of expressions enclosed in parentheses. DeadEnds provides a large library of built-in functions. User-defined functions are called with the same syntax.

Because the arguments of a function call are themselves expressions, function calls can be nested:

    add(mul(a, 2), sub(b, 1))

Here `a`, `2`, `b`, and `1` are expressions, `mul(a, 2)` and `sub(b, 1)` are expressions, and the entire call to `add` is also an expression. This expression is equivalent to a*2 + (b-1).

#### Built-in Functions

There is a long list of built-in functions, and it will grow for some time. The first subsection below describes the value types used in DeadEnds programs; these are the types of variables, function parameters and function return values. In the remaining sections the built-in functions are separated into logical categories and described.

##### Program Value Types

The DeadEnds language is *typed*: every value has a known type. One of the built-in functions is *valueof(expr)*, where *expr* is any expression. *Valueof* is a *meta* function that evaluates the expression and writes its value and type to the output stream; this is very useful when developing and debugging programs.

Here are the program value types:

​    null

​    integer

​    double

​    boolean

​    string (Unicode string)

​    gnode (Gedcom node)

​    person (Person record)

​    family (Family record)

​    source (Source record)

​    list (List of program values)

​    table (Map from strings to program values)

​    personset (Set of persons with associated types)

​    pair --- Pair of values

A *list* is a list of program values. The values can have any type and do not have to be the same.

A *table* is a hash table that maps strings to program values. The values can have any type and do not have to be the same.

A *personset* is a set of persons; each person may have an *associated value*. There are many built-in functions for personsets: they are a useful genealogical data structure. Associated values can have any type. One of the example programs below finds the Henry numbers for all descendents of a person. The Henry numbers are implemented as lists of integers which are the associated values of the elements of the personset of descendents.

Each built-in function summary shows its argument and return types. In three cases (*set*, *incr*, *decr*) an argument to a built-in function must be an identifier. These are the only examples where a built-in argument is not evaluated (the identifer is being used as an *L-value*).

Built-in arguments are usually restricted to one or more of the program types. These are checked as the program runs, and incorrect types cause the program to quit with a runtime error.

The *set* statement is the *assignment* statement; the expression is evaluated, and its value is assigned to the variable. The *set* statement is really *just* a top level expression, one of many built-in functions in the DeadEnds library, but because it serves as the language's assignment statement, it deserves this special mention.