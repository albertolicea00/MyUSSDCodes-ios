import SwiftUI

enum SectionKey: Hashable {
    case group(String)
    case category(String)
}

/// First tab: user groups + categories, "sections" of the catalog.
struct SectionsView: View {
    @EnvironmentObject private var store: CodeStore
    @State private var creatingCode = false

    private var categories: [String] {
        Array(Set(store.data.codes.map(\.category))).sorted()
    }

    private var groups: [CodeGroup] {
        store.data.groups.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                if !groups.isEmpty {
                    Section("My groups") {
                        ForEach(groups) { group in
                            NavigationLink(value: SectionKey.group(group.id)) {
                                sectionRow(
                                    icon: group.icon,
                                    name: group.name,
                                    count: store.data.codes.filter { $0.groupId == group.id }.count
                                )
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteGroup(id: group.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section("Categories") {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(value: SectionKey.category(category)) {
                            sectionRow(
                                icon: "🏷️",
                                name: category,
                                count: store.data.codes.filter { $0.category == category }.count
                            )
                        }
                    }
                }
            }
            .navigationTitle("Sections")
            .navigationDestination(for: SectionKey.self) { key in
                SectionDetailView(key: key)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingCode = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $creatingCode) {
                CodeEditorView(code: nil)
            }
        }
    }

    private func sectionRow(icon: String, name: String, count: Int) -> some View {
        HStack {
            Text(icon)
            Text(name)
            Spacer()
            Text("\(count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

/// Codes inside one group or category.
struct SectionDetailView: View {
    @EnvironmentObject private var store: CodeStore
    let key: SectionKey

    @State private var editing: UssdCode?

    private var title: String {
        switch key {
        case .group(let id):
            guard let group = store.data.groups.first(where: { $0.id == id }) else { return "Group" }
            return "\(group.icon) \(group.name)"
        case .category(let name):
            return name
        }
    }

    private var codes: [UssdCode] {
        switch key {
        case .group(let id):
            return store.data.codes.filter { $0.groupId == id }.sorted { $0.name < $1.name }
        case .category(let name):
            return store.data.codes.filter { $0.category == name }.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        CodeListView(codes: codes) { editing = $0 }
            .navigationTitle(title)
            .sheet(item: $editing) { code in
                CodeEditorView(code: code)
            }
    }
}
