### DeadEnds 'Built-in' Cheat Sheet

###### Miscellaneous

```
d(int)           -> string      Integer as string
nl()             -> string      Newline character
qt()             -> string      Ascii double quote
set(ident, any)  -> null        Assign value of expression to variable
ord(int)         -> string      Return ordinal form of a number as string
card(int)        -> string      Cardinal form of a number as string
roman(int)       -> string      Roman form of a number as string
null()           -> null        Null program value
```
###### Arithmetic
```
add(int|double|string, int|double|string)  -> int|double|string
sub(int|double, int|double)                -> int|double
mul(int|double, int|double)                -> int|double
div(int|double, int|double)                -> int|double
mod(int, int)                              -> int
neg(int|double)                            -> int|double
```
###### Increment and Decrement
```
incr(ident) -> int           Increment integer variable
decr(ident) -> int           Decrement integer variable
```
###### Comparison
```
eq(any, any) -> bool        True if values are equal
ne(any, any) -> bool        True if values are not equal
lt(any, any) -> bool|null   True if first arg is less than second
le(any, any) -> bool|null   True if first arg is less or equal second
gt(any, any) -> bool|null   True if first arg is greater than second
ge(any, any) -> bool|null   True if first arg is greater than or equal second
```
###### Logical
```
and(any [, any]*) -> bool        And up to 32 boolean values
or (any [, any]*) -> bool        Or up to 32 boolean values
not(any)          -> bool        Not a boolean value
```
###### Strings
```
upper (string) -> string          Uppercase a string
lower (string) -> string          Lowercase a string
capitalize (string) -> string     Capitalize a string
words (string)  -> list<string>   Extract words from a string
tokens (string) -> list<string>   Extract tokens from a string

```
###### Nodes
```
key (person|family|node|null) -> string|null   Node key
tag (node|null) -> string|null                 Node tag
val (node|null) -> string|null                 Node value
lev (node|null) -> int|null                    Node level
kid (node|null) -> node|null                   First kid
sib (node|null) -> node|null                   Next sib
kids (node|null) -> list<node>                 All kids
sibs (node|null) -> list<node>                 All sibs
dad (node|null) -> node|null                   Parent
root (person|family|null) -> node|null         Root node
kidwithtag (node|null, string) -> node|null    First kid with tag
kidswithtag (node|null, string) -> list<node>  All kids with tag
```
###### Person
```
person (string)        -> person|null     Look up person by key
name (person|null)     -> string|null     Standard form of person's name
sex(person|null)       -> string|null     Sex (M, F, U) of person
fullname (person|null, bool, bool, int)
                       -> string|null     Formatted name of person
givens (person|null)   -> list<string>    Given names of as list
surname (person|null)  -> string|null     Primary surname
trimname (person|null, int) -> string     Name trimmed in length
title(person|null)     -> string|null     First title
birth (person|null)    -> gnode|null      First birth event
death (person|null)    -> gnode|null      First death event
baptism (person|null)  -> gnode|null      First baptism event
burial (person|null)   -> gnode|null      First burial event
father (person|null)   -> person|null     First father
mother (person|null)   -> person|null     First mother
siblings (person|null) -> list<person>    Siblings
nextsib (person|null)  -> person|null     Next (younger) sib
prevsib (person|null)  -> person|null     Prev (older) sib
families (person|null) -> list<family>    Families person is spouse in
allpersons ()          -> list<person>    All persons in database
male (person)          -> bool|null       Whether person is male
female (person)        -> bool|null       Whether person is female
```
###### Family
```
marriage(family)  -> node|null        First marriage event
divorce(family)   -> node|null        First divorce event
allfamilies()     -> list<family>     All families in database
```
###### Person and Family
```
husband (person|family|null)   -> person|null    First husband
wife (person|family|null)      -> person|null    First wife
husbands (person|family|null)  -> list<person>   All husbands
wives (person|family|null)     -> list<person>   All wives
children (person|family|null)  -> list<person>   Children
nchildren (person|family|null) -> int|null       Number of children
spouses (person|family|null)   -> list<person>   Spouses
nspouses(person|family|null)   -> int|null       Number of spouses
parents (person|family|null)   -> list<person>   Parents
```
###### Events
```
date (node) -> string|null    Value of first DATE node that is a child of node
place(node) -> string|null    Value of first PLAC node that is a child of node
```
###### Generic
```
empty (list|table|set|string)    -> bool     Whether the object is empty
length (list|table|set|string)   -> int      Length of the object
clear (list|table|set)           -> null     Empty the structure
subscript (list|set|string, int) -> any      Return 1-indexed element
```
###### List
```
list ()             -> list       Create empty list
append (list, any)  -> null       Append value to the end of a list
prepend (list, any) -> null       Prepend value to the start of a list
push (list, any)    -> null       Push value onto list used as stack.
pop (list)          -> any        Pop value from a list used as stack.
enqueue (list, any) -> null       Enqueue value onto list used as queue
dequeue (list)      -> any        Dequeue value from list used as queue
pair (any, any)     -> list<any>  Create pair from two values
first (list(any))   -> any        Return first value of pair
second (list(any))  -> any        Return second value of pair
removefirst (list)  -> any        Remove and return first element of list
removelast (list)   -> any        Remove and return last element of list
```
###### Table
```
table()                    -> table         Create a table
insert(table, string, any) -> table         Add a (key, value) pair to the table
lookup(table, string)      -> any|null      Lookup a value in a table
```
###### PersonSet
```
personset ()                   -> set   Create person set
addtoset (set, person[, any])  -> null  Add person to set
removefromset (set, person)    -> null  Remove person from set
union (set, set)               -> set   Union of two set
intersect (set, set)           -> set   Intersection of two sets
difference (set, set)          -> set   Difference of two sets
parentset (set)                -> set   Parent set of set
childset (set)                 -> set   Children set of set
spouseset (set)                -> set   Spouse set of set
siblingset (set)               -> set   Sibling set of set
ancestorset (set)              -> set   Ancestor set of set
descendentset (set)            -> set   Descendant set of set
namesort (set)                 -> null  Sort set by name
keysort (set)                  -> null  Sort set by key
```
###### Meta
```
showframe()  -> string           Show current frame
showstack()  -> string           Show full run time stack
valueof(any) -> string           Eval arg and show its type and value
```
###### User Interface
```
getperson(string)  -> person | null    Request user to identify a person
getinteger(string) -> int | null       Request user to enter an int
getstring(string)  -> string | null    Request user to enter a string
```
###### Information Extraction
```
extractname(node, list, int, int) -> null  Extract a GedcomName
extractdate ----------TBD
extractplace ---------TBD
```
