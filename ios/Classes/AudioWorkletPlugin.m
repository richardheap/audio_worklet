#import "AudioWorkletPlugin.h"
#if __has_include(<audio_worklet/audio_worklet-Swift.h>)
#import <audio_worklet/audio_worklet-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "audio_worklet-Swift.h"
#endif

@implementation AudioWorkletPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioWorkletPlugin registerWithRegistrar:registrar];
}
@end
