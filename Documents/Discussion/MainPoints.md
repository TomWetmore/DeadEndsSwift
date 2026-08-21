Based on Gedcom.

No persistant database -- backing store is Gedcom files.

Only requirement for Gedcom is the semantic tags. User is otherwise free.

Programming language feature.

Evidence Versus Conclusion Operations -- is it possible with Gedcom?


My project is called DeadEnds. I have mentioned that there are a number of design decisions that may cause concern.

First, DeadEnds does not have a persistent database. When it starts up it reads a Gedcom file and builds an in-memory database that dissappears when the program ends. Since the whole database is in memory size is a concern. Since the database must be created afresh whenever a DeadEnds program starts performance is a concern.


Second, the database is very simple. The genealogical records (persons and families, etc) are "Gedcom node trees", which are transformations of Gedcom record to trees where each node represents one line of Gedcom. A database consists of a map from keys to these records, as well as a name index, date index and place index for quick searching. The database is created from scratch when any DeadEnds family program starts.
DeadEnds does not have a persistent database. Instead it reads a Gedcom file during startup and builds an in memory database.
