import SwiftUI

@main
struct CouchTo5KFlexibleStartApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task { await NotificationManager.shared.requestAuthorization() }
        }
    }
}
