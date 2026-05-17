//
//  PickerSupport.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 May 2026.
//  Last changed on 16 May 2026.
//

import SwiftUI
import DeadEndsLib

/// View for a single line of a person choosing view.
struct PersonChoiceRow: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(person.displayName())
                .font(.title3)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        let birth = person.birthEvent?.summary
        let death = person.deathEvent?.summary

        switch (birth, death) {
        case let (b?, d?): return "born \(b) — died \(d)   \(person.key)"
        case let (b?, nil): return "born \(b)   \(person.key)"
        case let (nil, d?): return "died \(d)   \(person.key)"
        default: return person.key
        }
    }
}

/// Method in the program model that handles the run button.
@MainActor
func handleRunButton(database: Database) async {

    guard let parsedProgram else { return }
    diagnostics = []
    output.clear()
    let buffer = BufferedProgramOutput()
    let program = Program(parsedProgram: parsedProgram,database: database,output: buffer,
        interaction: self)

    do {
        let result = try await Task.detached {
            try await program.interpretProgram()
        }.value

        output.text = displayableOutput(buffer.text)
    } catch let error as RuntimeError {
        output.text = displayableOutput(buffer.text)
        diagnostics = [Diagnostic(message: error.message, line: error.line > 0 ? error.line : nil)]
    } catch {
        output.text = displayableOutput(buffer.text)
        diagnostics = [Diagnostic(message: String(describing: error), line: nil)]
    }
}

/// Use the UI to choose a person.
/// chooseperson(msg: String, pattern: String) -> Person?
func bltinChoosePerson(_ args: [ParsedExpr]) async throws -> ProgramValue {

    guard let prompt = try evaluateString(args[0],
                                errMsg:"chooseperson: 1st arg must be a prompt message")
    guard let pattern = try evaluateString(args[1],
                                errMsg: "chooseperson: 2nd arg must be a name pattern")

    let candidates = database.persons(withName: pattern)

    await output.flush()

    guard let person = await interaction.choosePerson(
        prompt: prompt,
        candidates: candidates
    ) else {
        return .null
    }
    return .person(person)
}
