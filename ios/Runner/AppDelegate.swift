import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, OpenListEventDelegate, OpenListLogDelegate {
  private var eventAPI: Event?
  private let eventHandler = OpenListEventHandler()
  private let logCallback = OpenListLogCallback()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup event and log delegates
    eventHandler.delegate = self
    logCallback.delegate = self
    
    // Initialize OpenList core (if XCFramework is available)
    do {
      try OpenListManager.shared.initialize(event: eventHandler, logger: logCallback)
      print("[AppDelegate] OpenList core initialized")
    } catch {
      print("[AppDelegate] OpenList core initialization failed: \(error)")
      // Continue without core - will work in Flutter-only mode
    }
    
    // Setup Pigeon APIs
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("[AppDelegate] Failed to get FlutterViewController")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    let messenger = controller.binaryMessenger
    
    // Register Pigeon API implementations
    AppConfigSetup.setUp(binaryMessenger: messenger, api: AppConfigBridge())
    AndroidSetup.setUp(binaryMessenger: messenger, api: OpenListBridge())
    NativeCommonSetup.setUp(binaryMessenger: messenger, api: CommonBridge(viewController: controller))
    
    // Setup Event API for Flutter callbacks
    eventAPI = Event(binaryMessenger: messenger)
    
    print("[AppDelegate] Pigeon APIs registered successfully")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - OpenListEventDelegate
  
  func onStartError(type: String, error: String) {
    print("[AppDelegate] OpenList start error - Type: \(type), Error: \(error)")
    // Notify Flutter side if needed
  }
  
  func onShutdown(type: String) {
    print("[AppDelegate] OpenList shutdown - Type: \(type)")
    // Notify Flutter side if needed
  }
  
  func onProcessExit(code: Int) {
    print("[AppDelegate] OpenList process exit - Code: \(code)")
    // Handle process exit if needed
  }
  
  // MARK: - OpenListLogDelegate
  
  func onLog(level: Int16, time: Int64, message: String) {
    // Forward logs to Flutter side
    eventAPI?.onServerLog(level: Int64(level), time: "\(time)", log: message) { _ in }
  }
  
  // MARK: - Application Lifecycle
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Cleanup OpenList core
    OpenListManager.shared.stopServer()
    super.applicationWillTerminate(application)
  }
}
