import Flutter
import Foundation

/// Uploads files through a background URLSession so transfers continue while
/// the app is suspended. Only used for remote servers: the embedded core is
/// suspended with the app, so loopback uploads stay on the Dart path.
class UploadBridge: NSObject, UploadApi, URLSessionDataDelegate {
    static let sessionIdentifier = (Bundle.main.bundleIdentifier ?? "openlist") + ".upload"

    private static let maxBodyBytes = 64 * 1024
    private static let progressInterval: TimeInterval = 0.25

    var eventAPI: UploadEventApi?

    /// Completion handler passed to handleEventsForBackgroundURLSession.
    var backgroundCompletionHandler: (() -> Void)?

    // Main-thread only.
    private var tasks: [String: URLSessionTask] = [:]

    // Delegate-queue only.
    private var bodies: [Int: Data] = [:]
    private var lastProgress: [Int: Date] = [:]

    private let delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// Creating the session reattaches tasks left over from a previous launch.
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: UploadBridge.sessionIdentifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        return URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }()

    // MARK: - UploadApi

    func enqueue(request: UploadRequest) throws -> String {
        guard let url = URL(string: request.url), url.scheme == "https" || url.scheme == "http" else {
            throw PigeonError(code: "invalid-url", message: "unsupported upload URL", details: nil)
        }
        let file = URL(fileURLWithPath: request.filePath)
        guard FileManager.default.isReadableFile(atPath: file.path) else {
            throw PigeonError(code: "file-not-found", message: "file not found", details: nil)
        }
        var req = URLRequest(url: url)
        req.httpMethod = request.method
        for (name, value) in request.headers where name.caseInsensitiveCompare("Content-Length") != .orderedSame {
            req.setValue(value, forHTTPHeaderField: name)
        }
        let id = UUID().uuidString
        let task = session.uploadTask(with: req, fromFile: file)
        task.taskDescription = id
        tasks[id] = task
        task.resume()
        return id
    }

    func cancel(id: String) throws {
        if let task = tasks[id] {
            task.cancel()
            return
        }
        // Tasks restored after a relaunch are not in the map.
        session.getAllTasks { all in
            all.first { $0.taskDescription == id }?.cancel()
        }
    }

    // MARK: - URLSessionDataDelegate (delegate queue)

    func urlSession(
        _ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64, totalBytesExpectedToSend: Int64
    ) {
        let now = Date()
        if let last = lastProgress[task.taskIdentifier], now.timeIntervalSince(last) < Self.progressInterval {
            return
        }
        lastProgress[task.taskIdentifier] = now
        emit(task, state: .running, sent: totalBytesSent, total: max(totalBytesExpectedToSend, 0))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        var body = bodies[dataTask.taskIdentifier] ?? Data()
        if body.count < Self.maxBodyBytes {
            body.append(data.prefix(Self.maxBodyBytes - body.count))
            bodies[dataTask.taskIdentifier] = body
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let body = bodies.removeValue(forKey: task.taskIdentifier)
        lastProgress.removeValue(forKey: task.taskIdentifier)
        let sent = task.countOfBytesSent
        let total = max(task.countOfBytesExpectedToSend, 0)
        if let error = error as NSError? {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                emit(task, state: .canceled, sent: sent, total: total)
            } else {
                emit(task, state: .failed, sent: sent, total: total, error: error.localizedDescription)
            }
            return
        }
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let text = body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        emit(task, state: .completed, sent: sent, total: total, status: Int64(status), body: text)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            let handler = self?.backgroundCompletionHandler
            self?.backgroundCompletionHandler = nil
            handler?()
        }
    }

    // MARK: - Events

    private func emit(
        _ task: URLSessionTask, state: UploadEventState, sent: Int64, total: Int64,
        status: Int64 = 0, body: String? = nil, error: String? = nil
    ) {
        guard let id = task.taskDescription else { return }
        let event = UploadEvent(
            id: id, state: state, sent: sent, total: total, httpStatus: status, body: body, error: error)
        let finished = state == .completed || state == .failed || state == .canceled
        DispatchQueue.main.async { [weak self] in
            if finished { self?.tasks.removeValue(forKey: id) }
            self?.eventAPI?.onUploadEvent(event: event) { _ in }
        }
    }
}
