## Principles of Operation and APIs

The goal of this doc is to introduce potential developers to the principles behind DeadEnds software and present the higher level APIs that access the main features of the software.

### DeadEndsLib

DeadEndsLib is a library built from many source files. The library is a static library with the name libDeadEndsLib.a. Swift files that use the library must import DeadEndsLib.





#### GedcomNode

GedcomNode is a Swift class central to DeadEnds. DeadEnds records are composed of GedcomNode trees. (nodes in sequel, until we get to ProgramNodes) . Each node represents a line of Gedcom and the nodes are composed into trees that each represent a Gedcom record. All genealogical data in DeadEnds is ultimately composed of nodes and node trees. Here is the core class:

```swift
typealias RecordKey = String

final public class GedcomNode: Identifiable, CustomStringConvertible {
    public let id = UUID()
    
    public var key: RecordKey?
    public var tag: String
    public var val: String?

    public var sib: GedcomNode?
    public var kid: GedcomNode?
    public weak var dad: GedcomNode?
    
    public var lev: Int
    public init(key: RecordKey? = nil, tag: String, val: String? = nil)
    ...
}
```

GedcomNodes are Identifiable via the UUID id property. This is a rare spot in the DeadEnds architecture where library code has awareness of SwiftUI issues. The key, tag, and val strings are read directly from Gedcom fields. The sib, kid and dad links provide the tree structure -- each node in a tree points to its first kid, next sib, and dad. These three-letter names are used to avoid confusion with the sibling, child and parent relationships at the person record level. Lev is the Gedcom level of the node; it is not a stored property as it is computed when needed. The initializer only sets the three Gedcom properties.

Here are some more properties of GedcomNodes:

```swift
    ...
    public var kids: [GedcomNode]
    public func kid(withTag tag: String) -> GedcomNode?
    public func kid(withTags tags: [String]) -> GedcomNode?
    public func kids(withTag tag: String) -> [GedcomNode]
    public func kids(withTags tags: [String]) -> [GedcomNode]
    public func kidVal(forTag tag: String) -> String? 
    public func kidVal(forTags tags: [String]) -> String?
    public func kidVals(forTag tag: String) -> [String]
    public func kidVals(forTags tags: [String]) -> [String]
    public func kid(atPath path: [String]) -> GedcomNode?
    public func kidVal(atPath path: [String]) -> String?
    ...
```

These methods and property access a node's kid nodes and their values. Computed property kids returns all a node's kids (the kid of the node and the sib chain of that kid). Methods named kid or kids return nodes; methods named kidVal or kidVals returns the values of the kids. Methods exist for filtering kids with specific tags.

There are several other methods on GedcomNode:

```swift
    ...
    func gedcomText(level: Int = 0, indent: Bool = false) -> String
    public var description: String
    public func printTree(level: Int = 0, indent: String = "")

    public var subnodes: [GedcomNode]

    var hasKids: Bool

    func addKid(tag: String, val: String? = nil) -> GedcomNode
    func addKid(_ kid: GedcomNode) -> GedcomNode
    func addBareKid(_ kid: GedcomNode) -> GedcomNode
    func addSubtree(_ kid: GedcomNode) -> GedcomNode
    func addKidAfter(_ kid: GedcomNode, sib: GedcomNode?)
    func lastKid() -> GedcomNode?
    func removeKid()
    var prevSib: GedcomNode?
    func replaceKid(old oldNode: GedcomNode, with newNode: GedcomNode) -> Bool
    func addSib(_ sib: GedcomNode)
    func removeSib() -> GedcomNode?
    func moveUp() -> Bool
    func moveDown() -> Bool
    public func deepCopy(sibs: Bool = true) -> GedcomNode
    func deepTreeCopy()
    func deepForestCopy() -> GedcomNode
```
