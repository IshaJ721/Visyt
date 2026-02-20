import SwiftUI

@main
struct VisytApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vm)
        }
    }
}
