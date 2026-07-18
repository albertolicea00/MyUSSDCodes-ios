import SwiftUI

/// Bottom tab bar: Sections, All codes, Settings.
struct RootView: View {
    var body: some View {
        TabView {
            SectionsView()
                .tabItem {
                    Label("Sections", systemImage: "square.grid.2x2")
                }
            AllCodesView()
                .tabItem {
                    Label("All codes", systemImage: "magnifyingglass")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
