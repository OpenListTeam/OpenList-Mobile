import Foundation
import Openlistlib

/// Manages OpenList core server lifecycle
class OpenListManager: NSObject {
    static let shared = OpenListManager()
    
    private var isInitialized = false
    private var isServerRunning = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Initialization
    
    func initialize(event: OpenListEventHandler, logger: OpenListLogCallback) throws {
        guard !isInitialized else {
            print("[OpenListManager] Already initialized")
            return
        }
        
        do {
            try OpenlistlibInit(event, logger)
            isInitialized = true
            print("[OpenListManager] Initialized successfully")
        } catch {
            print("[OpenListManager] Initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Server Control
    
    func startServer() {
        guard isInitialized else {
            print("[OpenListManager] Not initialized, cannot start server")
            return
        }
        
        guard !isServerRunning else {
            print("[OpenListManager] Server already running")
            return
        }
        
        print("[OpenListManager] Starting OpenList server...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            OpenlistlibStart()
            self?.isServerRunning = true
            print("[OpenListManager] Server started")
        }
    }
    
    func stopServer(timeout: Int64 = 5000) {
        guard isServerRunning else {
            print("[OpenListManager] Server not running")
            return
        }
        
        print("[OpenListManager] Stopping OpenList server...")
        do {
            try OpenlistlibShutdown(timeout)
            isServerRunning = false
            print("[OpenListManager] Server stopped")
        } catch {
            print("[OpenListManager] Failed to stop server: \(error)")
        }
    }
    
    func isRunning() -> Bool {
        return isServerRunning && OpenlistlibIsRunning("http")
    }
    
    func getHttpPort() -> Int {
        // Default port for OpenList
        return 5244
    }
    
    func forceDBSync() {
        do {
            try OpenlistlibForceDBSync()
            print("[OpenListManager] Database sync completed")
        } catch {
            print("[OpenListManager] Database sync failed: \(error)")
        }
    }
}

// MARK: - Event Handler

class OpenListEventHandler: NSObject, OpenlistlibEventProtocol {
    weak var delegate: OpenListEventDelegate?
    
    func onStartError(_ t: String?, err: String?) {
        print("[OpenListEvent] Start error - Type: \(t ?? "unknown"), Error: \(err ?? "unknown")")
        delegate?.onStartError(type: t ?? "unknown", error: err ?? "unknown")
    }
    
    func onShutdown(_ t: String?) {
        print("[OpenListEvent] Shutdown - Type: \(t ?? "unknown")")
        delegate?.onShutdown(type: t ?? "unknown")
    }
    
    func onProcessExit(_ code: Int) {
        print("[OpenListEvent] Process exit - Code: \(code)")
        delegate?.onProcessExit(code: code)
    }
}

protocol OpenListEventDelegate: AnyObject {
    func onStartError(type: String, error: String)
    func onShutdown(type: String)
    func onProcessExit(code: Int)
}

// MARK: - Log Callback

class OpenListLogCallback: NSObject, OpenlistlibLogCallbackProtocol {
    weak var delegate: OpenListLogDelegate?
    
    func onLog(_ level: Int16, time: Int64, message: String?) {
        delegate?.onLog(level: level, time: time, message: message ?? "")
    }
}

protocol OpenListLogDelegate: AnyObject {
    func onLog(level: Int16, time: Int64, message: String)
}
