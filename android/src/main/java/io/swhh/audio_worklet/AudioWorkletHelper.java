package io.swhh.audio_worklet;

import android.media.AudioFormat;
import android.media.AudioTrack;
import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.Log;
import io.flutter.plugin.common.ErrorLogResult;
import io.flutter.plugin.common.MethodChannel;

import static io.swhh.audio_worklet.AudioWorkletPlugin.TAG;

class AudioWorkletHelper {

  private MethodChannel methodChannel;

  private AudioTrack audioTrack;

  private boolean running;
  private float[] floats = new float[5000];

  AudioWorkletHelper(MethodChannel methodChannel) {
    this.methodChannel = methodChannel;
  }

  void close() {
    // do nothing
  }

  void start(int rate) {
    int outMinSize = AudioTrack.getMinBufferSize(rate,
            AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT);
    Log.d(TAG, "start at rate=" + rate + " buf size(bytes)=" + outMinSize);

    audioTrack = new AudioTrack.Builder()
            .setAudioFormat(new AudioFormat.Builder()
                    .setSampleRate(rate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .build())
            .setBufferSizeInBytes(outMinSize * 4)
            //.setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY) // only allowed at 48k
            .build();
    audioTrack.play();
    //audioTrack.write(new float[outMinSize / 2],
    //        0, outMinSize / 2, AudioTrack.WRITE_NON_BLOCKING);
    running = true;

    Thread t;
    t = new Thread(this::runBody);
    t.setDaemon(true);
    t.start();
  }

  void stop() {
    Log.d(TAG, "stop");
    running = false;
    if (audioTrack != null) {
      audioTrack.stop();
      audioTrack.release();
      audioTrack = null;
    }
  }

  private void runBody() {
    final Handler handler = new Handler(Looper.getMainLooper());
    final Semaphore s = new Semaphore(1);
    final AtomicInteger length = new AtomicInteger(0);

    s.acquireUninterruptibly();

    while (running) {
      handler.post(() -> methodChannel.invokeMethod("getAudio", null, new ErrorLogResult(TAG) {
        @Override
        public void success(Object o) {
          double[] data = (double[]) o;
          if (data == null || data.length == 0) {
            try {
              Thread.sleep(100);
            } catch (InterruptedException e) {
              // ignore
            }
            Log.d(TAG, "slept");
            return;
          }
          if (floats.length < data.length) {
            floats = new float[data.length];
          }
          for (int i = 0; i < data.length; i++) {
            floats[i] = (float) data[i];
          }
          length.set(data.length);
          s.release();
        }
      }));

      s.acquireUninterruptibly();
      int l = length.get();
      if (audioTrack != null) {
        audioTrack.write(floats, 0, l, AudioTrack.WRITE_BLOCKING);
      }
    }
    Log.d(TAG, "sound thread ended");
  }
}
