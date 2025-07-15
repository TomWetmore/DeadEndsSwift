struct FamilySelectionView: View {
    @EnvironmentObject var model: AppModel
    let families: [GedcomNode]

    var body: some View {
        List(families, id: \.self) { family in
            Button {
                model.path.append(.family(family))
            } label: {
                Text(displayFamilySummary(family)) // Show spouses/children or marriage date
            }
        }
        .navigationTitle("Select Family")
    }
}