/**
 * DeviceIntegrityChecker
 *
 * Native bridge for Google Play Integrity (classic + standard) and the full
 * Huawei SafetyDetect surface (SysIntegrity, URL check, User Detect,
 * Wi-Fi Detect, AppsCheck).
 */
package net.anatech.device_integrity;

import android.content.Context;

import androidx.annotation.NonNull;

import com.google.android.play.core.integrity.IntegrityManager;
import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.IntegrityTokenRequest;
import com.google.android.play.core.integrity.StandardIntegrityManager;
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityToken;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest;

import com.huawei.hms.support.api.entity.safetydetect.MaliciousAppsData;
import com.huawei.hms.support.api.entity.safetydetect.MaliciousAppsListResp;
import com.huawei.hms.support.api.entity.safetydetect.UrlCheckResponse;
import com.huawei.hms.support.api.entity.safetydetect.UrlCheckThreat;
import com.huawei.hms.support.api.entity.safetydetect.VerifyAppsCheckEnabledResp;
import com.huawei.hms.support.api.entity.safetydetect.WifiDetectResponse;
import com.huawei.hms.support.api.safetydetect.SafetyDetect;
import com.huawei.hms.support.api.safetydetect.SafetyDetectClient;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class DeviceIntegrityChecker implements MethodChannel.MethodCallHandler {

    public static final String CHANNEL_NAME = "device_integrity";

    private final Context context;
    private StandardIntegrityTokenProvider standardProvider;

    public DeviceIntegrityChecker(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "playIntegrityToken":
                checkPlayIntegrity(call.argument("nonce"), call.argument("cloudProjectNumber"), result);
                break;
            case "prepareStandardIntegrityToken":
                prepareStandardIntegrity(call.argument("cloudProjectNumber"), result);
                break;
            case "playIntegrityStandardToken":
                playIntegrityStandard(call.argument("requestHash"), result);
                break;
            case "huaweiSysIntegrity":
                checkHuaweiSysIntegrity(call.argument("nonce"), call.argument("appId"), result);
                break;
            case "huaweiUrlCheck":
                huaweiUrlCheck(call.argument("url"), call.argument("appId"),
                        call.argument("threatTypes"), result);
                break;
            case "huaweiUserDetect":
                huaweiUserDetect(call.argument("appId"), result);
                break;
            case "huaweiWifiDetect":
                huaweiWifiDetect(result);
                break;
            case "huaweiEnableAppsCheck":
                huaweiEnableAppsCheck(result);
                break;
            case "huaweiIsVerifyAppsCheck":
                huaweiIsVerifyAppsCheck(result);
                break;
            case "huaweiGetMaliciousAppsList":
                huaweiGetMaliciousAppsList(result);
                break;
            // iOS-only methods: respond gracefully on Android.
            case "isDeviceCheckSupported":
            case "isAppAttestSupported":
                result.success(false);
                break;
            case "deviceCheckToken":
            case "appAttestGenerateKey":
            case "appAttestAttestKey":
            case "appAttestGenerateAssertion":
                result.success(failure("Apple APIs are not available on Android.",
                        "UNSUPPORTED_PLATFORM"));
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    // ---------------------------------------------------------------
    // Google Play Integrity
    // ---------------------------------------------------------------

    private void checkPlayIntegrity(String nonce, String cloudProjectNumber,
                                    @NonNull MethodChannel.Result result) {
        try {
            IntegrityManager manager = IntegrityManagerFactory.create(context);
            IntegrityTokenRequest.Builder builder = IntegrityTokenRequest.builder()
                    .setNonce(nonce != null ? nonce : generateNonce());
            if (cloudProjectNumber != null && !cloudProjectNumber.isEmpty()) {
                builder.setCloudProjectNumber(Long.parseLong(cloudProjectNumber));
            }
            manager.requestIntegrityToken(builder.build())
                    .addOnSuccessListener(resp -> result.success(success(resp.token(), null)))
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    private void prepareStandardIntegrity(String cloudProjectNumber,
                                          @NonNull MethodChannel.Result result) {
        try {
            if (cloudProjectNumber == null || cloudProjectNumber.isEmpty()) {
                result.error("INVALID_ARGUMENT", "cloudProjectNumber is required", null);
                return;
            }
            StandardIntegrityManager manager =
                    IntegrityManagerFactory.createStandard(context);
            manager.prepareIntegrityToken(
                    PrepareIntegrityTokenRequest.builder()
                            .setCloudProjectNumber(Long.parseLong(cloudProjectNumber))
                            .build())
                    .addOnSuccessListener(provider -> {
                        standardProvider = provider;
                        result.success(null);
                    })
                    .addOnFailureListener(e -> result.error(
                            e.getClass().getSimpleName(), e.getMessage(), null));
        } catch (Exception e) {
            result.error(e.getClass().getSimpleName(), e.getMessage(), null);
        }
    }

    private void playIntegrityStandard(String requestHash,
                                       @NonNull MethodChannel.Result result) {
        if (standardProvider == null) {
            result.success(failure(
                    "Call prepareStandardIntegrityToken() before requesting a token.",
                    "PROVIDER_NOT_PREPARED"));
            return;
        }
        try {
            StandardIntegrityTokenRequest.Builder builder =
                    StandardIntegrityTokenRequest.builder();
            if (requestHash != null && !requestHash.isEmpty()) {
                builder.setRequestHash(requestHash);
            }
            standardProvider.request(builder.build())
                    .addOnSuccessListener((StandardIntegrityToken token) ->
                            result.success(success(token.token(), null)))
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    // ---------------------------------------------------------------
    // Huawei SafetyDetect
    // ---------------------------------------------------------------

    private void checkHuaweiSysIntegrity(String nonce, String appId,
                                         @NonNull MethodChannel.Result result) {
        try {
            byte[] nonceBytes = nonce != null && !nonce.isEmpty()
                    ? nonce.getBytes() : generateNonceBytes();
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.sysIntegrity(nonceBytes, appId != null ? appId : "")
                    .addOnSuccessListener(resp ->
                            result.success(success(resp.getResult(), null)))
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    @SuppressWarnings("unchecked")
    private void huaweiUrlCheck(String url, String appId, Object threatTypesRaw,
                                @NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            List<Integer> threatTypes = new ArrayList<>();
            if (threatTypesRaw instanceof List) {
                for (Object o : (List<Object>) threatTypesRaw) {
                    if (o instanceof Number) threatTypes.add(((Number) o).intValue());
                }
            }
            if (threatTypes.isEmpty()) {
                threatTypes.add(UrlCheckThreat.MALWARE);
                threatTypes.add(UrlCheckThreat.PHISHING);
            }
            int[] typesArr = new int[threatTypes.size()];
            for (int i = 0; i < threatTypes.size(); i++) typesArr[i] = threatTypes.get(i);

            client.urlCheck(url, appId != null ? appId : "", typesArr)
                    .addOnSuccessListener((UrlCheckResponse resp) -> {
                        List<Integer> outThreats = new ArrayList<>();
                        for (UrlCheckThreat t : resp.getUrlCheckResponse()) {
                            outThreats.add(t.getUrlCheckResult());
                        }
                        Map<String, Object> map = new HashMap<>();
                        map.put("success", true);
                        map.put("threats", outThreats);
                        result.success(map);
                    })
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    private void huaweiUserDetect(String appId, @NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.userDetection(appId != null ? appId : "")
                    .addOnSuccessListener(resp -> {
                        Map<String, Object> map = new HashMap<>();
                        map.put("success", true);
                        map.put("responseToken", resp.getResponseToken());
                        result.success(map);
                    })
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    private void huaweiWifiDetect(@NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.getWifiDetectStatus()
                    .addOnSuccessListener((WifiDetectResponse resp) -> {
                        Map<String, Object> map = new HashMap<>();
                        map.put("success", true);
                        map.put("wifiDetectStatus", resp.getWifiDetectStatus());
                        result.success(map);
                    })
                    .addOnFailureListener(e -> result.success(failure(e.getMessage(),
                            e.getClass().getSimpleName())));
        } catch (Exception e) {
            result.success(failure(e.getMessage(), e.getClass().getSimpleName()));
        }
    }

    private void huaweiEnableAppsCheck(@NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.enableAppsCheck()
                    .addOnSuccessListener(v -> result.success(true))
                    .addOnFailureListener(e -> result.error(e.getClass().getSimpleName(),
                            e.getMessage(), null));
        } catch (Exception e) {
            result.error(e.getClass().getSimpleName(), e.getMessage(), null);
        }
    }

    private void huaweiIsVerifyAppsCheck(@NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.isVerifyAppsCheck()
                    .addOnSuccessListener((VerifyAppsCheckEnabledResp resp) ->
                            result.success(resp.getResult()))
                    .addOnFailureListener(e -> result.error(e.getClass().getSimpleName(),
                            e.getMessage(), null));
        } catch (Exception e) {
            result.error(e.getClass().getSimpleName(), e.getMessage(), null);
        }
    }

    private void huaweiGetMaliciousAppsList(@NonNull MethodChannel.Result result) {
        try {
            SafetyDetectClient client = SafetyDetect.getClient(context);
            client.getMaliciousAppsList()
                    .addOnSuccessListener((MaliciousAppsListResp resp) -> {
                        List<Map<String, Object>> out = new ArrayList<>();
                        List<MaliciousAppsData> list = resp.getMaliciousAppsList();
                        if (list != null) {
                            for (MaliciousAppsData app : list) {
                                Map<String, Object> entry = new HashMap<>();
                                entry.put("packageName", app.getApkPackageName());
                                entry.put("apkSha256", app.getApkSha256());
                                entry.put("category", app.getApkCategory());
                                out.add(entry);
                            }
                        }
                        result.success(out);
                    })
                    .addOnFailureListener(e -> result.error(e.getClass().getSimpleName(),
                            e.getMessage(), null));
        } catch (Exception e) {
            result.error(e.getClass().getSimpleName(), e.getMessage(), null);
        }
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private static Map<String, Object> success(String token, Map<String, Object> meta) {
        Map<String, Object> map = new HashMap<>();
        map.put("success", true);
        if (token != null) map.put("token", token);
        if (meta != null) map.put("metadata", meta);
        return map;
    }

    private static Map<String, Object> failure(String msg, String code) {
        Map<String, Object> map = new HashMap<>();
        map.put("success", false);
        if (msg != null) map.put("error", msg);
        if (code != null) map.put("errorCode", code);
        return map;
    }

    private static String generateNonce() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);

        return android.util.Base64.encodeToString(
                bytes,
                android.util.Base64.URL_SAFE
                        | android.util.Base64.NO_WRAP
                        | android.util.Base64.NO_PADDING
        );
    }

    private static byte[] generateNonceBytes() {
        byte[] bytes = new byte[24];
        new SecureRandom().nextBytes(bytes);
        return bytes;
    }
}

