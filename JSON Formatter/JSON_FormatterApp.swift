import SwiftUI

@main struct JSON_FormatterApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Text("JSON")
        }
        .menuBarExtraStyle(.window)
    }
}
