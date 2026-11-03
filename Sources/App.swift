import SwiftUI

@main
struct FolderViewerApp: App {
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
        }
        .defaultSize(width: 900, height: 600)
    }
}
