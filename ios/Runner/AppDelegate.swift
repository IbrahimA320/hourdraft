import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let storageChannelName = "hourdraft/storage"
  private let launcherChannelName = "com.example.app/launcher"
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

    // MARK: - Storage channel

    let storageChannel = FlutterMethodChannel(
      name: storageChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    storageChannel.setMethodCallHandler { [weak self] call, result in
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

    // MARK: - URL launcher channel

    let launcherChannel = FlutterMethodChannel(
      name: launcherChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    launcherChannel.setMethodCallHandler { call, result in
      guard call.method == "openUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let urlString = arguments["url"] as? String,
        let url = URL(string: urlString)
      else {
        result(FlutterError(
          code: "INVALID_URL",
          message: "A valid URL is required.",
          details: nil
        ))
        return
      }

      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}