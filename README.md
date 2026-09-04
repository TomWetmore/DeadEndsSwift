# DeadEnds Swift

DeadEndsSwift is a Mac, iPad, and Linux genealogy software system written in Swift. It has a core genealogical library, SwiftUI-based apps for Mac and iPad, and command line programs for Mac and Linux.

DeadEnds Swift is the successor to the DeadEnds C project, which is the successor to my LifeLines C program from the 1990's. The switch to SwifUI was based on Swift's support for memory management, Unicode, and its core library. DeadEnds Swift (*DeadEnds* from now on) supports reading Gedcom files, building an in-memory database, modifying that database and visualizing family relationships. It has a programming subsystem.

## Features

- Reads Gedcom files into an in-memory databases. It reads Gedcom files from any standard that uses the usual lineage-linking tags (INDI, FAM, FAMS, FAMC, HUSB, WIFE, CHIL), and a few other standard tags (NAME, SEX, BIRT, DEAT, MARR, DATE, PLAC, SOUR). DeadEnds does not have a persistant database; it uses Gedcom files as its backing store.
- The SwiftUI app displays Person, Family, Pedigree, and severl other pages. The number of views that make up the SwiftUI app are numerous and growing.
- One exciting page is the Desktop, in which persons show up as index cards that are moved and manipulated. I continue developing this metaphor; it uses ideas developed more than 40 years ago when I began writing genealogical software.
- Supports editing of genealogical data -- adding, deleting and modifying records, adding, removing and changing family relationships. Because the records are Gedcom-based trees, I am experimenting with two editing styles --- editing records as pure text, or editing the record as a Gedcom tree. Examples of both styles are implemented.
- Supports searching. LifeLines used a name index to provide searching by name. DeadEnds extends this with date and place indexes; it can search based on any combination of names with dates and times of vital events.
- Supports a builtin programming language similar to the one in LifeLines. This is a major feature.

## Targets

The DeadEnds project and repository contains several  targets. Here is an introduction to the main ones.

- DeadEndsLib -- the base genealogical library. It contains the database and its import stack; the Gedcom node, record, person, family datatypes; the interpreter; and other code. The code is common to Mac, IPad, and Linux.

- DeadEndsApp -- the SwiftUI application; it has several standard genealogical screens (called pages), includling person, family, pedigree, editing, merging, and desktop (see above). It is Mac only.

- RunScript -- the Swift half of the script interpretation process. It reads a LifeLines script from an S-expression file, then loads a database using the import stack, and then interprets the script within the context of the database.

- DeadEndsIPad -- place holder for an upcoming iPad version of the DeadEnds app.

  

## Status

Currently under active development. All versions found at GitHub should compile completely and work.

## Using the DeadEnds App

### Building

DeadEndSwift is packaged in a GitHub repository at https://github.com/TomWetmore/DeadEndsSwift. It contains the code targets, documentation, notes, example Gedcom files, and DeadEnds programs. Though under development I keep the targets buildable and runnable at all (well, most) times.

After you pull the repository, the main two targets to build (for the Mac) are *DeadEndsLib*, the underlying genealogical library, and *DeadEndsApp*, the SwiftUI app. Swift is an open source language available on Mac, Linux and Windows; on the other hand SwiftUI is Apple propritary. If you pull the repository onto a Mac you can build all targets immediately with Xcode. If you pull it onto a Linux system you can use the included ```package.swift``` file to build *DeadEndsLib* and *DeadEndsCommand*, a command line program that runs DeadEnds programs.

If you would like to experiment with the iPad you can build the *DeadEndsIPad* target and run it in a simulator or load it onto a real iPad. The iPad app is currently a single SwiftUI page with the DeadEnds *programming IDE*. You can only develop and run DeadEnds programs with the app. 

To run on Linux you need to install the Swift tool chain. I installed it on *Ubuntu* using *Swiftly 1.1.3*, Swift’s toolchain manager, and then used *swiftly* to install the Swift toolchain. I then installed some Ubuntu development packages I thought I might need, and then verified that the command `swift build` built *DeadEndsLib* and *DeadEndsCommand* from the `Package.swift` file.

I don't have a Linux machine so I created a Ubuntu VM on my Mac, where I do all my Linux testing. The Swift tool chain also runs on Windows, but I have no plans for that platform.

### Starting the App

Double click the app icon. The loading screen appears. Push the Open Gedcom File button and choose a Gedcom file from the panel. The app reads the Gedcom file, validates it, and store its contents in an in-RAM database. A person search screen appears. Enter a name in Gedcom format (surname set off by slashes). DeadEnds will display the list of persons who match that name. Click the person you want, and the Person Page for that person appears.

### Person Page

The app is in development, so user interface flow may seem a little strange in places and will likely change. The person page shows a person and the person's parents, spouses, and children. Birth and death information is given for each person. If you click any person, except for the main person, the person page changes to show the selected person as the new main person.

Across the bottom of the Person Page are buttons that make up the person action bar. The Father, Mother, Older Sibling, and Younger Sibling buttons make those persons the main person in the person page. The Pedigree and Family buttons move to the Pedigree Page and the Family Page. The Descendancy and 

### Pedigree Page

The Pedigree Page shows a person and three generations of ancestors. If you select one of the persons in the pedigree you switch back to the Person Page. However, you can navigate on the Pedigree Page by using the four button on the bottom of the page. With them you can navigate to the main person's father, mother, spouses or children.

### Family Page

The Family Page shows a family with the two parents at the top followed by the children. When you click a person on tne page the app navigates to the person's Person Page. The Family Page has an action bar on the bottom. The button labeled Open Desktop navigates to the Desktop Page with cards prearranged for the parents and children. The Tree Editor button is CURRENTLY A NO-OP.

### Descendants and Descendancy List

There are two action buttons currently on the Person Page that takes you to pages showing descendancies. Click on the Descendants button the display shifts to the Dependancy Page for the main person. This list show an indented list of all descendants of the main person. No spouses are shown. The style of person display is that same style used on the Person and Family page. Each person with descendants is collapsible by clicking  a disclosure triangle. If you then click on a person on the Descendancy page you return to the Person Page of that person.

Click on the Descendancy List button on the Person Page to move to the Descendancy List Page. This page shows the descendants of the main person also. Persons are shown as single lines, and spouses are also shown.  When you expand a person to see their descendants you will first see their spouse or spouses. After you expand a spouse line the children of that family are shown. This page distinguishes the children from different families by always interspersing a spouse/family level. The Descendants Page shows all the children of a person as a single list with no information about spouses.

### Desktop Page

The Desktop Page represents a desktop surface and "index cards" that can be moved around the desktop. There are two ways to get to the Desktop Page. First from the Person Page you can hit the Open Desktop button, which opens the Desktop with a card for the person. The Family Page also has an Open Desktop button. When you hit that button the Desktop opens along with index cards for the parents and the children laid out nicely on the Desktop. There's not a whole lot you can do on the page for now. But you can resize the cards, move the cards, group the cards and move groups together, and bring cards to the front if you overlap them. The cards have a context menu that allows you to open spouses if they are not  yet open. There is a context menu for the entire page that allows you to search for and add any person to the Desktop.

### Gedcom Record Editors

I have experimented with two ways to edit records and both are available in the user interface. From the Person Page you can select the Tree Editor or Text Editor button, and each will open a new page where you will see and edit the person's record.

#### Gedcom Tree Editor

 Gedcom tree.

- Expand and Collapse  -- lines in the tree can be expanded or collapsed. If a line is expanded its children are also shown; if the line is collapsed its children are not shown. You control this state using the disclosure chevron at the left end of line. Leaves of the tree, of course, cannot be expanded so don't have chevrons.
- Select -- one line is always selected (shown by the blue selection color)editing features, but little of them are now brought forward to the current set of pages. The issue of editing boils down, in my opinion, as to how far to implement Gedcom tree based editing. Bottom line is that I am very much in favor of that approach.

#### Gedcom Text Editor

The

### The Database

The DeadEnds database is a collection in-RAM, non persistent indexes and lists. The main component of the database is the **record index**, a map from record keys (Gedcom's *cross-reference identifiers*) to records. The records are tree structures composed of nodes, each node representing one line of Gedcom. There are other components in the database, including the name, date and place indexes.

A DeadEnds database is not persistent -- it exists only while the app is running. The *backing store* of DeadEnds are Gedcom files. When the app starts up its first task is to interact with the user to identify a Gedcom file to read to become that becomes initial state of the database.

### Use of Gedcom

Most genealogical programs use Gedcom as a file format for importing and exporting genealogical data. Early on (forty plus years ago) I decided to also use Gedcom as the format for all records in my genealogical software. I represent records as node trees, where each node is a Gedcom line.

Using Gedcom as the internal record format does not imply that DeadEnds enforces an official Gedcom standard. My software has never worried about standards. However, I do have to enforce a small set of rules. They boil down to:

- Person, Family and Source records must use INDI, FAM, and SOUR tags.
- Persons must link to Families via FAMS and FAMC values. Families must have reciprocal HUSB, WIFE, and CHIL links.
- Persons with name and sex values must use NAME and SEX lines; values of NAME lines must set off surnames with slashes.
- Birth, death, and marriage events must use BIRT, DEAT, and MARR tags.
- Date and places of events must use DATE and PLAC lines. The values of these lines are treated as free format.
- Records must be closed -- all records must have a unique key and all keys used as values must refer to existing records.

Using Gedcom for the internal representation of genealogical data was unconventional in the late 1980s, but no longer is so.







## License
(TBD) I haven't decided, but the code is avalable on git hub at https://github.com/TomWetmore/DeadEndsSwift
