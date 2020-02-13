import Flutter
import AVFoundation
import os.log

func worklet_log(_ msg: String) {
  if #available(iOS 10.0, *) {
    os_log("%s", msg)
  } else {
    print(msg)
  }
}

public class SwiftAudioWorkletPlugin: NSObject, FlutterPlugin {
  
  static var channel: FlutterMethodChannel?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "audio_worklet", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SwiftAudioWorkletPlugin(), channel: channel!)
  }
  
  let playerNode = AVAudioPlayerNode()
  let engine = AVAudioEngine()
  
  var sampleRate: Double = 0.0
  var inputFormat: AVAudioFormat
  
  var buffer1: LoadingAudioBuffer?
  var buffer2: LoadingAudioBuffer?
  
  override init() {
    let mainMixer = engine.mainMixerNode
    let output = engine.outputNode
    sampleRate = output.inputFormat(forBus: 0).sampleRate
    
    inputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                                sampleRate: sampleRate,
                                channels: 1,
                                interleaved: false)!
    
    engine.attach(playerNode)
    engine.connect(playerNode, to: mainMixer, format: inputFormat)
    
    engine.connect(mainMixer, to: output, format: nil)
    mainMixer.outputVolume = 1.0
  }
  
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "nativeRate":
      result(Int(floor(sampleRate)))
      return
      
    case "start":
      do {
        try engine.start()
      } catch {
        worklet_log("Could not start engine: \(error)")
        result(FlutterError.init(code: "errorStart",
                                 message: "could not start engine",
                                 details: error.localizedDescription))
        return
      }

      buffer1 = LoadingAudioBuffer(format: inputFormat, node: playerNode)
      buffer1?.onCompletion()
      buffer2 = LoadingAudioBuffer(format: inputFormat, node: playerNode)
      buffer2?.onCompletion()
      playerNode.play()
      result(nil)
      return
      
    case "stop":
      buffer1?.done = true;
      buffer1 = nil;
      buffer2?.done = true;
      buffer2 = nil;
      playerNode.stop()
      engine.stop()
      result(nil)
      return
      
    default:
      result(FlutterMethodNotImplemented)
      return
    }
  }
}

class LoadingAudioBuffer {
  
  static var nextSerial = 0;
  
  let buffer : AVAudioPCMBuffer
  let node: AVAudioPlayerNode
  var done : Bool = false;
  let serial: Int
  
  init(format: AVAudioFormat, node: AVAudioPlayerNode) {
    self.node = node
    self.buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 5000)!
    self.serial = LoadingAudioBuffer.nextSerial;
    LoadingAudioBuffer.nextSerial += 1;
    log("created")
  }
  
  func onCompletion() {
    if (self.done) {
      return
    }
    log("completed")
    DispatchQueue.main.async {
      self.refill()
    }
  }
  
  func refill() {
    SwiftAudioWorkletPlugin.channel?.invokeMethod("getAudio", arguments: nil, result: {(r:Any?) in
      if let au = r as? FlutterStandardTypedData {
        let count = Int(au.elementCount)
        self.buffer.frameLength = AVAudioFrameCount(count) // todo check for overflow
        let channelData = self.buffer.floatChannelData!.pointee
        au.data.withUnsafeBytes{(pointer: UnsafeRawBufferPointer) in
          let doubles = pointer.bindMemory(to: Double.self)
          for index in 0..<count {
            channelData[index] = Float(doubles[index])
          }
        }
      }
    })
    self.schedule()
  }
  
  func schedule() {
    log("scheduling")
    self.node.scheduleBuffer(buffer, completionHandler: onCompletion)
  }
  
  func log(_ msg: String) {
    worklet_log("\(self.serial): \(msg)");
  }
}
