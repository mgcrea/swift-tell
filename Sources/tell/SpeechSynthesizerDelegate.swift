import AVFAudio
import Foundation

@available(macOS 10.15, *)
public class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
  @Published public var speaking = false
  @Published public var muted = false
  @Published public var range = NSRange()
  @Published public var speechRate = 0.3
  @Published public var utter = ""

  @Published public var semaphore: DispatchSemaphore?
  @Published public var task: Task<Void, Error>?

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didStart utterance: AVSpeechUtterance
  ) {
    speaking = true
    muted = false
    utter = utterance.speechString
    print("didStart")
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didPause _: AVSpeechUtterance
  ) {
    speaking = false
    print("didPause")
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didCancel _: AVSpeechUtterance
  ) {
    speaking = false
    print("didCancel")
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didContinue _: AVSpeechUtterance
  ) {
    speaking = true
    print("didContinue")
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    willSpeakRangeOfSpeechString characterRange: NSRange,
    utterance _: AVSpeechUtterance
  ) {
    range = characterRange
    print("willSpeakRangeOfSpeechString", range)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didFinish _: AVSpeechUtterance
  ) {
    print("didFinish")
    task?.cancel()
    speaking = false
  }
}
