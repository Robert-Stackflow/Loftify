import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var clipboardChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      clipboardChannel = FlutterMethodChannel(
        name: "loftify/clipboard", binaryMessenger: controller.binaryMessenger)
      clipboardChannel?.setMethodCallHandler { call, result in
        guard call.method == "getMetadata" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result([
          "revision": String(UIPasteboard.general.changeCount),
          "uptimeMs": Int64(ProcessInfo.processInfo.systemUptime * 1000)
        ])
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
