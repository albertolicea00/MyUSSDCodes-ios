import SwiftUI

private let catalogRawURL =
    "https://raw.githubusercontent.com/albertolicea00/MyUSSDCodes-collection/main/codes/gsm-standard.json"

/// Third tab: import, data management and app info.
struct SettingsView: View {
    @EnvironmentObject private var store: CodeStore

    @State private var importURL = catalogRawURL
    @State private var importing = false
    @State private var showPasteSheet = false
    @State private var showResetConfirmation = false
    @State private var resultMessage: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Import collections") {
                    TextField("Collection URL", text: $importURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout)
                    Button {
                        importFromURL()
                    } label: {
                        if importing {
                            ProgressView()
                        } else {
                            Label("Import from URL", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(importing)
                    Button {
                        showPasteSheet = true
                    } label: {
                        Label("Paste JSON", systemImage: "doc.on.clipboard")
                    }
                }

                Section("Data") {
                    LabeledContent("Codes", value: "\(store.data.codes.count)")
                    LabeledContent("Groups", value: "\(store.data.groups.count)")
                    LabeledContent("Imported collections", value: "\(store.data.importedCollections.count)")
                    Button("Reset to bundled catalog", role: .destructive) {
                        showResetConfirmation = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link(destination: URL(string: "https://github.com/albertolicea00/MyUSSDCodes-collection")!) {
                        Label("Code catalog", systemImage: "books.vertical")
                    }
                    Link(destination: URL(string: "https://github.com/albertolicea00/MyUSSDCodes-ios")!) {
                        Label("iOS app source", systemImage: "apple.logo")
                    }
                    Link(destination: URL(string: "https://github.com/albertolicea00/MyUSSDCodes-apk")!) {
                        Label("Android app source", systemImage: "smartphone")
                    }
                    LabeledContent("License", value: "MIT © 2026 Alberto Licea")
                }

                Section {
                    Text("USSD codes are executed by your carrier. Codes vary by country, carrier and plan; some may be paid services. Double-check a code before running it. iOS blocks some USSD codes in the dialer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPasteSheet) {
                PasteImportSheet { raw in
                    do {
                        let count = try store.importCollection(json: Data(raw.utf8))
                        resultMessage = "Imported \(count) codes."
                    } catch {
                        resultMessage = "Import failed: \(error.localizedDescription)"
                    }
                }
            }
            .confirmationDialog(
                "All custom codes, groups and imported collections will be deleted and the bundled GSM catalog restored.",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { store.reset() }
            }
            .alert(
                resultMessage ?? "",
                isPresented: Binding(
                    get: { resultMessage != nil },
                    set: { if !$0 { resultMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func importFromURL() {
        guard let url = URL(string: importURL.trimmingCharacters(in: .whitespaces)) else {
            resultMessage = "Invalid URL."
            return
        }
        importing = true
        Task {
            defer { importing = false }
            do {
                let count = try await store.importCollection(from: url)
                resultMessage = "Imported \(count) codes."
            } catch {
                resultMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}

/// Free-form JSON paste box for offline imports.
private struct PasteImportSheet: View {
    let onImport: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var raw = ""

    var body: some View {
        NavigationStack {
            TextEditor(text: $raw)
                .font(.callout.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(8)
                .navigationTitle("Paste collection JSON")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            onImport(raw)
                            dismiss()
                        }
                        .disabled(raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}
