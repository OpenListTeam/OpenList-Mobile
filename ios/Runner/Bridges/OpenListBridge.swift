import Flutter
import Foundation

/// Bridge implementation for Android-specific APIs (iOS equivalent) and the
/// shared server runtime API.
class OpenListBridge: NSObject, Android, ServerApi {
    private let registrar: FlutterPluginRegistrar?

    init(registrar: FlutterPluginRegistrar? = nil) {
        self.registrar = registrar
        super.init()
    }

    // MARK: - Android (legacy)

    func addShortcut() throws {
        // iOS has no launcher shortcut equivalent; no-op.
    }

    func startService() throws {
        OpenListManager.shared.startServer()
    }

    func getOpenListHttpPort() throws -> Int64 {
        return OpenListManager.shared.status().httpPort
    }

    func isRunning() throws -> Bool {
        return OpenListManager.shared.isRunning()
    }

    func getOpenListVersion() throws -> String {
        return Bundle.main.infoDictionary?["OpenListVersion"] as? String ?? "dev"
    }

    // MARK: - ServerApi

    private static func complete(_ completion: @escaping (Result<Void, Error>) -> Void) -> (Error?) -> Void {
        return { error in completion(error.map { .failure($0) } ?? .success(())) }
    }

    func start(completion: @escaping (Result<Void, Error>) -> Void) {
        OpenListManager.shared.startServer(completion: Self.complete(completion))
    }

    func stop(completion: @escaping (Result<Void, Error>) -> Void) {
        OpenListManager.shared.stopServer(completion: Self.complete(completion))
    }

    func restart(completion: @escaping (Result<Void, Error>) -> Void) {
        OpenListManager.shared.restartServer(completion: Self.complete(completion))
    }

    func getStatus(completion: @escaping (Result<ServerStatus, Error>) -> Void) {
        completion(.success(OpenListManager.shared.status()))
    }

    func getMode() throws -> String {
        return OpenListManager.shared.mode
    }

    func setMode(mode: String) throws {
        // Applied on the next start.
        OpenListManager.shared.mode = mode
    }

    func setAdminPassword(pwd: String, completion: @escaping (Result<Void, Error>) -> Void) {
        OpenListManager.shared.setAdminPassword(pwd, completion: Self.complete(completion))
    }

    func getLocalToken(completion: @escaping (Result<String, Error>) -> Void) {
        OpenListManager.shared.adminToken(completion: completion)
    }

    func getRuntimeStatus(completion: @escaping (Result<String, Error>) -> Void) {
        OpenListManager.shared.runtimeStatus { completion(.success($0)) }
    }

    func getSecurityReport(mode: String, completion: @escaping (Result<String, Error>) -> Void) {
        OpenListManager.shared.securityReport(mode: mode, completion: completion)
    }

    func getRecentLogs(completion: @escaping (Result<[LogEntry], Error>) -> Void) {
        completion(.success(OpenListManager.shared.recentLogs()))
    }
}
