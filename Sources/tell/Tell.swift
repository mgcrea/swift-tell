import ArgumentParser
import AVFAudio
import Darwin
import Foundation

// https://github.com/apple/swift-argument-parser/blob/main/Examples/count-lines/CountLines.swift

@main
@available(macOS 10.15, *)
struct Tell: AsyncParsableCommand {
  public private(set) var version = "1.0.0"

  @Flag(help: "List available voices")
  var listVoices = false

  @Flag(name: .customLong("version"), help: "Print version")
  var showVersion = false

  @Flag(help: "The speech utterance uses markup written using the Speech Synthesis Markup Language (SSML) standard")
  var ssml = false

  // print(AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceMaximumSpeechRate)
  @Option(name: .shortAndLong, help: "The utterance rate, [0.0 - 1.0] Default = 0.5")
  var rate: Float?

  @Option(name: .customLong("pitch"), help: "The utterance pitchMultiplier, [0.5 - 2.0] Default = 1.0")
  var pitchMultiplier: Float?

  @Option(name: .long, help: "The utterance volume, [0.0 - 1.0] Default = 1.0")
  var volume: Float?

  @Option(name: .customLong("pre"), help: "The utterance preUtteranceDelay, Default = 0.0")
  var preUtteranceDelay: Double?

  @Option(name: .customLong("post"), help: "The utterance postUtteranceDelay, Default = 0.0")
  var postUtteranceDelay: Double?

  @Option(name: .shortAndLong, help: "The utterance voice")
  var voice: String?

  @Option(name: .shortAndLong, help: "The utterance language, Default = locale")
  var language: String = Locale.current.identifier

  @Option(
    name: .shortAndLong,
    help: "The utterance file to be spoken. If omitted, read from stdin.",
    completion: .file(),
    transform: URL.init(fileURLWithPath:)
  )
  var file: URL?

  @Option(
    name: .shortAndLong,
    help: "Output spoken speech as a PCM file.",
    completion: .file(),
    transform: URL.init(fileURLWithPath:)
  )
  var output: URL?

  @Flag(help: "Output spoken range of speech as sliced PCM files")
  var slice = false

  @Argument(help: "The phrase to tell.")
  var phrase: String?
}

@available(macOS 10.15, *)
extension Tell {
  var inputFileHandle: FileHandle? {
    get throws {
      guard let file = file else {
        return .standardInput
      }
      do {
        return try FileHandle(forReadingFrom: file)
      } catch {
        print(error.localizedDescription)
        return nil
      }
    }
  }

  var inputContents: String? {
    if file != nil {
      do {
        return String(bytes: try inputFileHandle!.availableData, encoding: .utf8)!
      } catch {}
    }
    return phrase
  }

  var speechVoice: AVSpeechSynthesisVoice? {
    if voice != nil {
      return AVSpeechSynthesisVoice(identifier: voice!)
    }
    return AVSpeechSynthesisVoice(language: language)
  }

  var utterance: AVSpeechUtterance {
    let ssml = ssml || inputContents!.starts(with: "<speak>")
    // https://cloud.google.com/text-to-speech/docs/ssml
    if ssml {
      guard #available(macOS 13.0, *) else {
        fatalError("'ssml' isn't supported on this platform.")
      }
      let ssmlUtterance = AVSpeechUtterance(
        ssmlRepresentation: inputContents!
      )
      guard ssmlUtterance != nil else {
        fatalError("input isn't a valid SSML utterance")
      }
      return ssmlUtterance!
    }
    return AVSpeechUtterance(string: inputContents!)
  }

  func printVoices() {
    let speechVoices = AVSpeechSynthesisVoice.speechVoices()
    print("[")
    for (index, voice) in speechVoices.enumerated() {
      print(String(format: "  {\"language\": \"%@\", \"identifier\": \"%@\", \"name\": \"%@\"}",
                   voice.language,
                   voice.identifier,
                   voice.name), terminator: "")
      if index < speechVoices.count - 1 {
        print(",")
      } else {
        print("\n]")
      }
    }
  }

  func configureUtterance(utterance: AVSpeechUtterance) {
    // Configure the utterance.
    if rate != nil {
      utterance.rate = rate!
    }
    if pitchMultiplier != nil {
      utterance.pitchMultiplier = pitchMultiplier!
    }
    if volume != nil {
      utterance.volume = volume!
    }
    if preUtteranceDelay != nil {
      utterance.preUtteranceDelay = preUtteranceDelay!
    }
    if postUtteranceDelay != nil {
      utterance.postUtteranceDelay = postUtteranceDelay!
    }
  }

  mutating func run() async throws {
    if showVersion {
      print(version)
      return
    }
    if listVoices {
      printVoices()
      return
    }

    guard inputContents != nil else {
      print(Tell.helpMessage())
      return
    }

    // Configure utterance
    configureUtterance(utterance: utterance)

    // Assign the voice to the utterance.
    utterance.voice = speechVoice

    // Create a speech synthesizer.
    let synthesizer = AVSpeechSynthesizer()

    // Bind to a delegate
    let delegate = SpeechSynthesizerDelegate()
    synthesizer.delegate = delegate

    // Setup delegate awaited task
    delegate.task = Task {
      try await Task.sleep(nanoseconds: UInt64(60.0 * 60.0 * Double(NSEC_PER_SEC)))
    }

    // Tell the synthesizer to speak the utterance.
    if output == nil {
      synthesizer.speak(utterance)
    } else {
      var outputFile: AVAudioFile?
      var outputRangeFiles: [NSRange: AVAudioFile?] = [:]
      let outputUrl = output!
      let slice: Bool = slice
      let outputUrlExtension = outputUrl.pathExtension
      let baseString = outputUrlExtension.isEmpty ?
        outputUrl.relativeString :
        outputUrl.relativeString.replacingOccurrences(of: "." + outputUrlExtension, with: "")

      synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
          fatalError("unknown buffer type: \(buffer)")
        }

        do {
          if pcmBuffer.frameLength == 0 {
            // done
          } else {
            // Main file
            if outputFile == nil {
              print(String(format: "Writing to file %@...", outputUrl.absoluteString), to: &errStream)
              outputFile = try AVAudioFile(
                forWriting: outputUrl,
                settings: pcmBuffer.format.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: false
              )
            }
            // Append buffer to main file
            try outputFile?.write(from: pcmBuffer)

            if slice && delegate.range.upperBound > 0 {
              // Slice file
              if outputRangeFiles[delegate.range] == nil {
                let filePath = String(format: baseString + "_%d_%d" + "." + outputUrlExtension,
                                      delegate.range.lowerBound,
                                      delegate.range.upperBound)

                print(String(format: "Writing slice to file %@...", filePath), to: &errStream)
                outputRangeFiles[delegate.range] = try AVAudioFile(
                  forWriting: URL(fileURLWithPath: filePath),
                  settings: pcmBuffer.format.settings,
                  commonFormat: .pcmFormatInt16,
                  interleaved: false
                )
              }
              // Append buffer to range file
              try outputRangeFiles[delegate.range]!?.write(from: pcmBuffer)
            }
          }
        } catch {
          print(error.localizedDescription)
        }
      }
    }

    do {
      try await delegate.task?.value
    } catch {
      // Expected task.cancel()
    }
  }
}
