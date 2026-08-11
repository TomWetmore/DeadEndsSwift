### DeadEnds Programming Feature



Intended to document the DeadEnds Programming Language.

##### Parsing and Interpreting

The feature is broken into two software components: *parsing* and *interpreting*.

The parsing component uses Point-Free's *Parsing package*. The result of parsing is a Swift structure that holds an immutable representation of the program.

Here is an attempt to describe the language through its Swift structure

```
ParsedProgram: [ParsedDefn]
ParsedDefn: ParsedProcDefn | ParsedFuncDefn | ParsedGlobalDefn | ParsedIncludeDefn
ParsedProcDefn: String [String] [ParsedStatement]
ParsedFuncDefn: String [String] [ParsedStatement]
ParsedGlobalDefn: String
ParsedIncludeDefn: String
ParsedStatement: ParsedCallStatement | ParsedWhileStmt | ParsedIfStmt | ParsedReturnStmt   | ParsedBreakStmt | ParsedContinueStmt | ParsedForEachStmt | ParsedExpr
ParsedCallStatement: String [ParsedExpr]
ParsedWhileStatement: ParsedCondition [ParsedStatement]
ParsedIfStatement: ParsedCondition [ParsedStatement][ParsedElseIf][ParsedStatement]?
ParsedElseIf: ParsedCondition [ParsedStatement]
ParsedReturnStmt: [ParsedExpr]
ParsedBreakStmt: nil
ParsedContinueStatement: nil
ParsedForEachStmt: ParsedExpr String String? String [ParsedStatement]
ParsedCondition: ParsedExpr | String ParsedExpr
ParsedExpr: Identifier | IntegerConstant | DoubleConstant | stringConstant | functionCall 
functionCall: String [ParsedExpr]
```

#### Built-Ins

This section describes the built-in functions of the programming language.

The arguments to the built-in functions are ParsedExprs. These are tree structures created when a program is parsed. They are static and persistent and hold argument expressions as found in the source. When programs are interpreted the args are evaluated in the current context. They evaluate to run-time values. Program values are transient objects that disappear when its value is used.

In a few cases an identifier argument is needed for its name not its value. In these cases the argument is not evaluated. A good example is the assignment built-in, "set(identifier, any)". It evaluates the second argument which can be any ParsedExpr, and then assigns that value to the identifier in the symbol table. If the variable is in the symbol table its value is changed. If the variable is not in the symbol table it is added with the value.

In most cases, however, ParsedExpr identifiers are the names of variables whose values are needed by the evaluation. The identifier is be evaluated like any other expresssion, so its value taken from the variable in the symbol table.

The DeadEnds language is strongly typed. Every ProgramValue has an explicit type, and the type is kept as part of the value. See the "valueof()" built-in -- It can be used to inspect the type and value of any ProgramValue, very useful during debugging.

The types and their associated values are:

```
null
integer(Int)
double(Double)
boolean(Bool)
string(String)
gnode(GedcomNode)
person(Person)
family(Family)
source(Source)
list(List)
table(ProgramTable)
personset(PersonSet<any>)
traverse(GedcomNode)
allPersons
allFamilies
```

The type `any` is used in the tables below. There is no `any` type; it indicates that an arg or return type can be of any type.

Identifiers (variables in symbol tables) are not strongly typed. An identifier's type is that of the last value assigned to it.

=========================================================

Null Forwarding and Returning Empty Lists.

Many built-ins are null-forwarding. Null fowarding happens when a built-in returns a null value instead of the normal type expected. This can happen in two ways.

First, if the built-in cannot find the information requested it returns null. This is how null forwarding starts. Second, if a null is passed into a built-in, the built-in may pass (forward) the null along

 A good example is the `father` function defined as `father(person|null) -> person|null`. The function normally takes a person and returns the person's father. If the person does not have a father then the function returns null. Also, if null is passed in to `father`, then it returns null. This allows built-ins to be chained together without null-checking code.

Consider this program that shows both types of null forwarding.

```proc main () {
    set(p, getperson("enter a person"))
    "1 " name(p) nl()
    "2 " name(father(p)) nl()
    "3 " name(father(father(p))) nl()
    "4 " name(father(father(father(p)))) nl()
    "5 " name(father(father(father(father(p))))) nl()
    "6 " name(father(father(father(father(father(p)))))) nl()
}
```

This asks for a person from the database and then tries to print that person's name and the names of the next five males in the person's paternal line. If I run this on my wife the output is:

```
1 Luann Frances Grenda
2 Anthony Grenda
3 Jan Grenda
4 Frank Grenda
5
6
```

Her paternal great great grandfather and beyond are not known. On the fifth call to `name`, `father`  is called on Frank Grenda, but it returns null because Frank's father is not in the database. On the sixth call `father` is called with a null argument and returns null. Null forwarding is almost always the right thing to do.

Some built-ins return lists. For example, `children(person|family) -> list(person)` can be applied to a person or family and returns the children of the entity. If the person or family exists but has no children, `children` returns an empty list. If the argument itself is null, it also returns an empty list. Returning an empty list is a form of null forwarding for sequence-valued built-ins. The alternative is to return null, but empty lists are more useful because they work naturally with `foreach`, `length`, and other list operations.

###### Miscellaneous

```
d(integer)           -> string      Convert integer to string
nl()                 -> string      Return newline character
set(identifier, any) -> null        Assign value of expression to variable
ord(integer)         -> string      Return ordinal form of a number as string
card(integer)        -> string      Return the cardinal form of a number as string
roman(integer)       -> string      Return the Roman form of a number as string
null()               -> null        Return the null program value
```

`set` is the language's *assignment statement*. Its first arg must be an identifier.

###### Arithmetic

```
add(integer|double|string, integer|double|string) -> integer|double|string
sub(integer|double, integer|double) -> integer|double
mul(integer|double, integer|double) -> integer|double
div(integer|double, integer|double) -> integer|double
mod(integer, integer)               -> integer
neg(integer|double)                 -> integer|double
```
Arg types must match. For example, `sub` must be given two integers or two doubles, not one of each. This should be rethought because there are no current built-ins to coerce values.

In LifeLines `add` and `mul` could have two to 32 arguments (like `add` and `or`  allow). `add` and `mul` should be changed to use the LifeLines approach.

###### Increment and Decrement

```
incr(identifier) -> integer -- identifier must have an integer value
decr(identifier) -> integer -- identifier must have an integer value
```
The arg must be an identifier that is the name of an integer variable in the symbol table. Its value is incremented or decremented in the symbol table.

###### Comparison
```
eq(any, any) -> bool        Returns whether two values are equal
ne(any, any) -> bool        Returns whether two values are not equal
lt(any, any) -> bool|null   Returns whether the first arg is less than the second
le(any, any) -> bool|null   Returns whether the first arg is less or equal the second.
gt(any, any) -> bool|null   Returns whether the first arg is greater than the second.
ge(any, any) -> bool|null   Returns whether the first arg is greater than or equal the second.
```
`eq` and `ne` use an internal `==` operator. It is only as good as that operator.

`lt`, `le`, `gt`, and `ge` use an internal compare operator. It returns `null` for non-simple comparisons. This is an issue for the future.

###### Logical Operators
```
and(any [, any]*) -> bool     Return result of and'ing up to 32 boolean values
or (any [, any]*) -> bool     Return result of or'ing up to 32 boolean values
not(any)          -> bool     Return the not of a boolean value
```
`and` and `or` can have 1 to 32 arguments. Short circuiting is used, so args that do not need to be evaluated are not. The args can be `any` because there is a `toBool` function that coerces any value to boolean. However the `toBool` function is primitive.`not` also can have  `any` argument because it uses the same `toBool` function.

###### GedcomNode properties and operations
```
key (person|family|node|null) -> string|null   Node key
tag (node|null) -> string|null                 Node tag
val (node|null) -> string|null                 Node value
lev (node|null) -> integer|null                Node level
kid (node|null) -> node|null                   First kid
sib (node|null) -> node|null                   Next sib
kids (node|null) -> list(node)                 All kids
sibs (node|null) -> list(node)                 All sibs
dad (node|null) -> node|null                   Parent
root (person|family|null) -> node|null         Root node
kidwithtag (node|null, string) -> node|null    First kid with tag
kidswithtag (node|null, string) -> list(node)  All kids with tag
```
Most forward null directly. `kids`, `sibs`, `kidswithtag` return empty lists as a form of null forwarding.

###### Person Operations
```
person (string)       -> person|null        Look up person in database by key
name (person|null)    -> string|null        Standard form of person's name
fullname (person|null, bool, bool, integer)
                       -> string|null       Formatted name of person
givens (person|null)   -> list(string)      Given names of person as a list
surname (person|null)  -> string|null       Primary surname
birth (person|null)    -> gnode|null        Primary birth event
death (person|null)    -> gnode|null        Primary death event
father (person|null)   -> person|null       Primary father
mother (person|null)   -> person|null       Primary mother
families (person|null) -> list(family)      Families person is spouse in
allpersons ()          -> list(person)      All persons in database
male (person)          -> bool|null         Whether person is male
female (person)        -> bool|null         Whether person is female

allfamilies()          -> list(family)      All families in database
```
These are all null forwarding.

###### Person and Family Operations
```
husband (person|family)  -> person|null    Primary husband
wife (person|family)     -> person|null    Primary wife
husbands (person|family) -> list(person)   All husbands
wives (person|family)    -> list(person)   All wives
children (person|family) -> list(person)   Children
spouses (person|family)  -> list(person)   Spouses
parents (person|family)  -> list(person)   Parents
siblings (person)        -> list(person)   Siblings
```
These are all null or empty list forwarding.
###### Operations on Events
```
date (node) -> string|null    Value of first DATE node that is a child of node
place(node) -> string|null    Value of first PLAC node that is a child of node
```
###### Generic List, Table, PersonSet and String Operations
```
empty (list|table|personset|string)        -> bool      Whether the object is empty
length (list|table|personset|string)       -> integer   Length of the object
clear (list|table|personset)               -> null      Empty the structure
subscript (list|personset|string, integer) -> any       Return 1-indexed element
```
            "traverse":  Builtin(min: 1, max: 1) { try await self.bltinNodes($0)},

###### List Operations

```
list ()             -> list       Create empty list
append (list, any)  -> null       Append value to the end of a list
prepend (list, any) -> null       Prepend value to the start of a list
push (list, any)    -> null       Push value onto list used as stack.
pop (list)          -> any        Pop value from a list used as stack.
enqueue (list, any) -> null       Enqueue value onto list used as queue
dequeue (list)      -> any        Dequeue value from list used as queue
pair (any, any)     -> list(any)  Create pair from two values
first (list(any))   -> any        Return first value of pair
second (list(any))  -> any        Return second value of pair
removefirst (list)  -> any        Remove and return first element of list
removelast (list)   -> any        Remove and return last element of list
```
`append`, `prepend`, `push`, and `enqueue` return `null`. They cause side-effects. `pop`, `dequeue`, `removefirst` and `removelast` remove and return values from a list. They return `null` if the list is empty.

###### Table Operations

```
table()                    -> table         Create a table
insert(table, string, any) -> table         Add a (key, value) pair to the table
lookup(table, string)      -> any|null      Lookup a value in a table
```
###### PersonSet Operations
```
personset ()                          -> personset   Create person set
addtoset (personset, person [, any]) -> null         Add person to set
removefromset (personset, person)    -> null         Remove person from set
union (personset, personset)      -> personset    Union of two set
intersect (personset, personset)  -> personset    Intersection of two sets
difference (personset, personset) -> personset    Difference of two sets
parentset (personset)             -> personset    Parent set of set
childset (peronsset)              -> personset    Children set of set
spouseset (personset)             -> personset    Spouse set of set
siblingset (personset)            -> personset    Sibling set of set
ancestorset (personset)           -> personset    Ancestor set of set
descendentset (personset)         -> personset    Descendant set of set
namesort (personset)              -> null         Sort set by name
keysort (personset)               -> null         Sort set by key
```
All operations are nondestructive; argument sets are not modified.

`parentset`, `childset`, etc., *do not* add their arg sets to their result sets. However, members from arg sets may end up in the result sets if they have the given relationship with another member of the arg set. For example, `set(t, spouseset(s))` does not add the elements of `s` to set `t`. However if an element of `t` is a spouse of someone in `s`, then that member of `s` will be in `t`.

Person set elements may have an optional value. Algorithms and output functions can use these values. The value is assigned when a person is added to a set.

###### Meta Operations

For debugging during development.

```
showframe() -> string           Show the current frame
showstack() -> string           Show the full run time stack
valueof(any) -> string          Evaluate arg and show its type and value
```

###### User Interface

```
getperson(string)  -> person | null    Request user to identify a person
getinteger(string) -> integer | null   Request user to enter an integer
getstring(string)  -> string | null    Request user to enter a string
```
These perform the user interface. The string arguments are prompts shown by the user interface.

###### Information Extraction
```
extractname(gedcomnode, list, integer, integer) -> null  Extract a GedcomName
extractdate ----------TBD
extractplace ---------TBD
```
##### Lists of Lists, Tables of Tables, etc.

Lists and tables are reference values. This simplifies internal operations, and aids arbitrary structuring. For example, a list holds a list of values with no restrictions on their types -- they can be lists or tables.

There is no requirement that elements in a list, values in a table, or the associaterd values in person sets have the same type. Each element has its own known type. Of course, if you go crazy with intersting structures, using structures with mixed types, you will deserve the problems it causes.
