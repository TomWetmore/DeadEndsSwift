### DeadEnds and Gedcom

1. DeadEnds does not have a persistent database. When a DendEnds program starts it creates a database by reading a Gedcom file. The file is parsed into a Gedcom node tree for each Gedcom record, and those trees are the database records. A Gedcom node is the internal representation of one line of Gedcom. A DeadEnds database consists of four indexes -- a record index (key to tree map) and three others for names, places, and dates.
2. DeadEnds does not require any particular version of Gedcom. It requires three things. First the file must be UTF-8. Second the file must use standard lineage linking. That is, it must use INDI, FAM, SEX, NAME, BIRT, DEAT, MARR, DATE, PLAC, FAMS, FAMC, HUSB, WIFE, and CHIL, in the conventional manner. No other restrictions are placed on the tags and values. And third, the file must be "closed" -- every record referred to must exist.



