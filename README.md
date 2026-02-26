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

## License
(TBD) I haven't decided, but the code is avalable on git hub at https://github.com/TomWetmore/DeadEndsSwift
