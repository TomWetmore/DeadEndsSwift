DeadEnds programs are stored in files. You can edit them with a text editor, but the DeadEnds app has a convenient IDE page that makes it easy to create, edit, compile, debug and run programs.

The programs can be placed in any directory.you edit with a screen editor. Programs are not edited from within

**Procedures and Functions**

A DeadEnds program is made up of sequence of definitions. Two types of definitions define procedures and functions. A procedure has format:

​    proc *name* ( *params* ) { *statements* }

*Name* is the name of the procedure, *params* is an optional list of parameters separated by commas, and *statements* is a list of statements that make up the procedure's body. Program execution begins at the first statement in the procedure named *main*. Procedures may call other procedures and functions.

Procedures are called with the *call* statement described below.When a procedure is called, the statements making up its body are executed.

A function has format:

​    func *name* ( *params* ) { *statements* }

*Name*, *params* and *statements* are defined as in procedures. Functions may call other procedures and functions. When a function is called the statements that make it up are executed. A function differs from a procedure by returning a value to the procedure or function that calls it. Values are returned by the *return* statement, described below. Recursive functions and procedures are allowed. A function is called by invoking it in an expression.

**Comments**

DeadEnds comments begin with `/*` and end with ```*/```.

### Statements

#### Expression Statements

The DeadEnds language has several statements. The simplest is the *expression* statement, which is an expression that is not part of any other statement or expression ("at the top level"). Expressions are defined below. **Important**: When an expression statement is evaluated, if its value is a string it is written to the program output stream. This is DeadEnds legacy. The original language was a report generator, so it was natural for any top level string be written to output. It soon became clear that the language was a general purpose language, but this bit of legacy was retained. It is often convenient.

For example, the expression *name(person)*, where *person* is a person, returns the person’s name as a string so it is written immediately to the output stream. On the other hand, the expression *set(n, nspouses(person))* assigns the variable *n* the number of spouses that person *person* has, but since *set* returns null, nothing is written to output.**Important**: The languge *does not* have an assignment statement. That role is played by the built-in set function.

#### If and While Statements

The language includes *if* statements, *while* statements and procedure call statements,with the following formats:

​    if ([*varb*,] *expr*) { *statements* } [ elsif ([*varb*], *expr*) { *statements* } ]\* [ else { *statements* } ]

​    while ([*varb*,] *expr* ) { *statements* }

​    call *name* ( *args* )

Square brackets means optional, and the asterisk means zero or more. An *if* statement is run by evaluating the conditional expression in the *if* clause. If true the *if* clause is run, and the rest of the *if* statement is ignored. If the value is false, and there is an *elsif* clause following, the conditional in the *elsif* clause is evaluated, and if non-zero, the else clause is run. Conditionals are evaluated until one of them is true, or until there are no more. If no conditional is true, and if the *if* statement ends with an *else* clause, the *else* clause is executed.

There are two forms of conditional expression. If it is a single expression, it is just evaluated. If it is a variable followed by an expression, the expression is evaluated and assigned to the variable.

The *while* statement provides a looping mechanism. The conditional is evaluated, and if true, the body of the loop is run. After each iteration the expression is reevaluated; as long as it remains true, the loop is repeated.

The call statement provides procedure calls. *Name* must match one of the procedures defined in the report program. *Args* is a list of expressions separated by commas. Recursion is allowed. When a call is run, the arguments are evaluated and used to initialize the procedure's parameters. The procedure is then run. When the procedure completes, execution resumes with the first statement after the call.

#### Foreach Statement

The LifeLines language has special iterator statement for iterating different data structures. The DeadEnds version consolidates all those iterators into a single foreach statement. It has the format:

*foreach(structure, element[, value], count) { statements }*

#### Other Statements

The language also has these statements:

​    include(*string*)

​    global(*varb*)

​    set(*varb*, *expr*)

​    continue()

​    break()

​    return([*expr*])

The *include* and *global* statements are used at the top level, outside the scope of any procedure or function. The *include* statement includes the contents of another file into the program. The string names another program file. An included file can include other files, to any depth. This feature is useful for commonly used routines and *user libraries*.

The *global* statement declares a variable to have global scope. Global variables are accessible from any point in a program unless its name is *hidden* by a local parameter or variable. A global variable provides a way for all activations of a recursive function to access the same variable.

The *set* statement is the *assignment* statement; the expression is evaluated, and its value is assigned to the variable. The *set* statement is really *just* a top level expression, one of many built-in functions in the DeadEnds library, but because it serves as the language's assignment statement, it deserves this special mention.

The *continue* statement jumps to the bottom of the current loop, but does not leave the loop.

The *break* statement breaks out of the most closely nested loop.

The *return* statement returns from the current procedure or function. Procedures can have *return* statements without expressions; functions have *return* statements with expressions.

**Expressions**

There are four types of expressions: *literals*, *integers*, *variables* and built-in or user defined *function* *calls*.

A *literal* is any string enclosed in double quotes; its value is itself. An *integer* is any integer constant; its value is itself. A *variable* is a named location in the local or global symbol table that can be assigned different values during program execution. The value of a variable is the last value assigned to it. Variables do not have fixed type. However all values have an explicitly known type.

An identifier followed by comma-separated list of expressions enclosed in parentheses, is either a call to a built-in function or a call to a user-defined *function*. The language has a long list of built-in functions that are listed later.

**Built-in Functions**

There is a long list of built-in functions, and this list will continue to grow for some time. The first subsection below describes the value types used in DeadEnds programs; these are the types of variables, function parameters and function return values. In the remaining sections the built-in functions are separated into logical categories and described.

**Program Value Types**

The DeadEnds language is *strongly typed* -- every value has a specific, known type. One of the built-in functions is *valueof(expr)*. This is a *meta* function. Calling it evaluates the expression and writes its value and type to the output stream -- often all you need to debug a DeadEnds program.

​    null --- Empty type and value

​    integer --- Integer

​    double --- Double

​    boolean --- Boolean

​    string --- Unicode string

​    gnode --- Gedcom node

​    person --- Person record

​    family --- Family record

​    source --- Source record

​    list --- List

​    table --- String to program value map

​    personset --- Person set (with associated type)

​    pair --- Pair of values

  case traverse(GedcomNode)

  case allPersons

  case allFamilies

In the summaries of built-in functions below, each function is shown with its argument types and its return type. The types are from the preceding list. In three cases (set, incr, decr) an argument to a built-in function must be an identifie a variable; when this is so its type is given as *XXX_V*, where *XXX* is one of the types above. The

built-ins do not check the types of their arguments. Variables can hold values of any type, though at

any one time they will hold values of only one type. Note that *EVENT* is a subtype of *NODE*, and

*BOOL* is a subtype of *INT*. Built-ins with type *VOID* actually return null (zero) values.