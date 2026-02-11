import Flutter
import Foundation

/// Bridge implementation for Android-specific APIs (iOS equivalent)
class OpenListBridge: NSObject, Android {
    private let registrar: FlutterPluginRegistrar?
    
    init(registrar: FlutterPluginRegistrar? = nil) {
        self.registrar = registrar
        super.init()
    }
    
    func addShortcut() throws {
        print("[OpenListBridge] addShortcut called - iOS does not support shortcuts like Android")
        // iOS doesn't have the same shortcut system as Android
        // This is a no-op on iOS
    }
    
    func startService() throws {
        print("[OpenListBridge] startService called")
        OpenListManager.shared.startServer()
    }
    
    func setAdminPwd(pwd: String) throws {
        print("[OpenListBridge] setAdminPwd called")
        try OpenListManager.shared.setAdminPassword(pwd)
    }
    
    func getOpenListHttpPort() throws -> Int64 {
        let port = OpenListManager.shared.getHttpPort()
        print("[OpenListBridge] getOpenListHttpPort: \(port)")
        return Int64(port)
    }
    
    func isRunning() throws -> Bool {
        let running = OpenListManager.shared.isRunning()
        print("[OpenListBridge] isRunning: \(running)")
        return running
    }
    
    func getOpenListVersion() throws -> String {
        // Get version from build configuration or Info.plist
        let version = Bundle.main.infoDictionary?["OpenListVersion"] as? String ?? "dev"
        print("[OpenListBridge] getOpenListVersion: \(version)")
        return version
    }
}
