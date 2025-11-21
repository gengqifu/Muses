import Flutter
import UIKit

public class SoundwavePlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var methodChannel: FlutterMethodChannel?
  private var stateEventChannel: FlutterEventChannel?
  private var pcmEventChannel: FlutterEventChannel?
  private var spectrumEventChannel: FlutterEventChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SoundwavePlayerPlugin()
    instance.methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

    instance.stateEventChannel = FlutterEventChannel(name: "\(eventPrefix)/state", binaryMessenger: registrar.messenger())
    instance.pcmEventChannel = FlutterEventChannel(name: "\(eventPrefix)/pcm", binaryMessenger: registrar.messenger())
    instance.spectrumEventChannel = FlutterEventChannel(name: "\(eventPrefix)/spectrum", binaryMessenger: registrar.messenger())

    instance.stateEventChannel?.setStreamHandler(instance)
    instance.pcmEventChannel?.setStreamHandler(instance)
    instance.spectrumEventChannel?.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init", "load", "play", "pause", "stop", "seek":
      // Placeholder: succeed without actual implementation yet.
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler placeholder
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // No-op placeholder for now.
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // No-op placeholder for now.
    return nil
  }

  private static let methodChannelName = "soundwave_player"
  private static let eventPrefix = "soundwave_player/events"
}
