import SwiftUI

/// Create or edit a custom code: dial string with {placeholders}, variables and group.
struct CodeEditorView: View {
    let code: UssdCode?

    @EnvironmentObject private var store: CodeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dialCode = ""
    @State private var descriptionText = ""
    @State private var category = "Custom"
    @State private var dangerous = false
    @State private var groupId: String?
    @State private var newGroupName = ""
    @State private var variables: [CodeVariable] = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Code") {
                    TextField("Name", text: $name)
                    TextField("*123*{number}#", text: $dialCode)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                    TextField("Category", text: $category)
                    Toggle("Dangerous code", isOn: $dangerous)
                }

                Section("Group") {
                    Picker("Existing group", selection: $groupId) {
                        Text("No group").tag(String?.none)
                        ForEach(store.data.groups.sorted(by: { $0.name < $1.name })) { group in
                            Text("\(group.icon) \(group.name)").tag(String?.some(group.id))
                        }
                    }
                    TextField("…or create a new group", text: $newGroupName)
                }

                Section {
                    ForEach($variables) { $variable in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("{\(variable.key)}")
                                .font(.callout.monospaced())
                                .foregroundStyle(.tint)
                            TextField("Label", text: $variable.label)
                            Picker("Type", selection: $variable.type) {
                                ForEach(VariableType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .onDelete { variables.remove(atOffsets: $0) }

                    Button {
                        syncVariablesWithCode()
                    } label: {
                        Label("Detect variables from code", systemImage: "wand.and.stars")
                    }
                } header: {
                    Text("Variables")
                } footer: {
                    Text("Add {placeholders} to the code; the app asks for each value before dialing.")
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                if let code, code.custom {
                    Section {
                        Button("Delete code", role: .destructive) {
                            store.deleteCode(id: code.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(code == nil ? "New code" : "Edit code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let code else { return }
        name = code.name
        dialCode = code.code
        descriptionText = code.description
        category = code.category
        dangerous = code.dangerous
        groupId = code.groupId
        variables = code.variables
    }

    private func syncVariablesWithCode() {
        let used = dialCode.matches(of: #/\{([a-zA-Z][a-zA-Z0-9]*)\}/#).map { String($0.1) }
        variables.removeAll { !used.contains($0.key) }
        for key in used where !variables.contains(where: { $0.key == key }) {
            variables.append(CodeVariable(key: key, label: key))
        }
    }

    private func save() {
        syncVariablesWithCode()

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedCode = dialCode.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty {
            error = "Name is required."
            return
        }
        if trimmedCode.isEmpty {
            error = "Code is required."
            return
        }
        if trimmedCode.wholeMatch(of: #/([*#+0-9]|\{[a-zA-Z][a-zA-Z0-9]*\})+/#) == nil {
            error = "Code may only contain *, #, +, digits and {placeholders}."
            return
        }
        if variables.contains(where: { $0.label.trimmingCharacters(in: .whitespaces).isEmpty }) {
            error = "Every variable needs a label."
            return
        }

        var resolvedGroupId = groupId
        let trimmedGroupName = newGroupName.trimmingCharacters(in: .whitespaces)
        if !trimmedGroupName.isEmpty {
            let group = CodeGroup(id: "group-\(UUID().uuidString)", name: trimmedGroupName)
            store.upsert(group: group)
            resolvedGroupId = group.id
        }

        store.upsert(
            code: UssdCode(
                id: code?.id ?? "custom-\(UUID().uuidString)",
                name: trimmedName,
                description: descriptionText.trimmingCharacters(in: .whitespaces),
                code: trimmedCode,
                category: category.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "Custom"
                    : category.trimmingCharacters(in: .whitespaces),
                variables: variables,
                dangerous: dangerous,
                custom: true,
                groupId: resolvedGroupId
            )
        )
        dismiss()
    }
}
