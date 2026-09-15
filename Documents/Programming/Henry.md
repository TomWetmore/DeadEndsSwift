I'm putting programming project two on hold; I over-estimated the interest they would generate. I will convert them to documents and put them in the programming section of the DeadEnds repository.

But I still want to introduce the third project because it is intersting, and it demonstrates features of the DeadEnds language.

The goal of the project is to show a person and all their desendents as a Henry list. For example, the list starting at my grest(3) grandfather is 359 persons long and begins:

```
1 Daniel Van Cott Wetmore
1 1 Jesse Wetmore
1 2 Daniel Lorenzo Wetmore
1 2 1 Emeline Terentia Wetmore
1 2 1 1 Frank Egbert Manoel Borges
1 2 1 1 1 Alfred Hazard Borges
1 2 1 1 1 1 Alfred Hazard Borges Jr
1 2 1 1 1 1 1 Alana Heady Borges
1 2 1 1 1 1 2 Hedy Alice Borges
1 2 1 1 1 2 Robert Post Borges
1 2 1 1 1 2 1 Bruce Sanz Borges
1 2 1 1 1 2 2 Warren Limantour Borges
1 2 1 1 2 Lucille Ruth Borges
1 2 1 1 2 1 Creighton Borges Kimble
1 2 1 1 2 1 1 Fay Annette Kimble
1 2 1 1 2 1 1 1 Tobi Rebecca Combs Wright
1 2 1 1 2 1 2 Roy Dexter Kimble
```

Each Henry number is unique and is assigned to descendents based on their relationship to person 1. For example, person (1 a b c) is the c'th child of the b'th child of the a'th child of person 1.

Below is the full program. The main proc is:
```
proc main () {
    set(root, getperson("Enter a person for the henry listing"))
    set(set, gethenryset(root))
    foreach(set, person, code, n) {
        call showperson(person, code)
    }
}
```

Every DeadEnds program needs a main proc where it starts.  This proc asks for person number 1, creates its Henry set, and then shows the persons in the set. *getperson* is a *built-in function* that interacts with the user to identify a person. *set* is the built-in function that assigns values to identifiers in symbol tables. *foreach* is a general iterator that here iterates the completed henry set showing the persons with codes.

*gethenryset* is a *user-defined function* that creates and returns the list of persons with their codes. Here it is:

```
func gethenryset(person) {
    set(code, list())  /* Create the list for the code. */
    append(code, 1) /* Set the first code to [1] */
    set(set, personset()) /* Create the personset. */
    addtoset(set, person, code) /* Add the first person to the set. */
    call addhenrychildren(set, person, code) /* Add first person's children. */
    return(set) /* Return the full set with codes. */
}
```

The first line creates a *list* and assigns it to the identifier *code*. A list is a list of any of the language's data types. The second line appends a 1 to the code, showing that in this program codes are going to be lists of integers. The third line creates a *personset*, a powerful genealogical data type, and assigns it to the identifier *set*. The *addtoset* line adds the first person to the set. *personset* allows each member person to have an *associated value*; for this application that value is the list holding the person's Henry number.

After adding person 1 to the set, the function calls *addhenrychildren*, which adds the top person's children to the set. That code is:
```
proc addhenrychildren(set, person, code) {
    foreach(children(person), child, n) {
        set(childcode, append(shallowcopy(code), n)) /* Create child's code. */
        addtoset(set, child, childcode) /* Add child to the person set. */
        call addhenrychildren(set, child, childcode) /* Recurse to child's children. */
    }
}
```

The body of the proc is a *foreach* statement that iterates a person's children. *children* is a built-in function that returns the children of its argument. The loop iterates each child. The first line creates the child's Henry code by copying the parent's code and appending the child's index. The child and its code are then added to the set. *addhenrychildren* is then called recursively on each child's first child.

The proc that shows the persons is:
```
proc showperson(person, code) {
    foreach(code, number, n) { d(number) " " }
    name(person) nl()
}
```

That is all there is to it. As usual, recursive problems break down into very little code. This is a simple program that shows the power of the DeadEnds programming language. The program exploits the *personset* datatype with its *associated value*s that can be of any type needed for an application.

There is an issue with this program, though it might seem minor. It is possible for descendents to show up in multiple places in a descendency, that is, a descendency is not really a tree, but a directed graph. Imagine that two great-grandchilren of the top person married and had children (a second cousin marriage). All their descendents, by this program, would show up twice, with different Henry numbers, as descendents of the two second cousins.

Is this an error or just an inconvenience? Should we do something about it? What do you think? Personally I would fix it. This was going to the the programming problem three assignment.
