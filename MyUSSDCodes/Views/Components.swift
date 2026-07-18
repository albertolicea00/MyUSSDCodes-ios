import SwiftUI

/// One code inside a list: name, dial string, description and danger badge.
struct CodeRow: View {
    let code: UssdCode

    var body: some View {
        HStack(spacing: 12) {
            if code.dangerous {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(code.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(code.code)
                    .font(.callout.monospaced())
                    .foregroundStyle(.tint)
                if !code.description.isEmpty {
                    Text(code.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

/// Reusable list of codes: tap → pre-dial sheet, swipe → edit/delete for custom codes.
struct CodeListView: View {
    @EnvironmentObject private var store: CodeStore
    let codes: [UssdCode]
    let onEdit: (UssdCode) -> Void

    @State private var running: UssdCode?

    var body: some View {
        List {
            ForEach(codes) { code in
                Button {
                    running = code
                } label: {
                    CodeRow(code: code)
                }
                .swipeActions(edge: .trailing) {
                    if code.custom {
                        Button(role: .destructive) {
                            store.deleteCode(id: code.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            onEdit(code)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .sheet(item: $running) { code in
            RunCodeSheet(code: code)
        }
    }
}

/// Asks for the code's variables (if any), warns on dangerous codes, then opens the dialer.
struct RunCodeSheet: View {
    let code: UssdCode

    @Environment(\.dismiss) private var dismiss
    @State private var values: [String: String] = [:]

    private var ready: Bool {
        code.variables.allSatisfy { variable in
            !(values[variable.key] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(code.code)
                        .font(.title3.monospaced())
                        .foregroundStyle(.tint)
                    if !code.description.isEmpty {
                        Text(code.description)
                            .font(.callout)
                    }
                }

                if !code.variables.isEmpty {
                    Section("Fill in before dialing") {
                        ForEach(code.variables) { variable in
                            TextField(
                                variable.label,
                                text: binding(for: variable.key),
                                prompt: Text(variable.hint.isEmpty ? variable.label : variable.hint)
                            )
                            .keyboardType(keyboard(for: variable.type))
                        }
                    }
                }

                if code.dangerous {
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This code can lock your SIM, change settings or cost money. Double-check before running it.")
                                if !code.notes.isEmpty {
                                    Text(code.notes)
                                }
                            }
                            .font(.callout)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        UssdDialer.dial(UssdDialer.dialString(for: code, values: values))
                        dismiss()
                    } label: {
                        Label("Open in dialer", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!ready)
                }
            }
            .navigationTitle(code.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { values[key] ?? "" },
            set: { values[key] = $0 }
        )
    }

    private func keyboard(for type: VariableType) -> UIKeyboardType {
        switch type {
        case .text: return .default
        case .number: return .numberPad
        case .phone: return .phonePad
        }
    }
}
