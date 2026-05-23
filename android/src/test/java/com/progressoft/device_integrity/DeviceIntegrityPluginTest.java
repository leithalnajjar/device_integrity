package net.anatech.device_integrity;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

/**
 * Minimal smoke test for the plugin package. Real instrumentation tests
 * live in the example app's androidTest module.
 */
public class DeviceIntegrityPluginTest {
  @Test
  public void channelNameIsStable() {
    assertEquals("device_integrity", DeviceIntegrityChecker.CHANNEL_NAME);
  }
}
