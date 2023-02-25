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
    print("Speech did start", to: &errStream)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didPause _: AVSpeechUtterance
  ) {
    speaking = false
    print("Speech did pause", to: &errStream)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didCancel _: AVSpeechUtterance
  ) {
    speaking = false
    print("Speech did cancel", to: &errStream)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didContinue _: AVSpeechUtterance
  ) {
    speaking = true
    print("Speech did continue", to: &errStream)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    willSpeakRangeOfSpeechString characterRange: NSRange,
    utterance _: AVSpeechUtterance
  ) {
    range = characterRange
    print(String(format: "Speech speaking range %d to %d...",
                 range.lowerBound, range.upperBound), to: &errStream)
  }

  public func speechSynthesizer(
    _: AVSpeechSynthesizer,
    didFinish _: AVSpeechUtterance
  ) {
    print("Speech did finish", to: &errStream)
    task?.cancel()
    speaking = false
  }
}
