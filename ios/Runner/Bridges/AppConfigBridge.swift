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
        if let customDir = defaults.string(forKey: Keys.dataDir), !customDir.isEmpty {
            print("[AppConfigBridge] Using custom data directory: \(customDir)")
            return customDir
        }
        
        // Default to app's document directory with openlist_data subdirectory
        // This follows iOS app data storage guidelines
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let openlistDataDir = documentsDirectory.appendingPathComponent("openlist_data")
        
        // Create directory if not exists
        if !FileManager.default.fileExists(atPath: openlistDataDir.path) {
            do {
                try FileManager.default.createDirectory(at: openlistDataDir, withIntermediateDirectories: true, attributes: nil)
                print("[AppConfigBridge] Created data directory: \(openlistDataDir.path)")
            } catch {
                print("[AppConfigBridge] Failed to create data directory: \(error)")
                throw error
            }
        }
        
        print("[AppConfigBridge] Data directory: \(openlistDataDir.path)")
        return openlistDataDir.path
    }
    
    func setDataDir(dir: String) throws {
        // On iOS, we should not allow users to change data directory arbitrarily
        // But we keep the method for compatibility
        if dir.isEmpty {
            defaults.removeObject(forKey: Keys.dataDir)
            print("[AppConfigBridge] Data directory reset to default")
        } else {
            // iOS: Only allow setting within app's container
            let appDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            if dir.hasPrefix(appDir) {
                defaults.set(dir, forKey: Keys.dataDir)
                print("[AppConfigBridge] Data directory set to: \(dir)")
            } else {
                print("[AppConfigBridge] Rejected invalid data directory (outside app container): \(dir)")
                throw NSError(domain: "AppConfigBridge", code: -2, 
                            userInfo: [NSLocalizedDescriptionKey: "Data directory must be within app container"])
            }
        }
    }
    
    func isSilentJumpAppEnabled() throws -> Bool {
        return defaults.bool(forKey: Keys.silentJumpApp)
    }
    
    func setSilentJumpAppEnabled(enabled: Bool) throws {
        defaults.set(enabled, forKey: Keys.silentJumpApp)
        print("[AppConfigBridge] Silent jump app enabled: \(enabled)")
    }
}
