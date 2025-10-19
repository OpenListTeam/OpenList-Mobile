import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var eventAPI: Event?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
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
    
    // Initialize OpenList core (if XCFramework is available)
    #if canImport(Openlistlib)
    let eventHandler = OpenListEventHandler()
    let logCallback = OpenListLogCallback()
    eventHandler.eventAPI = eventAPI
    logCallback.eventAPI = eventAPI
    
    do {
      try OpenListManager.shared.initialize(event: eventHandler, logger: logCallback)
      print("[AppDelegate] OpenList core initialized")
    } catch {
      print("[AppDelegate] OpenList core initialization failed: \(error)")
      // Continue without core - will work in Flutter-only mode
    }
    #else
    print("[AppDelegate] OpenList core not available - running in Flutter-only mode")
    #endif
    
    print("[AppDelegate] Pigeon APIs registered successfully")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Application Lifecycle
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Cleanup OpenList core
    OpenListManager.shared.stopServer()
    super.applicationWillTerminate(application)
  }
}
