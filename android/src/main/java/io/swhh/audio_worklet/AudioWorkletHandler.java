package io.swhh.audio_worklet;

import android.media.AudioTrack;

import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static android.media.AudioManager.STREAM_MUSIC;
import static io.swhh.audio_worklet.AudioWorkletPlugin.TAG;

public class AudioWorkletHandler implements MethodChannel.MethodCallHandler {

  private final AudioWorkletHelper helper;

  AudioWorkletHandler(AudioWorkletHelper helper) {
    this.helper = helper;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch (call.method) {
      case "nativeRate":
        result.success(AudioTrack.getNativeOutputSampleRate(STREAM_MUSIC));
        return;

      case "start":
        Integer rate = call.argument("rate");
        if (rate == null) {
          result.error("missingParam", "rate is missing", null);
          return;
        }
        try {
          helper.start(rate);
          result.success(null);
        } catch (Exception e) {
          Log.e(TAG, "oops", e);
          result.error("startFail", "startFail", e.getMessage());
        }
        return;

      case "stop":
        try {
          helper.stop();
          result.success(null);
        } catch (Exception e) {
          Log.e(TAG, "oops", e);
          result.error("stopFail", "stopFail", e.getMessage());
        }
        break;

      default:
        result.notImplemented();
    }
  }
}
