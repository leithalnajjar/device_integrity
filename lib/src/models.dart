/// Data models returned by the [DeviceIntegrity] plugin.
///
/// All tokens returned by these models are opaque blobs that **must be
/// validated on your backend server**, not on the client. The client side
/// only requests the token; verification of signature and claims is the
/// responsibility of your server.
library;

/// Generic result for an integrity / attestation request.
///
/// This is used by:
/// - Google Play Integrity (classic and standard requests)
/// - Huawei SafetyDetect SysIntegrity
/// - Apple DeviceCheck
/// - Apple App Attest (attestation / assertion)
class IntegrityResult {
  /// `true` if the native API returned a token successfully.
  final bool success;

  /// The opaque token returned by the native API.
  ///
  /// - Play Integrity: a signed JWE that decodes (server-side) into the
  ///   verdicts described in the README (account details, app integrity,
  ///   device integrity, recent device activity, device attributes,
  ///   Play Protect status, app access risk, environment details).
  /// - Huawei SysIntegrity: a JWS (JSON Web Signature).
  /// - Apple DeviceCheck: the base64-encoded `DCDevice` token.
  /// - Apple App Attest: the base64-encoded CBOR attestation / assertion
  ///   blob (depending on the call).
  final String? token;

  /// Optional extra metadata returned by the platform (for example the
  /// `keyId` produced by App Attest's `generateKey`).
  final Map<String, dynamic>? metadata;

  /// Human-readable error message if [success] is `false`.
  final String? error;

  /// Native error code / exception class name if [success] is `false`.
  final String? errorCode;

  /// Creates an [IntegrityResult].
  const IntegrityResult({
    required this.success,
    this.token,
    this.metadata,
    this.error,
    this.errorCode,
  });

  /// Builds an [IntegrityResult] from a platform-channel map.
  factory IntegrityResult.fromMap(Map<String, dynamic> map) {
    final raw = map['metadata'];
    final metadata = raw is Map
        ? raw.map((k, v) => MapEntry(k.toString(), v))
        : null;
    return IntegrityResult(
      success: map['success'] as bool? ?? false,
      token: map['token'] as String?,
      metadata: metadata,
      error: map['error'] as String?,
      errorCode: map['errorCode'] as String?,
    );
  }

  @override
  String toString() => success
      ? 'IntegrityResult(success: true, token: ${_short(token)}, metadata: $metadata)'
      : 'IntegrityResult(success: false, error: $error, errorCode: $errorCode)';

  static String _short(String? t) {
    if (t == null) return 'null';
    return t.length > 24 ? '${t.substring(0, 24)}…' : t;
  }
}

/// Threat type returned by Huawei SafetyDetect URL check.
enum UrlThreatType {
  /// Malware site.
  malware,

  /// Phishing site.
  phishing,

  /// Other / unknown threat type.
  other,
}

/// Result of a Huawei SafetyDetect URL check.
class UrlCheckResult {
  /// `true` if the request finished successfully (regardless of whether
  /// threats were found).
  final bool success;

  /// List of threats detected for the requested URL.
  final List<UrlThreatType> threats;

  /// Error message if [success] is `false`.
  final String? error;

  /// Native error code if [success] is `false`.
  final String? errorCode;

  /// Creates a [UrlCheckResult].
  const UrlCheckResult({
    required this.success,
    this.threats = const [],
    this.error,
    this.errorCode,
  });

  /// Builds a [UrlCheckResult] from a platform-channel map.
  factory UrlCheckResult.fromMap(Map<String, dynamic> map) {
    final list = (map['threats'] as List?) ?? const [];
    final threats = list
        .map((e) => (e as num).toInt())
        .map(_threatFromInt)
        .toList(growable: false);
    return UrlCheckResult(
      success: map['success'] as bool? ?? false,
      threats: threats,
      error: map['error'] as String?,
      errorCode: map['errorCode'] as String?,
    );
  }

  static UrlThreatType _threatFromInt(int code) {
    switch (code) {
      case 1:
        return UrlThreatType.malware;
      case 3:
        return UrlThreatType.phishing;
      default:
        return UrlThreatType.other;
    }
  }
}

/// Result of a Huawei SafetyDetect user-detect (reCAPTCHA-style) request.
class UserDetectResult {
  /// `true` if the user passed verification.
  final bool success;

  /// Response token that must be verified server-side.
  final String? responseToken;

  /// Error message if [success] is `false`.
  final String? error;

  /// Native error code if [success] is `false`.
  final String? errorCode;

  /// Creates a [UserDetectResult].
  const UserDetectResult({
    required this.success,
    this.responseToken,
    this.error,
    this.errorCode,
  });

  /// Builds a [UserDetectResult] from a platform-channel map.
  factory UserDetectResult.fromMap(Map<String, dynamic> map) =>
      UserDetectResult(
        success: map['success'] as bool? ?? false,
        responseToken: map['responseToken'] as String?,
        error: map['error'] as String?,
        errorCode: map['errorCode'] as String?,
      );
}

/// Result of a Huawei SafetyDetect Wi-Fi detect request.
class WifiDetectResult {
  /// `true` if the call succeeded.
  final bool success;

  /// Raw Wi-Fi detect status code (see Huawei docs):
  /// - 0: secure
  /// - 1: open / unsecure
  /// - 2: SSL pinning detected
  final int? wifiDetectStatus;

  /// Error message if [success] is `false`.
  final String? error;

  /// Native error code if [success] is `false`.
  final String? errorCode;

  /// Creates a [WifiDetectResult].
  const WifiDetectResult({
    required this.success,
    this.wifiDetectStatus,
    this.error,
    this.errorCode,
  });

  /// Builds a [WifiDetectResult] from a platform-channel map.
  factory WifiDetectResult.fromMap(Map<String, dynamic> map) =>
      WifiDetectResult(
        success: map['success'] as bool? ?? false,
        wifiDetectStatus: (map['wifiDetectStatus'] as num?)?.toInt(),
        error: map['error'] as String?,
        errorCode: map['errorCode'] as String?,
      );
}

/// Description of a malicious app reported by Huawei SafetyDetect.
class MaliciousApp {
  /// Package name of the malicious app.
  final String packageName;

  /// SHA-256 of the APK.
  final String? apkSha256;

  /// Category code (see Huawei docs).
  final int? category;

  /// Creates a [MaliciousApp].
  const MaliciousApp({
    required this.packageName,
    this.apkSha256,
    this.category,
  });

  /// Builds a [MaliciousApp] from a platform-channel map.
  factory MaliciousApp.fromMap(Map<String, dynamic> map) => MaliciousApp(
        packageName: map['packageName']?.toString() ?? '',
        apkSha256: map['apkSha256'] as String?,
        category: (map['category'] as num?)?.toInt(),
      );

  @override
  String toString() =>
      'MaliciousApp(packageName: $packageName, category: $category)';
}

