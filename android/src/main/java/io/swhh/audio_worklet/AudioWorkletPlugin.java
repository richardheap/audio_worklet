package io.swhh.audio_worklet;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * AudioWorkletPlugin
 */
public class AudioWorkletPlugin implements FlutterPlugin {
  static final String TAG = "audio_worklet";

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects.
  public static void registerWith(Registrar registrar) {
    new AudioWorkletPlugin().setupChannels(registrar.messenger(), registrar.context());
  }

  private MethodChannel methodChannel;
  private AudioWorkletHelper helper;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    setupChannels(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    teardownChannels();
  }

  private void setupChannels(BinaryMessenger messenger, Context context) {
    methodChannel = new MethodChannel(messenger, "audio_worklet");
    helper = new AudioWorkletHelper(methodChannel);
    methodChannel.setMethodCallHandler(new AudioWorkletHandler(helper));
  }

  private void teardownChannels() {
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;

    helper.close();
    helper = null;
  }
}
