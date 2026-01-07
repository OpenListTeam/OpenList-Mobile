import Foundation
import Openlistlib

/// Manages OpenList core server lifecycle
class OpenListManager: NSObject {
    static let shared = OpenListManager()
    
    private var isInitialized = false
    private var isServerRunning = false
    private var dataDir: String?
    
    // Keep strong references to prevent deallocation
    var eventHandler: OpenListEventHandler?
    var logCallback: OpenListLogCallback?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Initialization
    
    func initialize(event: OpenListEventHandler, logger: OpenListLogCallback) throws {
        guard !isInitialized else {
            print("[OpenListManager] Already initialized")
            return
        }
        
        // Get data directory from AppConfigBridge
        let appConfig = AppConfigBridge()
        let dataDirPath: String
        do {
            dataDirPath = try appConfig.getDataDir()
            self.dataDir = dataDirPath
            print("[OpenListManager] Data directory: \(dataDirPath)")
        } catch {
            print("[OpenListManager] Failed to get data directory: \(error)")
            throw error
        }
        
        // Set data directory for OpenList core (no error return)
        OpenlistlibSetConfigData(dataDirPath)
        
        // Enable stdout logging (no error return)
        OpenlistlibSetConfigLogStd(true)
        
        var error: NSError?
        OpenlistlibInit(event, logger, &error)
        if let err = error {
            print("[OpenListManager] Initialization failed: \(err)")
            throw err
        }
        isInitialized = true
        print("[OpenListManager] Initialized successfully with data directory: \(dataDirPath)")
    }
    
    // MARK: - Server Control
    
    func startServer() {
        print("[OpenListManager] Start server request received")
        
        // Check if initialized, if not, try to initialize first
        if !isInitialized {
            print("[OpenListManager] Not initialized, attempting initialization...")
            let eventHandler = OpenListEventHandler()
            let logCallback = OpenListLogCallback()
            
            // Set event API reference before initialization
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            eventHandler.eventAPI = appDelegate?.eventAPI
            logCallback.eventAPI = appDelegate?.eventAPI
            
            // Store references globally for persistence
            OpenListManager.shared.eventHandler = eventHandler
            OpenListManager.shared.logCallback = logCallback
            
            do {
                try initialize(event: eventHandler, logger: logCallback)
                print("[OpenListManager] Initialization completed, proceeding to start server")
            } catch {
                print("[OpenListManager] Initialization failed: \(error), cannot start server")
                return
            }
        }
        
        guard !isServerRunning else {
            print("[OpenListManager] Server already running")
            return
        }
        
        print("[OpenListManager] Starting OpenList server with data directory: \(dataDir ?? "unknown")...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            OpenlistlibStart()
            
            // Small delay to ensure server is ready
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                self?.isServerRunning = true
                print("[OpenListManager] Server started successfully")
                
                // Notify Flutter side
                if let eventAPI = (UIApplication.shared.delegate as? AppDelegate)?.eventAPI {
                    eventAPI.onServiceStatusChanged(isRunning: true) { result in
                        switch result {
                        case .failure(let error):
                            print("[OpenListManager] Failed to notify Flutter of status change: \(error)")
                        case .success:
                            print("[OpenListManager] Status change notification sent to Flutter")
                        }
                    }
                }
            }
        }
    }
    
    func stopServer(timeout: Int64 = 5000) {
        guard isServerRunning else {
            print("[OpenListManager] Server not running")
            return
        }
        
        print("[OpenListManager] Stopping OpenList server...")
        var error: NSError?
        OpenlistlibShutdown(timeout, &error)
        if let err = error {
            print("[OpenListManager] Failed to stop server: \(err)")
            return
        }
        isServerRunning = false
        print("[OpenListManager] Server stopped")
    }
    
    func isRunning() -> Bool {
        return isServerRunning && OpenlistlibIsRunning("http")
    }
    
    func getHttpPort() -> Int {
        // Default port for OpenList
        return 5244
    }
    
    func forceDBSync() {
        var error: NSError?
        OpenlistlibForceDBSync(&error)
        if let err = error {
            print("[OpenListManager] Database sync failed: \(err)")
            return
        }
        print("[OpenListManager] Database sync completed")
    }
}

// MARK: - Event Handler

class OpenListEventHandler: NSObject, OpenlistlibEventProtocol {
    weak var eventAPI: Event?
    
    func onStartError(_ t: String?, err: String?) {
        print("[OpenListEvent] Start error - Type: \(t ?? "unknown"), Error: \(err ?? "unknown")")
        // Notify Flutter side via Event API if needed
    }
    
    func onShutdown(_ t: String?) {
        print("[OpenListEvent] Shutdown - Type: \(t ?? "unknown")")
        // Notify Flutter side via Event API if needed
    }
    
    func onProcessExit(_ code: Int) {
        print("[OpenListEvent] Process exit - Code: \(code)")
        // Handle process exit if needed
    }
}

// MARK: - Log Callback

class OpenListLogCallback: NSObject, OpenlistlibLogCallbackProtocol {
    weak var eventAPI: Event?
    
    func onLog(_ level: Int16, time: Int64, message: String?) {
        let logMessage = message ?? ""
        print("[OpenListLog] Level: \(level), Message: \(logMessage)")
        
        // Forward logs to Flutter side
        if let api = eventAPI {
            api.onServerLog(level: Int64(level), time: "\(time)", log: logMessage) { result in
                switch result {
                case .failure(let error):
                    print("[OpenListLog] Failed to send log to Flutter: \(error)")
                case .success:
                    break // Success, no action needed
                }
            }
        } else {
            print("[OpenListLog] Warning: eventAPI is nil, cannot forward log to Flutter")
        }
    }
}
