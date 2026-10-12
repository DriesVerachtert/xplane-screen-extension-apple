# XPlaneScreenExtension

An iPhone/iPad/Mac app that turns your device into a secondary screen for
[X-Plane](https://www.x-plane.com/): live flight instruments on one screen,
one-tap command buttons (gear, brakes, lights, ...) on another. It talks to
the simulator over the [ExtPlane](https://github.com/vranki/ExtPlane) plugin's
TCP protocol.

**This app only does anything useful if X-Plane is running with the ExtPlane
plugin installed and reachable on your network.** It is not affiliated with
Laminar Research.

See [`PLAN.md`](PLAN.md) for the architecture and build plan.

## Building

Prerequisites:

- Xcode (full install, not just Command Line Tools)
- [Homebrew](https://brew.sh)
- `brew install xcodegen swiftlint swiftformat xcbeautify`

The Xcode project is generated from [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and is **not** committed —
regenerate it after cloning and after any change to `project.yml`:

```sh
xcodegen generate
open XPlaneScreenExtension.xcodeproj
```

Command-line build/test (no Xcode UI needed):

```sh
xcodebuild -scheme XPlaneScreenExtension-macOS -destination 'platform=macOS' test
xcodebuild -scheme XPlaneScreenExtension-iOS -destination 'platform=iOS Simulator,name=iPhone 17' build
```

SwiftLint and SwiftFormat run automatically as Xcode build phases; to run them
standalone:

```sh
swiftlint
swiftformat --lint .   # check only
swiftformat .           # actually reformat
```

## License

GNU GPLv3, with an additional permission for distribution through Apple's App
Store — see [`LICENSE`](LICENSE).
