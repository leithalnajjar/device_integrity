import Flutter
import UIKit
import DeviceCheck

/// Native bridge for Apple DeviceCheck (`DCDevice`) and App Attest
/// (`DCAppAttestService`). All Android-only methods respond gracefully.
public class DeviceIntegrityPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "device_integrity",
      binaryMessenger: registrar.messenger()
    )
    let instance = DeviceIntegrityPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // ------------------------------------------------------------------
    // DeviceCheck
    // ------------------------------------------------------------------
    case "isDeviceCheckSupported":
      result(DCDevice.current.isSupported)

    case "deviceCheckToken":
      guard DCDevice.current.isSupported else {
        result(Self.failure("DCDevice is not supported on this device.",
                            code: "UNSUPPORTED"))
        return
      }
      DCDevice.current.generateToken { data, error in
        if let error = error {
          result(Self.failure(error.localizedDescription,
                              code: String(describing: type(of: error))))
          return
        }
        guard let data = data else {
          result(Self.failure("Empty DeviceCheck token", code: "EMPTY_TOKEN"))
          return
        }
        result(Self.success(token: data.base64EncodedString()))
      }

    // ------------------------------------------------------------------
    // App Attest
    // ------------------------------------------------------------------
    case "isAppAttestSupported":
      if #available(iOS 14.0, *) {
        result(DCAppAttestService.shared.isSupported)
      } else {
        result(false)
      }

    case "appAttestGenerateKey":
      if #available(iOS 14.0, *) {
        let svc = DCAppAttestService.shared
        guard svc.isSupported else {
          result(Self.failure("App Attest is not supported.", code: "UNSUPPORTED"))
          return
        }
        svc.generateKey { keyId, error in
          if let error = error {
            result(Self.failure(error.localizedDescription,
                                code: String(describing: type(of: error))))
            return
          }
          result(Self.success(token: keyId))
        }
      } else {
        result(Self.failure("App Attest requires iOS 14+", code: "UNSUPPORTED_OS"))
      }

    case "appAttestAttestKey":
      if #available(iOS 14.0, *) {
        guard
          let args = call.arguments as? [String: Any],
          let keyId = args["keyId"] as? String,
          let clientDataHashB64 = args["clientDataHash"] as? String,
          let hash = Data(base64Encoded: clientDataHashB64)
        else {
          result(Self.failure("keyId and clientDataHash (base64) are required.",
                              code: "INVALID_ARGUMENT"))
          return
        }
        DCAppAttestService.shared.attestKey(keyId, clientDataHash: hash) { object, error in
          if let error = error {
            result(Self.failure(error.localizedDescription,
                                code: String(describing: type(of: error))))
            return
          }
          guard let object = object else {
            result(Self.failure("Empty attestation object", code: "EMPTY_TOKEN"))
            return
          }
          result(Self.success(
            token: object.base64EncodedString(),
            metadata: ["keyId": keyId]
          ))
        }
      } else {
        result(Self.failure("App Attest requires iOS 14+", code: "UNSUPPORTED_OS"))
      }

    case "appAttestGenerateAssertion":
      if #available(iOS 14.0, *) {
        guard
          let args = call.arguments as? [String: Any],
          let keyId = args["keyId"] as? String,
          let clientDataHashB64 = args["clientDataHash"] as? String,
          let hash = Data(base64Encoded: clientDataHashB64)
        else {
          result(Self.failure("keyId and clientDataHash (base64) are required.",
                              code: "INVALID_ARGUMENT"))
          return
        }
        DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: hash) { object, error in
          if let error = error {
            result(Self.failure(error.localizedDescription,
                                code: String(describing: type(of: error))))
            return
          }
          guard let object = object else {
            result(Self.failure("Empty assertion object", code: "EMPTY_TOKEN"))
            return
          }
          result(Self.success(
            token: object.base64EncodedString(),
            metadata: ["keyId": keyId]
          ))
        }
      } else {
        result(Self.failure("App Attest requires iOS 14+", code: "UNSUPPORTED_OS"))
      }

    // ------------------------------------------------------------------
    // Android-only methods – return graceful failure on iOS.
    // ------------------------------------------------------------------
    case "playIntegrityToken",
         "playIntegrityStandardToken",
         "huaweiSysIntegrity",
         "huaweiUrlCheck",
         "huaweiUserDetect",
         "huaweiWifiDetect":
      result(Self.failure(
        "\(call.method) is only available on Android.",
        code: "UNSUPPORTED_PLATFORM"
      ))

    case "prepareStandardIntegrityToken":
      result(nil) // no-op on iOS

    case "huaweiEnableAppsCheck", "huaweiIsVerifyAppsCheck":
      result(false)

    case "huaweiGetMaliciousAppsList":
      result([] as [Any])

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Helpers

  private static func success(token: String?,
                              metadata: [String: Any]? = nil) -> [String: Any] {
    var map: [String: Any] = ["success": true]
    if let token = token { map["token"] = token }
    if let metadata = metadata { map["metadata"] = metadata }
    return map
  }

  private static func failure(_ message: String, code: String) -> [String: Any] {
    return [
      "success": false,
      "error": message,
      "errorCode": code,
    ]
  }
}
