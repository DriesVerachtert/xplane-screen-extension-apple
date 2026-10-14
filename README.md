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

## Running on a real iPhone/iPad

The simplest path is: open `XPlaneScreenExtension.xcodeproj` in Xcode, sign in
with your Apple ID under **Xcode → Settings → Accounts** (a free "Personal
Team" is enough for on-device testing, no paid Apple Developer Program needed),
select the `XPlaneScreenExtension-iOS` scheme, pick your device, and hit Run.

A few things that aren't obvious the first time:

- The device needs **Developer Mode** enabled: **Settings → Privacy &
  Security → Developer Mode** on the device, which requires a restart.
- The very first install needs to be explicitly trusted on the device:
  **Settings → General → VPN & Device Management**, tap the developer
  profile, tap **Trust**. Until you do this, launching fails with an
  "invalid code signature" error even though the install succeeded.
- A free Personal Team's app install expires after about a week and needs
  reinstalling — expected, not a bug.
- Since the device is on your Wi-Fi network rather than sharing this Mac's
  localhost (unlike the macOS build or the iOS Simulator), enter this
  machine's actual LAN IP as the host, not `127.0.0.1`.

To build and install from the command line instead of Xcode's UI (useful for
scripting; `xcrun xctrace list devices` lists connected device IDs):

```sh
# Your Team ID is the certificate's OU field, which can differ from the
# parenthetical in its CN -- Xcode's Accounts pane doesn't show it directly:
security find-certificate -p -c "Apple Development: you@example.com" \
    ~/Library/Keychains/login.keychain-db | openssl x509 -noout -subject

xcodebuild -scheme XPlaneScreenExtension-iOS -destination 'id=<device-id>' \
    -allowProvisioningUpdates DEVELOPMENT_TEAM=<your-team-id> build

xcrun devicectl device install app --device <device-id> \
    ~/Library/Developer/Xcode/DerivedData/XPlaneScreenExtension-*/Build/Products/Debug-iphoneos/XPlaneScreenExtension-iOS.app

xcrun devicectl device process launch --device <device-id> eu.dries.xplanescreenextension
```

## License

GNU GPLv3, with an additional permission for distribution through Apple's App
Store — see [`LICENSE`](LICENSE).
