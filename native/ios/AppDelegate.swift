import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let storageChannelName = "hourdraft/storage"
  private let storageKeyPrefix = "hourdraft."

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
      )
    }

    let channel = FlutterMethodChannel(
      name: storageChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard
        let arguments = call.arguments as? [String: Any],
        let key = arguments["key"] as? String
      else {
        result(FlutterError(
          code: "INVALID_ARGUMENT",
          message: "A storage key is required.",
          details: nil
        ))
        return
      }

      let fullKey = (self?.storageKeyPrefix ?? "hourdraft.") + key

      switch call.method {
      case "get":
        result(UserDefaults.standard.string(forKey: fullKey))
      case "set":
        guard let value = arguments["value"] as? String else {
          result(FlutterError(
            code: "INVALID_VALUE",
            message: "A string storage value is required.",
            details: nil
          ))
          return
        }
        UserDefaults.standard.set(value, forKey: fullKey)
        result(nil)
      case "remove":
        UserDefaults.standard.removeObject(forKey: fullKey)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}