# Tell

Small command-line utility to speak some text, using [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) tool.

Beefed up alternative to Apple's `/usr/bin/say` utility built with [Swift](https://www.swift.org).

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
