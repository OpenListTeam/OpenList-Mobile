import Flutter
import Foundation

/// Bridge implementation for App Configuration APIs
class AppConfigBridge: NSObject, AppConfig {
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let wakeLock = "app_config_wake_lock"
        static let startAtBoot = "app_config_start_at_boot"
        static let autoCheckUpdate = "app_config_auto_check_update"
        static let autoOpenWebPage = "app_config_auto_open_web_page"
        static let dataDir = "app_config_data_dir"
        static let silentJumpApp = "app_config_silent_jump_app"
    }
    
    func isWakeLockEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.wakeLock)
    }
    
    func setWakeLockEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.wakeLock)
        print("[AppConfigBridge] Wake lock enabled: \(enabled)")
    }
    
    func isStartAtBootEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.startAtBoot)
    }
    
    func setStartAtBootEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.startAtBoot)
        print("[AppConfigBridge] Start at boot enabled: \(enabled)")
    }
    
    func isAutoCheckUpdateEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.autoCheckUpdate)
    }
    
    func setAutoCheckUpdateEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.autoCheckUpdate)
        print("[AppConfigBridge] Auto check update enabled: \(enabled)")
    }
    
    func isAutoOpenWebPageEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.autoOpenWebPage)
    }
    
    func setAutoOpenWebPageEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.autoOpenWebPage)
        print("[AppConfigBridge] Auto open web page enabled: \(enabled)")
    }
    
    func getDataDir() throws -> String {
        if let customDir = defaults.string(forKey: Keys.dataDir) {
            return customDir
        }
        
        // Default to app's document directory
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].path
        return documentsDirectory
    }
    
    func setDataDir(dir: String) throws {
        defaults.set(dir, forKey: Keys.dataDir)
        print("[AppConfigBridge] Data directory set to: \(dir)")
    }
    
    func isSilentJumpAppEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.silentJumpApp)
    }
    
    func setSilentJumpAppEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.silentJumpApp)
        print("[AppConfigBridge] Silent jump app enabled: \(enabled)")
    }
}
