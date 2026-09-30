import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var clipboardChannel: FlutterMethodChannel?
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    clipboardChannel = FlutterMethodChannel(
      name: "loftify/clipboard", binaryMessenger: flutterViewController.engine.binaryMessenger)
    clipboardChannel?.setMethodCallHandler { call, result in
      guard call.method == "getMetadata" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result([
        "revision": String(NSPasteboard.general.changeCount),
        "uptimeMs": Int64(ProcessInfo.processInfo.systemUptime * 1000)
      ])
    }

    super.awakeFromNib()
  }
}
