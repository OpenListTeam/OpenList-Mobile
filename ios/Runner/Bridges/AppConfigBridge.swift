import Flutter
import Foundation
import UIKit
import UniformTypeIdentifiers

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

final class DownloadStorageBridge: NSObject, DownloadStorage, UIDocumentPickerDelegate {
    private enum Keys {
        static let selectedDirectory = "openlist.download.selected-directory"
        static let directoryPrefix = "openlist.download.directory."
        static let filePrefix = "openlist.download.file."
        static let defaultDirectory = "directory-default"
    }

    private struct DirectoryHandle {
        let reference: String
        let name: String
        let url: URL
    }

    private struct FileHandleInfo {
        let reference: String
        let directory: DirectoryHandle
        let name: String
        let temporaryName: String
        let url: URL
    }

    private let defaults = UserDefaults.standard
    private var pickerCompletion: ((Result<DownloadDirectory?, Error>) -> Void)?
    private var activeDirectoryURL: URL?

    override init() {
        super.init()
        if let reference = defaults.string(forKey: Keys.selectedDirectory) {
            _ = try? directory(for: reference)
        }
    }

    deinit {
        activeDirectoryURL?.stopAccessingSecurityScopedResource()
    }

    func getDefaultDirectory(completion: @escaping (Result<DownloadDirectory, Error>) -> Void) {
        do {
            let directory: DirectoryHandle
            if let selected = defaults.string(forKey: Keys.selectedDirectory) {
                directory = try self.directory(for: selected)
            } else {
                directory = try defaultDirectory()
            }
            completion(.success(DownloadDirectory(reference: directory.reference, name: directory.name)))
        } catch {
            completion(.failure(error))
        }
    }

    func chooseDirectory(completion: @escaping (Result<DownloadDirectory?, Error>) -> Void) {
        guard pickerCompletion == nil else {
            completion(.failure(PigeonError(code: "picker-busy", message: "A directory picker is already open", details: nil)))
            return
        }
        guard let controller = presentingController() else {
            completion(.failure(PigeonError(code: "picker-unavailable", message: "The directory picker is unavailable", details: nil)))
            return
        }
        pickerCompletion = completion
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        controller.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let completion = pickerCompletion
        pickerCompletion = nil
        guard let url = urls.first else {
            completion?(.success(nil))
            return
        }
        do {
            try activate(url)
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            let reference = "directory-\(UUID().uuidString)"
            let name = url.lastPathComponent.isEmpty ? "Selected folder" : url.lastPathComponent
            defaults.set(bookmark, forKey: directoryKey(reference, "bookmark"))
            defaults.set(name, forKey: directoryKey(reference, "name"))
            defaults.set(reference, forKey: Keys.selectedDirectory)
            completion?(.success(DownloadDirectory(reference: reference, name: name)))
        } catch {
            completion?(.failure(error))
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        let completion = pickerCompletion
        pickerCompletion = nil
        completion?(.success(nil))
    }

    func resetSelectedDirectory(completion: @escaping (Result<Void, Error>) -> Void) {
        activeDirectoryURL?.stopAccessingSecurityScopedResource()
        activeDirectoryURL = nil
        defaults.removeObject(forKey: Keys.selectedDirectory)
        completion(.success(()))
    }

    func reserveFile(directoryReference: String, filename: String, completion: @escaping (Result<DownloadFile, Error>) -> Void) {
        do {
            let directory = try directory(for: directoryReference)
            let requested = try safeFilename(filename)
            let finalName = uniqueName(in: directory, requested: requested)
            let temporaryName = ".openlist-\(UUID().uuidString).part"
            let url = directory.url.appendingPathComponent(temporaryName, isDirectory: false)
            guard FileManager.default.createFile(atPath: url.path, contents: Data()) else {
                throw PigeonError(code: "reserve-failed", message: "Cannot reserve download file", details: nil)
            }
            let reference = "file-\(UUID().uuidString)"
            saveFile(reference: reference, directory: directory.reference, name: finalName, temporaryName: temporaryName)
            completion(.success(try fileInfo(reference: reference, directory: directory, name: finalName, temporaryName: temporaryName, url: url)))
        } catch {
            completion(.failure(error))
        }
    }

    func getFileLength(fileReference: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        do {
            let file = try file(reference: fileReference)
            let attributes = try FileManager.default.attributesOfItem(atPath: file.url.path)
            completion(.success((attributes[.size] as? NSNumber)?.int64Value ?? 0))
        } catch {
            completion(.failure(error))
        }
    }

    func truncateFile(fileReference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        withFileHandle(fileReference: fileReference, completion: completion) { handle in
            try handle.truncate(atOffset: 0)
        }
    }

    func writeFile(fileReference: String, offset: Int64, data: FlutterStandardTypedData, completion: @escaping (Result<Void, Error>) -> Void) {
        guard offset >= 0 else {
            completion(.failure(PigeonError(code: "invalid-offset", message: "File offset must not be negative", details: nil)))
            return
        }
        withFileHandle(fileReference: fileReference, completion: completion) { handle in
            _ = try handle.seek(toOffset: UInt64(offset))
            try handle.write(contentsOf: data.data)
        }
    }

    func flushFile(fileReference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        withFileHandle(fileReference: fileReference, completion: completion) { handle in
            try handle.synchronize()
        }
    }

    func finalizeFile(fileReference: String, completion: @escaping (Result<DownloadFile, Error>) -> Void) {
        do {
            let file = try file(reference: fileReference)
            let finalName = uniqueName(in: file.directory, requested: file.name, ignored: file.temporaryName)
            let destination = file.directory.url.appendingPathComponent(finalName, isDirectory: false)
            try FileManager.default.moveItem(at: file.url, to: destination)
            saveFile(reference: file.reference, directory: file.directory.reference, name: finalName, temporaryName: "")
            completion(.success(try fileInfo(reference: file.reference, directory: file.directory, name: finalName, temporaryName: "", url: destination)))
        } catch {
            completion(.failure(error))
        }
    }

    func discardFile(fileReference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        removeFile(reference: fileReference, completion: completion)
    }

    func getFile(fileReference: String, completion: @escaping (Result<DownloadFile?, Error>) -> Void) {
        do {
            guard let file = try? file(reference: fileReference) else {
                completion(.success(nil))
                return
            }
            guard FileManager.default.fileExists(atPath: file.url.path) else {
                removeFileMetadata(reference: fileReference)
                completion(.success(nil))
                return
            }
            completion(.success(try fileInfo(reference: file.reference, directory: file.directory, name: file.name, temporaryName: file.temporaryName, url: file.url)))
        } catch {
            completion(.failure(error))
        }
    }

    func listFiles(directoryReference: String, completion: @escaping (Result<[DownloadFile], Error>) -> Void) {
        do {
            let directory = try directory(for: directoryReference)
            let urls = try FileManager.default.contentsOfDirectory(
                at: directory.url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsPackageDescendants]
            )
            var files: [DownloadFile] = []
            for url in urls {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true, !url.lastPathComponent.hasPrefix(".openlist-") else { continue }
                let name = url.lastPathComponent
                let existing = existingFileReference(directory: directory.reference, name: name)
                let reference = existing ?? "file-\(UUID().uuidString)"
                if existing == nil {
                    saveFile(reference: reference, directory: directory.reference, name: name, temporaryName: "")
                }
                files.append(try fileInfo(reference: reference, directory: directory, name: name, temporaryName: "", url: url))
            }
            completion(.success(files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteFile(fileReference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        removeFile(reference: fileReference, completion: completion)
    }

    func clearDirectory(directoryReference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let directory = try directory(for: directoryReference)
            let urls = try FileManager.default.contentsOfDirectory(at: directory.url, includingPropertiesForKeys: [.isRegularFileKey], options: [])
            for url in urls {
                if (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                    try FileManager.default.removeItem(at: url)
                }
            }
            for reference in fileReferences(in: directory.reference) {
                removeFileMetadata(reference: reference)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func openFile(fileReference: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let file = try file(reference: fileReference)
            DispatchQueue.main.async {
                UIApplication.shared.open(file.url, options: [:]) { completion(.success($0)) }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func openDirectory(directoryReference: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let directory = try directory(for: directoryReference)
            DispatchQueue.main.async {
                UIApplication.shared.open(directory.url, options: [:]) { completion(.success($0)) }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func presentingController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if !scenes.isEmpty {
            let activeScenes = scenes.filter { $0.activationState == .foregroundActive }
            let candidates = activeScenes.isEmpty ? scenes : activeScenes
            let window = candidates.compactMap { $0.windows.first(where: { $0.isKeyWindow }) ?? $0.windows.first }.first
            return window?.rootViewController
        }
        // Legacy app-delegate lifecycle (no scene manifest).
        let delegateWindow = UIApplication.shared.delegate?.window ?? nil
        return delegateWindow?.rootViewController
    }

    private func defaultDirectory() throws -> DirectoryHandle {
        let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads/OpenList", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return DirectoryHandle(reference: Keys.defaultDirectory, name: "OpenList", url: url)
    }

    private func directory(for reference: String) throws -> DirectoryHandle {
        if reference == Keys.defaultDirectory { return try defaultDirectory() }
        guard defaults.data(forKey: directoryKey(reference, "bookmark")) != nil else {
            throw PigeonError(code: "directory-not-found", message: "Download directory not found", details: nil)
        }
        let url = try bookmarkURL(reference: reference)
        try activate(url)
        let name = defaults.string(forKey: directoryKey(reference, "name")) ?? url.lastPathComponent
        return DirectoryHandle(reference: reference, name: name, url: url)
    }

    private func bookmarkURL(reference: String) throws -> URL {
        guard let data = defaults.data(forKey: directoryKey(reference, "bookmark")) else {
            throw PigeonError(code: "directory-not-found", message: "Download directory not found", details: nil)
        }
        let (url, stale) = try bookmarkURL(data: data)
        if stale {
            guard url.startAccessingSecurityScopedResource() else {
                throw PigeonError(code: "directory-access-denied", message: "Download directory permission was revoked", details: nil)
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let refreshed = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(refreshed, forKey: directoryKey(reference, "bookmark"))
        }
        return url
    }

    private func bookmarkURL(data: Data) throws -> (URL, Bool) {
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
        return (url, stale)
    }

    private func activate(_ url: URL) throws {
        if activeDirectoryURL?.path == url.path { return }
        activeDirectoryURL?.stopAccessingSecurityScopedResource()
        guard url.startAccessingSecurityScopedResource() else {
            throw PigeonError(code: "directory-access-denied", message: "Download directory permission was revoked", details: nil)
        }
        activeDirectoryURL = url
    }

    private func file(reference: String) throws -> FileHandleInfo {
        guard let directoryReference = defaults.string(forKey: fileKey(reference, "directory")),
              let name = defaults.string(forKey: fileKey(reference, "name")) else {
            throw PigeonError(code: "file-not-found", message: "Download file not found", details: nil)
        }
        let temporaryName = defaults.string(forKey: fileKey(reference, "temporary")) ?? ""
        let directory = try directory(for: directoryReference)
        let currentName = temporaryName.isEmpty ? name : temporaryName
        return FileHandleInfo(reference: reference, directory: directory, name: name, temporaryName: temporaryName, url: directory.url.appendingPathComponent(currentName, isDirectory: false))
    }

    private func safeFilename(_ filename: String) throws -> String {
        let name = filename.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .filter { $0.unicodeScalars.allSatisfy { $0.value >= 0x20 } }
        guard !name.isEmpty, name != ".", name != ".." else {
            throw PigeonError(code: "invalid-filename", message: "Invalid download filename", details: nil)
        }
        return name
    }

    private func uniqueName(in directory: DirectoryHandle, requested: String, ignored: String? = nil) -> String {
        var candidate = requested
        var index = 1
        while candidate != ignored && FileManager.default.fileExists(atPath: directory.url.appendingPathComponent(candidate).path) {
            let dot = candidate.lastIndex(of: ".")
            let stem = dot.map { String(candidate[..<$0]) } ?? candidate
            let extensionPart = dot.map { String(candidate[$0...]) } ?? ""
            candidate = "\(stem)_\(index)\(extensionPart)"
            index += 1
        }
        return candidate
    }

    private func fileInfo(reference: String, directory: DirectoryHandle, name: String, temporaryName: String, url: URL) throws -> DownloadFile {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        var mime: String?
        if let type = UTType(filenameExtension: url.pathExtension),
           let value = type.preferredMIMEType {
            mime = value
        }
        return DownloadFile(reference: reference, directoryReference: directory.reference, name: name, size: size, modifiedAt: Int64(modified * 1000), mimeType: mime)
    }

    private func withFileHandle(fileReference: String, completion: @escaping (Result<Void, Error>) -> Void, operation: (FileHandle) throws -> Void) {
        do {
            let file = try file(reference: fileReference)
            let handle: FileHandle
            do {
                handle = try FileHandle(forUpdating: file.url)
            } catch {
                throw PigeonError(code: "file-open-failed", message: "Cannot open download file", details: nil)
            }
            defer { try? handle.close() }
            try operation(handle)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    private func removeFile(reference: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            if let file = try? file(reference: reference), FileManager.default.fileExists(atPath: file.url.path) {
                try FileManager.default.removeItem(at: file.url)
            }
            removeFileMetadata(reference: reference)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    private func saveFile(reference: String, directory: String, name: String, temporaryName: String) {
        defaults.set(directory, forKey: fileKey(reference, "directory"))
        defaults.set(name, forKey: fileKey(reference, "name"))
        defaults.set(temporaryName, forKey: fileKey(reference, "temporary"))
    }

    private func removeFileMetadata(reference: String) {
        ["directory", "name", "temporary"].forEach { defaults.removeObject(forKey: fileKey(reference, $0)) }
    }

    private func existingFileReference(directory: String, name: String) -> String? {
        defaults.dictionaryRepresentation().keys.compactMap { key -> String? in
            guard key.hasPrefix(Keys.filePrefix), key.hasSuffix(".directory") else { return nil }
            let reference = String(key.dropFirst(Keys.filePrefix.count).dropLast(".directory".count))
            guard defaults.string(forKey: key) == directory,
                  defaults.string(forKey: fileKey(reference, "name")) == name,
                  (defaults.string(forKey: fileKey(reference, "temporary")) ?? "").isEmpty else { return nil }
            return reference
        }.first
    }

    private func fileReferences(in directory: String) -> [String] {
        defaults.dictionaryRepresentation().keys.compactMap { key in
            guard key.hasPrefix(Keys.filePrefix), key.hasSuffix(".directory") else { return nil }
            let reference = String(key.dropFirst(Keys.filePrefix.count).dropLast(".directory".count))
            return defaults.string(forKey: key) == directory ? reference : nil
        }
    }

    private func directoryKey(_ reference: String, _ suffix: String) -> String {
        "\(Keys.directoryPrefix)\(reference).\(suffix)"
    }

    private func fileKey(_ reference: String, _ suffix: String) -> String {
        "\(Keys.filePrefix)\(reference).\(suffix)"
    }
}
