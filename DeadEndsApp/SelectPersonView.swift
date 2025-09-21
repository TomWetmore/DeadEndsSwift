//
//  SelectPersonView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 16 September 2025.
//

import SwiftUI

struct SelectPersonView: View {
    @EnvironmentObject var model: AppModel
    @State private var key: String = "@I1@"

    var body: some View {
        VStack {
            Text("Enter a GEDCOM Key")
            TextField("@I123@", text: $key)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Load Person") {
                if let person = model.database?.recordIndex.person(for: key) {
                    model.path.append(Route.person(person))
                } else {
                    print("Key not found")
                }
            }
        }
        .padding()
    }
}
