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

​    if ([*varb*,] *expr*) { *statements* } [ elsif ([*varb*], *expr*) { *statements* } ]  [ else { *statements* } ]

​    while ([*varb*,] *expr* ) { *statements* }

​    call *name* ( *args* )

Square brackets indicate optional parts. An *if* statement is run by evaluating the conditional expression in the *if* clause. If true, the statements in the *if* clause are evaluated, and the rest of the *if* statement, if any, is ignored. If the value is false, and there is an *elsif* clause following, the conditional in the *elsif* clause is evaluated, and if non-zero, the statements in that clause are executed. Conditionals are evaluated until one of them is true, or until there are no more. If no conditional is true, and if the *if* statement ends with an *else* clause, the statements in the *else* clause are executed.

**Important**: There are two forms of conditional expressions. If the conditional is a single expression, it is just evaluated. If the conditional is a variable followed by an expression, the expression is evaluated and its value is assigned to the variable.

The *while* statement provides a looping mechanism. The conditional is evaluated, and if true, the body of the loop is executed. After each iteration the expression is reevaluated; as long as it remains true, the loop is repeated.

The call statement provides procedure calls. *Name* must match one of the procedures defined in the report program. *Args* is a list of argument expressions separated by commas. Recursion is allowed. When a call is run, the arguments are evaluated and used to initialize the procedure's parameters. The procedure is then executed. When the procedure completes, execution resumes with the first item after the call.

The report language also includes the following statement types:

include(*string*)

global(*varb*)

set(*varb*, *expr*)

continue()

break()

return([*expr*])

The *include* statement includes the contents of another file into the current file; its string expression is

the name of another LifeLines program file. It is described in more detail below. The *global* statement

must be used *outside* the scope of any procedure or function; it declares a variable to have global scope.

The *set* statement is the *assignment* statement; the expression is evaluated, and its value is assigned

to the variable. The *continue* statement jumps to the bottom of the current loop, but does not leave the

loop. The *break* statement breaks out of the most closely nested loop. The *return* statement returns from

the current procedure or function. Procedures have *return* statements without expressions; functions

have *return* statements with expressions. None of these statements return a value, so none has a direct

effect on program output.

In addition to these conventional statements, the report generator provides other iterator statements

for looping through genealogical and other types of data. For example, the *children* statement

iterates through the children of a family, the *spouses* statement iterates through the spouses of a

person, and the *families* statement iterates through the families that a person is a spouse or parent in.

These iterators and others are described in more detail later under the appropriate data types.

**Expressions**

There are four types of expressions: *literals*, *integers*, *variables* and built-in or user defined *function*

*calls*.

A *literal* is any string enclosed in double quotes; its value is itself. An *integer* is any integer constant;

its value is itself. A *variable* is a named location that can be assigned different values during program

execution. The value of a variable is the last value assigned to it. Variables do not have fixed type; at

different times in a program, the same variable may be assigned data of completely different types. An

identifier followed by comma-separated list of expressions enclosed in parentheses, is either a call to a

built-in function or a call to a user-defined *function*.

**Include Feature**

The LifeLines programming language provides an *include* feature. Using this feature one LifeLines*LifeLines Reference Manual – 29*

program can refer to other LifeLines programs. This feature is provided by the include statement:

include(*string*)

where *string* is a quoted string that is the name of another LifeLines program file. When an include

statement is encountered, the program that it refers to is read at that point, exactly as if the contents of

included file had been in the body of the original file at that point. This allows you to create LifeLines

program library files that can be used by many programs. Included files may in turn contain include

statements, and so on to any depth. LifeLines will use the *LLPROGRAMS* shell variable, if set, to

search for the include files.

**Built-in Functions**

There is a long list of built-in functions, and this list will continue to grow for some time. The first

subsection below describes the value types used in LifeLines programs; these are the types of variables,

function parameters and function return values. In the remaining sections the built-in functions are

separated into logical categories and described.

**Value Types**

ANY

INT

BOOL

STRING

LIST

TABLE

INDI

FAM

SET

NODE

EVENT

VOID

union of all types

integer (on most systems a 32-bit signed value)

boolean (0 represents *false*; anything else represents *true*)

text string

arbitrary length list of any values

keyed look-up table

person; reference to a GEDCOM *INDI* record

family; reference to a GEDCOM *FAM* record

arbitrary length set of persons

GEDCOM node; reference to a line in a GEDCOM tree/record

event; reference to substructure of nodes in a GEDCOM record

type with no values

In the summaries of built-in functions below, each function is shown with its argument types and its

return type. The types are from the preceding list. Sometimes an argument to a built-in function must be

a variable; when this is so its type is given as *XXX_V*, where *XXX* is one of the types above. The

built-ins do not check the types of their arguments. Variables can hold values of any type, though at

any one time they will hold values of only one type. Note that *EVENT* is a subtype of *NODE*, and

*BOOL* is a subtype of *INT*. Built-ins with type *VOID* actually return null (zero) values.