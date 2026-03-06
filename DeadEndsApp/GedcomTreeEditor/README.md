# Gedcom Tree Editor

The Gedcom tree editor is built from SwiftUI views and other components. The editor appears as one of the DeadEndsApp page views.

The Gedcom tree editor allows a user to edit a Gedcom record in its 'native' form as a tree of Gedcom nodes. Nodes can be expanded (show the next level below) or closed. Disclosure triangles indicate whether a node is expanded or not. Leaf nodes do not have disclosure triangles.

The files that implement the editor include:

- GedcomEditorPage.swift
- GedcomTreeEditor.swift
- GedcomTreeEditorRow.swift
- GedcomTreeEditorModel.swift
- GedcomTreeManager.swift
- DragDropStuff.swift
- GedcomTreeValidator.swift
- TreeEditorButtons.swift

## GedcomTreeEditorModel

The Gedcom tree editor model keeps track of the the visual state of the Gedcom tree. It tracks the set of expanded nodes and the  selected node. It tracks the locations of each row to support drag and drop operations. And it uses two counters to 

The heading for the model is:

```swift
@Observable
final class GedcomTreeEditorModel {
    var expandedSet: Set<UUID> = []
    var selectedNode: GedcomNode? = nil
    var rowFrames: [UUID: CGRect] = [:]
    var changeCounter: Int = 0
```

**expandedSet** holds the UUID's of the expanded nodes. **selectedNode** holds the selected node. **rowFrames** holds the frames of the visible rows (a row on the editor view corresponds with a Gedcom node in the record tree). I'll explain **changeCounter** when I better understand it.

The **init(root: GedcomNode? = nil)** sets the first node to the selected node and adds the node to the expanded set.

Method **func toggleExpansion(for node: GedcomNode)** toggles the expansion state of a node, selecting the node if it toggles to the expanded state.

 Property **var canDeleteSelectedNode: Bool** returns whether a node can be deleted. Currently level 0 nodes and level 1 nodes with lineage-linking tags can't be deleted. Property  **var canMoveDownSelectedNode: Bool** returns whether a node can moved down its sibling chain (swapped with its next sibling). Property **var canMoveUpSelectedNode: Bool** returns whether a node can be moved back in its sibling chain (swapped with its previous sibling)

Method **func selectDad()** selects the dad node of the current node. Method **func selectFirstKid()** selects the first kid of the selected node. Method **func selectNextSib()** selects the next sib of the selected mode. Method **func selectPrevSib()** selects the pervious sib of the selected node.

## GedcomEditorPage.swift

The Gedcom editor page view renders a header, an editable Gedcom tree and edit control buttons. The view structure begins:

```swift
struct GedcomEditorPage: View {
    @Bindable var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode
    var title: String = "Edit Gedcom Record"
```

..................
```swift
    var body: some View {
        VStack(spacing: 0) {
        // Header
        HStack {

​        Text(title)

​          .font(.headline)

​        Spacer()

​      }

​      .padding(.horizontal, 8)

​      .padding(.vertical, 6)

​      .background(Color(NSColor.underPageBackgroundColor))



​      Divider()



​      // Editable Gedcom tree.

​      GedcomTreeEditor(viewModel: viewModel, manager: manager, root: root)



​      Divider()



​      // Edit buttons.

​      TreeEditorButtons(viewModel: viewModel, treeManager: manager)

​    }

  }

}
```
