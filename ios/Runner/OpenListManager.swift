import Foundation
import Openlistlib
import UIKit

/// Manages the in-process OpenList core on iOS.
///
/// iOS suspends the app in the background, so the server only runs while the
/// app is active or inside a short background task; it is never promised to
/// keep running. All core calls are serialized on `coreQueue`.
class OpenListManager: NSObject {
    static let shared = OpenListManager()

    static let modeLocal = "local"
    static let modeLan = "lan"
    static let modePublic = "public"
    private static let modeKey = "server_exposure_mode"
    private static let maxLogs = 300

    private let coreQueue = DispatchQueue(label: "openlist.core")
    private let stateLock = NSLock()
    private var isInitialized = false
    private var isServerRunning = false
    private var runningMode: String?
    private var lastError: String?
    private var logs: [LogEntry] = []
    private var dataDir: String?

    // Keep strong references to prevent deallocation
    var eventHandler: OpenListEventHandler?
    var logCallback: OpenListLogCallback?

    private override init() {
        super.init()
    }

    // MARK: - Initialization

    private func ensureInitialized() throws {
        if isInitialized {
            return
        }
        let eventHandler = OpenListEventHandler()
        let logCallback = OpenListLogCallback()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        eventHandler.eventAPI = appDelegate?.eventAPI
        logCallback.eventAPI = appDelegate?.eventAPI
        self.eventHandler = eventHandler
        self.logCallback = logCallback
        try initialize(event: eventHandler, logger: logCallback)
    }

    func initialize(event: OpenListEventHandler, logger: OpenListLogCallback) throws {
        guard !isInitialized else {
            print("[OpenListManager] Already initialized")
            return
        }
        self.eventHandler = event
        self.logCallback = logger

        let dataDirPath = try AppConfigBridge().getDataDir()
        self.dataDir = dataDirPath
        OpenlistlibSetConfigData(dataDirPath)
        OpenlistlibSetConfigLogStd(true)

        var error: NSError?
        OpenlistlibInit(event, logger, &error)
        if let err = error {
            print("[OpenListManager] Initialization failed: \(err)")
            throw err
        }
        isInitialized = true
        print("[OpenListManager] Initialized with data directory: \(dataDirPath)")
    }

    // MARK: - Exposure mode

    /// Defaults to loopback-only. Existing installs keep LAN so an update does
    /// not cut off clients that already relied on the old 0.0.0.0 default.
    var mode: String {
        get {
            if let m = UserDefaults.standard.string(forKey: Self.modeKey) {
                return Self.normalize(m)
            }
            let dir = (try? AppConfigBridge().getDataDir()) ?? ""
            let existing = FileManager.default.fileExists(atPath: (dir as NSString).appendingPathComponent("config.json"))
            let m = existing ? Self.modeLan : Self.modeLocal
            UserDefaults.standard.set(m, forKey: Self.modeKey)
            return m
        }
        set {
            UserDefaults.standard.set(Self.normalize(newValue), forKey: Self.modeKey)
        }
    }

    static func normalize(_ mode: String) -> String {
        return mode == modeLan || mode == modePublic ? mode : modeLocal
    }

    // MARK: - Server control

    func startServer(completion: ((Error?) -> Void)? = nil) {
        coreQueue.async { [weak self] in
            guard let self = self else { return }
            var failure: Error?
            do {
                try self.ensureInitialized()
                if !self.isRunning() {
                    let mode = self.mode
                    let options = "{\"mode\":\"\(mode)\"}"
                    var error: NSError?
                    OpenlistlibStartWithOptions(options, &error)
                    if let err = error {
                        throw err
                    }
                    self.setState(running: OpenlistlibIsRunning(""), mode: mode, error: nil)
                    print("[OpenListManager] Server started, mode=\(mode)")
                }
            } catch {
                print("[OpenListManager] Start failed: \(error)")
                failure = error
                self.setState(running: false, mode: nil, error: error.localizedDescription)
            }
            self.notifyStatus()
            DispatchQueue.main.async { completion?(failure) }
        }
    }

    func stopServer(timeout: Int64 = 5000, completion: ((Error?) -> Void)? = nil) {
        coreQueue.async { [weak self] in
            guard let self = self else { return }
            let failure = self.shutdownLocked(timeout: timeout)
            self.notifyStatus()
            DispatchQueue.main.async { completion?(failure) }
        }
    }

    /// Blocking stop for app termination.
    func stopServerSync(timeout: Int64 = 5000) {
        coreQueue.sync { _ = shutdownLocked(timeout: timeout) }
    }

    private func shutdownLocked(timeout: Int64) -> Error? {
        guard isInitialized, OpenlistlibIsRunning("") else {
            setState(running: false, mode: nil, error: nil)
            return nil
        }
        var error: NSError?
        OpenlistlibForceDBSync(&error)
        error = nil
        OpenlistlibShutdown(timeout, &error)
        if let err = error {
            print("[OpenListManager] Failed to stop server: \(err)")
            setState(running: OpenlistlibIsRunning(""), mode: runningMode, error: err.localizedDescription)
            return err
        }
        setState(running: false, mode: nil, error: nil)
        print("[OpenListManager] Server stopped")
        return nil
    }

    func restartServer(completion: ((Error?) -> Void)? = nil) {
        stopServer { [weak self] _ in self?.startServer(completion: completion) }
    }

    /// Called by the core's shutdown/start-error hooks on any thread.
    func handleCoreStopped(error: String?) {
        coreQueue.async { [weak self] in
            guard let self = self else { return }
            if !OpenlistlibIsRunning("") {
                self.setState(running: false, mode: nil, error: error)
            } else if let error = error {
                self.stateLock.lock()
                self.lastError = error
                self.stateLock.unlock()
            }
            self.notifyStatus()
        }
    }

    private func setState(running: Bool, mode: String?, error: String?) {
        stateLock.lock()
        isServerRunning = running
        runningMode = running ? mode : nil
        lastError = error
        stateLock.unlock()
    }

    func isRunning() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return isServerRunning && isInitialized && OpenlistlibIsRunning("")
    }

    // MARK: - Status

    func status() -> ServerStatus {
        stateLock.lock()
        let running = isServerRunning
        let mode = runningMode ?? self.mode
        let error = lastError
        stateLock.unlock()

        let scheme = readScheme()
        let pinned = scheme.address.isEmpty || scheme.address == "0.0.0.0" || scheme.address == "::" ? nil : scheme.address
        let addresses: [String]
        if mode == Self.modeLocal {
            addresses = ["127.0.0.1"]
        } else if let pinned = pinned {
            addresses = [pinned]
        } else {
            addresses = Self.localIPv4Addresses() + ["127.0.0.1"]
        }
        return ServerStatus(
            running: running,
            mode: mode,
            httpPort: Int64(scheme.httpPort),
            httpsPort: Int64(scheme.httpsPort),
            forceHttps: scheme.forceHttps,
            addresses: addresses,
            manuallyStopped: false,
            lastError: error
        )
    }

    private struct Scheme {
        var address = ""
        var httpPort = 5244
        var httpsPort = -1
        var forceHttps = false
    }

    private func readScheme() -> Scheme {
        var s = Scheme()
        guard let dir = dataDir ?? (try? AppConfigBridge().getDataDir()),
              let data = FileManager.default.contents(atPath: (dir as NSString).appendingPathComponent("config.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let scheme = json["scheme"] as? [String: Any]
        else {
            return s
        }
        s.address = scheme["address"] as? String ?? ""
        s.httpPort = scheme["http_port"] as? Int ?? s.httpPort
        s.httpsPort = scheme["https_port"] as? Int ?? s.httpsPort
        s.forceHttps = scheme["force_https"] as? Bool ?? false
        return s
    }

    private static func localIPv4Addresses() -> [String] {
        var result: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return result }
        defer { freeifaddrs(ifaddr) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard let addr = ptr.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_INET),
                  flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0
            else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: host)
                if !result.contains(ip) { result.append(ip) }
            }
        }
        return result
    }

    private func notifyStatus() {
        let s = status()
        DispatchQueue.main.async {
            guard let api = (UIApplication.shared.delegate as? AppDelegate)?.eventAPI else { return }
            api.onServiceStatusChanged(isRunning: s.running) { _ in }
            api.onServerStatus(status: s) { _ in }
        }
    }

    // MARK: - Logs

    func appendLog(_ entry: LogEntry) {
        stateLock.lock()
        logs.append(entry)
        if logs.count > Self.maxLogs {
            logs.removeFirst(logs.count - Self.maxLogs)
        }
        stateLock.unlock()
    }

    func recentLogs() -> [LogEntry] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return logs
    }

    // MARK: - Core queries

    func setAdminPassword(_ pwd: String, completion: @escaping (Error?) -> Void) {
        coreQueue.async { [weak self] in
            var failure: Error?
            do {
                guard let self = self else { return }
                guard !pwd.isEmpty else {
                    throw PigeonError(code: "server", message: "password is empty", details: nil)
                }
                try self.ensureInitialized()
                if let dataDir = self.dataDir {
                    OpenlistlibSetConfigData(dataDir)
                }
                OpenlistlibSetAdminPassword(pwd)
            } catch {
                failure = error
            }
            DispatchQueue.main.async { completion(failure) }
        }
    }

    func adminToken(completion: @escaping (Result<String, Error>) -> Void) {
        coreQueue.async { [weak self] in
            let result: Result<String, Error>
            if self?.isRunning() != true {
                result = .failure(PigeonError(code: "server", message: "server is not running", details: nil))
            } else {
                var error: NSError?
                // gomobile string returns may import as optional.
                let token: String? = OpenlistlibAdminToken(&error)
                result = error.map { .failure($0) } ?? .success(token ?? "")
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func runtimeStatus(completion: @escaping (String) -> Void) {
        coreQueue.async { [weak self] in
            var json = "{\"running\":false}"
            if self?.isRunning() == true {
                let s: String? = OpenlistlibRuntimeStatus()
                json = s ?? json
            }
            DispatchQueue.main.async { completion(json) }
        }
    }

    func securityReport(mode: String, completion: @escaping (Result<String, Error>) -> Void) {
        coreQueue.async { [weak self] in
            let result: Result<String, Error>
            do {
                try self?.ensureInitialized()
                let report: String? = OpenlistlibSecurityReport(Self.normalize(mode))
                result = .success(report ?? "")
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func forceDBSync() {
        coreQueue.async {
            var error: NSError?
            OpenlistlibForceDBSync(&error)
            if let err = error {
                print("[OpenListManager] Database sync failed: \(err)")
            }
        }
    }
}

// MARK: - Event Handler

class OpenListEventHandler: NSObject, OpenlistlibEventProtocol {
    weak var eventAPI: Event?

    func onStartError(_ t: String?, err: String?) {
        print("[OpenListEvent] Start error - Type: \(t ?? "unknown"), Error: \(err ?? "unknown")")
        OpenListManager.shared.handleCoreStopped(error: "\(t ?? "core"): \(err ?? "unknown")")
    }

    func onShutdown(_ t: String?) {
        print("[OpenListEvent] Shutdown - Type: \(t ?? "unknown")")
        OpenListManager.shared.handleCoreStopped(error: nil)
    }

    func onProcessExit(_ code: Int) {
        print("[OpenListEvent] Process exit - Code: \(code)")
    }
}

// MARK: - Log Callback

class OpenListLogCallback: NSObject, OpenlistlibLogCallbackProtocol {
    weak var eventAPI: Event?

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm:ss"
        return f
    }()

    func onLog(_ level: Int16, time: Int64, message: String?) {
        let text = String((message ?? "").prefix(1000))
        let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000)
        let timeStr = Self.formatter.string(from: date)
        OpenListManager.shared.appendLog(LogEntry(level: Int64(level), time: timeStr, message: text))

        DispatchQueue.main.async { [weak self] in
            self?.eventAPI?.onServerLog(level: Int64(level), time: timeStr, log: text) { _ in }
        }
    }
}
