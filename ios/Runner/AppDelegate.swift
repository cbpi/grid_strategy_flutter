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

    let channel = FlutterMethodChannel(
      name: "grid_strategy/signing",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getProvisioningExpiry" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(Self.provisioningExpiryMilliseconds())
    }
  }

  private static func provisioningExpiryMilliseconds() -> Int64? {
    let profileURL = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
    guard let profileData = try? Data(contentsOf: profileURL) else { return nil }
    guard let plistData = embeddedProvisioningPlist(in: profileData),
          let profile = try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
          ) as? [String: Any],
          let expiry = profile["ExpirationDate"] as? Date else { return nil }

    return Int64(expiry.timeIntervalSince1970 * 1000)
  }

  private static func embeddedProvisioningPlist(in data: Data) -> Data? {
    let startMarker = Data("<plist".utf8)
    let endMarker = Data("</plist>".utf8)
    guard let start = data.range(of: startMarker),
          let end = data.range(of: endMarker, in: start.lowerBound..<data.endIndex) else {
      return nil
    }
    return data.subdata(in: start.lowerBound..<end.upperBound)
  }
}
