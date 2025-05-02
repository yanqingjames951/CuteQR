import SwiftUI

@main
struct CuteQRApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.pastelPink)
                .preferredColorScheme(getColorScheme())
        }
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch colorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
