/**
 * DeviceIntegrityPlugin
 *
 * Flutter plugin for device integrity verification using:
 * - Google Play Integrity API for GMS devices
 * - Huawei SafetyDetect SysIntegrity for HMS devices
 *
 * Created by: Laith Alnajjar
 * Date: May 14, 2026
 */
package net.anatech.device_integrity;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;

public class DeviceIntegrityPlugin implements FlutterPlugin, ActivityAware {

    private MethodChannel channel;
    private DeviceIntegrityChecker checker;
    private Context applicationContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        applicationContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), DeviceIntegrityChecker.CHANNEL_NAME);
        checker = new DeviceIntegrityChecker(applicationContext);
        channel.setMethodCallHandler(checker);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        checker = null;
        applicationContext = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        // Activity context available if needed for future enhancements
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // Handle configuration changes
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        // Handle reattachment after configuration changes
    }

    @Override
    public void onDetachedFromActivity() {
        // Clean up activity-specific resources
    }
}
