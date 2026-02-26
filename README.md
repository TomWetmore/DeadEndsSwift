# DeadEndsSwift

DeadEndsSwift is a macOS genealogy software system written in Swift. It consists of a core genealogical library, a SwiftUI-based application, and some command line programs that use the library.

DeadEnds is the successor to my C-based DeadEnds project, which was the successor to my C-based LifeLines program written in the 1990's. DeadEnds Swift supports reading Gedcom files, building an in-memory genealogical database, and visualizing family relationships.

In the rest of this file DeadEnds always means DeadEnds Swift, unless DeadEnds C is used directly.

## Features
- Reads Gedcom files into internal (in-RAM) databases. DeadEnds can read Gedcom files from any standard that uses the normal lineage-linking tags (FAMS, FAMC, HUSB, WIFE, CHIL), and a few other standard tags (NAME, SEX, BIRT, DEAT, MARR, DATE, PLAC, SOUR, ...). DeadEnds uses Gedcom files as backing store for its databases when the program is not running. DeadEnds does not think of Gedcom files as anything other than snoozing DeadEnds databases.
- Displays Person, Family, Pedigree, and other views. The SwiftUI app features a number of views and screens. These are under active development.
- One exciting screen is the Desktop view, in which persons show up in the form of index cards that can be moved and manipulated on the Desktop. I hope to continue developing this metaphor, as it represents ideas formulated more than 40 years ago when I had not the time to work on them.
- Supports editing of genealogical data -- adding, deleting and modifying records, adding, removing and changing family relationships.
- Supports searching. LifeLines supports search by name only, as each index in LifeLines requires custom records in the database and custom data structures at run time. With DeadEnds there is no persistent database, and there is a rich set of container structures, so writing date and place indexes is easy, so DeadEnds search can use names, dates, and/or places.
- Supports an internal scripting language. The scripting language is nearly identical to that of the LifeLines scripting language. Current access to this feature is a little awkward becuase I have not had the time to fashion a Swift parser for the scripting language (the C version used yacc). There is a patch for this however. I have written a yacc-based (same yacc file used by LifeLines) C program that parses LifeLines scripts and converts them to S-expressions (Lisp). DeadEnds Swift has a command line program that reads the S-expressions, converts them to an abstract syntax tree matching that of LifeLines, and then interprets the scripts. This is a proof of concept only, though it works.

## Targets

The DeadEnds project consists of  targets. Here is an introduction to the main ones.

- DeadEndsLib -- the base genealogical library. It contains the database and its import stack; the Gedcom node, record, person, family datatypes; the interpreter; and other code.

- DeadEndsApp -- the SwiftUI application; it has several standard genealogical screens (called pages in Deadends), includling person, family, pedigree, editing, merging, and desktop (see above).

- RunScript -- the Swift half of the script interpretation process. It reads a LifeLines script from an S-expression file, then loads a database using the regular database import stack, and then interprets the script

- DeadEndsIPad -- place holder for an upcoming iPad version of the DeadEnds app.

  

## Status

Currently under active development. All versions found at GitHub should compile completely and work.

## Using the DeadEnds App

### Starting

Double click the app icon. The loading screen appears. Push the Open Gedcom File button and choose a Gedcom file from the open file panel. The Gedcom file is read, validated, and its contents stored in an in-RAM database. A person search screen then appears. Enter a person's name in 'Gedcom name' format (surname set off by slashes). DeadEnds will show a list of everyone in the database who matches the name. Click the person you want, and the Person Page for that person appears.

### Person Page

The app is still in development, so the user interface flow may seem a little strange in places. Okay, the person page shows a person and the person's parents, spouses, and children. Birth and death information is given for each person. If you click any person, except for the main person, the person page changes, now showing the selected person as the main person.

Across the bottom of that page are the buttons making up the 'person action bar'. The Father, Mother, Older Sibling, and Younger Sibling buttons make those persons the main person in the person page. The Pedigree and Family buttons move to the Pedigree Page and the Family Page.

### Pedigree Page

The Pedigree Page shows a person and three generations of ancestors. If you select one of the persons in the pedigree you switch back to the Person Page. However, you can navigate on the Pedigree Page by using the four button on the bottom of the page. With them you can navigate to the main person's father, mother, spouses or children.

### Family Page

The Family Page shows a family with the two parents at the top followed by the children. When you click a person on tne page the app navigates to the person's Person Page. The Family Page has an action bar on the bottom. The button labeled Open Desktop navigates to the Desktop Page with cards prearranged for the parents and children. The Tree Editor button is CURRENTLY A NO-OP.

### The Database

The DeadEnds database is a collection in-RAM, non persistent indexes and lists. The main component of the database is called the 'record index', a map from record keys (Gedcom cross-reference identifiers) to records. The records are tree structures composed of nodes, each node representing one line of Gedcom. There are other components in the database, including name, date and place indexes.

The key point about a DeadEnds database is that it is not persistent. It exists only while the app is running. The 'backing store' of DeadEnds are Gedcom files. When the app starts up its first task is to interact with the user and identify the Gedcom file to read to become the initial state of the database.

### Use of Gedcom

Most genealogical programs use Gedcom as 'intended', as a file format for importing and exporting data. Early on I decided to also use Gedcom as the internal format for all records. Going back forty years now I have always represented records as node trees, where each node is a Gedcom line. Of historical interest, the records in LifeLines databases (persistent and B-tree based) are Gedcom strings. When read to RAM records are parsed to node trees; when written back out records the are flattened back to text.

Using Gedcom as the internal record format may does not imply that DeadEnds is complient to some official Gedcom standard. Early on decided I would not enforce a standards; I wanted to be as loosey goosey as possible. I do have to enforce a minimalist set of rules but ignore everything else. The rules boil down to:

- Person, Family and Source records must use INDI, FAM, and SOUR tags.
- Persons must link to Families via FAMS and FAMC values.
- Persons with name and sex values must use NAME and SEX lines; values of NAME lines must set off surnames with slashes.
- Families must link to Persons via HUSB, WIFE, and CHIL nodes.
- Birth, death, and marriage events must use BIRT, DEAT, and MARR tags.
- Date and places of events must use DATE AND PLAC lines.
- Records must be closed -- all records referred to must exist -- no wild pointers allowed.
- I beleive these rules are consistent with every version of lineage-linked Gedcom standards.

Using Gedcom for the internal representation of genealogical data was unconventional in the late 1980s, but no longer is so.







## License
(TBD) I haven't decided, but the code is avalable on git hub at https://github.com/TomWetmore/DeadEndsSwift
