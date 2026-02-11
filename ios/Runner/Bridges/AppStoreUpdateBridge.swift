import Foundation
import StoreKit
import UIKit
import Flutter

final class AppStoreUpdateBridge: NSObject, SKStoreProductViewControllerDelegate {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
    }

    func checkAndShowUpdate(result: @escaping FlutterResult) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            result(false)
            return
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else {
            result(false)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("[AppStoreUpdateBridge] Apple API error: \(error)")
                result(false)
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let results = json["results"] as? [[String: Any]],
                let first = results.first,
                let latestVersion = first["version"] as? String,
                let trackId = first["trackId"] as? Int
            else {
                result(false)
                return
            }

            let hasUpdate = self?.isVersionNewer(latest: latestVersion, current: currentVersion) ?? false
            if !hasUpdate {
                result(false)
                return
            }

            self?.presentStoreProduct(trackId: trackId) { presented in
                result(presented)
            }
        }.resume()
    }

    private func presentStoreProduct(trackId: Int, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let presenter = self?.viewController ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                completion(false)
                return
            }

            let storeVC = SKStoreProductViewController()
            storeVC.delegate = self
            let parameters = [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: trackId)]
            storeVC.loadProduct(withParameters: parameters) { loaded, error in
                if let error = error {
                    print("[AppStoreUpdateBridge] Failed to load product: \(error)")
                    completion(false)
                    return
                }
                if loaded {
                    presenter.present(storeVC, animated: true) {
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    private func isVersionNewer(latest: String, current: String) -> Bool {
        let latestParts = latest.split(separator: ".").map { Int($0) ?? 0 }
        let currentParts = current.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(latestParts.count, currentParts.count)

        for index in 0..<count {
            let latestValue = index < latestParts.count ? latestParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0
            if latestValue != currentValue {
                return latestValue > currentValue
            }
        }
        return false
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true)
    }
}
