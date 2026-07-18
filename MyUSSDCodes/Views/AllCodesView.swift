import SwiftUI

/// Second tab: every code on the device behind a search box.
struct AllCodesView: View {
    @EnvironmentObject private var store: CodeStore

    @State private var query = ""
    @State private var editing: UssdCode?
    @State private var creatingCode = false

    private var filtered: [UssdCode] {
        store.data.codes
            .filter { $0.matches(query) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    CodeListView(codes: filtered) { editing = $0 }
                }
            }
            .navigationTitle("All codes")
            .searchable(text: $query, prompt: "Search codes…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingCode = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editing) { code in
                CodeEditorView(code: code)
            }
            .sheet(isPresented: $creatingCode) {
                CodeEditorView(code: nil)
            }
        }
    }
}
