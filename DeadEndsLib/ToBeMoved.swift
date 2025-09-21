//
//  ToBeMoved.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 9/16/25.
//

import Foundation

// In DeadEndsLib
public extension GedcomNode {
    /// Replaces this node's entire children list, fixing parent links.
    func replaceChildren(with newFirstChild: GedcomNode?) {
        var c = newFirstChild
        while let n = c {
            n.dad = self
            c = n.sib
        }
        self.kid = newFirstChild
    }
}
