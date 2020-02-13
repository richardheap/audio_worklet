# audio_worklet

A plugin to stream blocks of audio to the sound card.

This plugin was created to mimic the way the `ScriptProcessingNode` of the Web Audio API works.
After the sound card is started, the sound system make a periodic callback to request the next
block of audio samples. The callback is implemented as a Native->Dart callback, and must be
provided by implementing `AWEvents`.

The use of a callback allows the Flutter application to generate the audio on the fly from a
signal generator, midi player, audio codec, pitch changer, jitter buffer, etc, etc.

## Usage

A typical first use is to query the default sample rate of the sound system.

```dart
import 'package:audio_worklet/audio_worklet.dart';

var nativeRate = await AudioWorklet.nativeRate;
```

To start the sound card use `start(rate)` and to stop it use `stop()`. For example:

```dart
              RaisedButton(
                child: Text('Start'),
                onPressed: () => AudioWorklet.start(_nativeRate),
              ),
              RaisedButton(
                child: Text('Stop'),
                onPressed: () => AudioWorklet.stop(),
              ),
```

In the same way that the Web Audio API works, a callback function must be provided to deliver
the next block of audio samples periodically. The Flutter application must implement `AWEvents`,
and pass in that implementation when inititalizing the library. One way is to implement this
at the application stateful widget level.

```dart
class _MyAppState extends State<MyApp> implements AWEvents {

  @override
  void initState() {
    super.initState();
    AudioWorklet.setEventHandler(this); // register the callback
    initPlatformState();
  }

  @override
  Float64List getAudio() {
    // todo - return a list of double samples between -1.0 and +1.0
  }
```
