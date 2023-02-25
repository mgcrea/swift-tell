# Tell

Small command-line utility to speak some text, using [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) tool.

Beefed up alternative to Apple's `/usr/bin/say` utility built with [Swift](https://www.swift.org).

## Usage

```txt
USAGE: tell [<options>] [<phrase>]

ARGUMENTS:
  <phrase>                The phrase to tell.

OPTIONS:
  --list-voices           List available voices
  --version               Print version
  --ssml                  The speech utterance uses markup written using the Speech Synthesis Markup Language (SSML) standard
  -r, --rate <rate>       The utterance rate, [0.0 - 1.0] Default = 0.5
  --pitch <pitch>         The utterance pitchMultiplier, [0.5 - 2.0] Default = 1.0
  --volume <volume>       The utterance volume, [0.0 - 1.0] Default = 1.0
  --pre <pre>             The utterance preUtteranceDelay, Default = 0.0
  --post <post>           The utterance postUtteranceDelay, Default = 0.0
  -v, --voice <voice>     The utterance voice
  -l, --language <language>
                          The utterance language, Default = locale (default: en_FR)
  -f, --file <file>       The utterance file to be spoken. If omitted, read from stdin.
  -o, --output <output>   Output spoken speech as a PCM file.
  --slice                 Output spoken range of speech as sliced PCM files
  -h, --help              Show help information.
```

## build

### debug

```sh
swift package update
swift build
```

### release

```sh
swift package update
swift build -c release
```

## install

```sh
sudo cp .build/release/tell /usr/local/bin
```

## develop

Using [swift-watch](https://github.com/Swift-Watch/swift-watch)

```sh
swift watch -x="run"

swift watch -x="run Tell --rate 0.35 'Hello world'" --clear

swift watch -x="run Tell --rate 0.35 --file test2.xml --voice com.apple.voice.premium.en-US.Ava" --clear
```
