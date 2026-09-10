import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Android answers this in MainActivity. With no handler here, iOS fell
    // back to UTC and scheduled every reminder at the wrong hour.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SnapCalTimeZone") {
      let channel = FlutterMethodChannel(
        name: "snapcal/timezone",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getLocalTimeZone":
          result(TimeZone.current.identifier)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
