import SwiftUI

@main
struct MyUSSDCodesApp: App {
    @StateObject private var store = CodeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
