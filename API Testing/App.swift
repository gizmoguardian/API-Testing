import SwiftUI

@main
struct SpottedApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didReceiveMemoryWarning notification: Notification) {
        // Clear caches when memory is low
        URLCache.shared.removeAllCachedResponses()
        
        // Clear temporary files from disk
        let fileManager = FileManager.default
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        try? fileManager.removeItem(at: tempDirectoryURL)
        try? fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        
        // Post notification for views to clean up
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
} 