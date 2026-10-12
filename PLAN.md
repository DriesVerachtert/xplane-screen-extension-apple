# X-Plane Screen Extension — Plan

An iPhone/iPad (and, with little extra effort, Mac) app that acts as a secondary
screen for X-Plane: live instrument gauges on one screen, one-tap command buttons
(gear, brakes, lights, ...) on another, talking to the flight sim over the
[ExtPlane](https://github.com/vranki/ExtPlane) plugin's TCP protocol.

Reference material already reviewed:

- `../ExtPlane` — the X-Plane plugin + protocol definition (`README.md`). Plain-text,
  line-based TCP protocol on port 51000: `sub`/`unsub`/`set`/`get` for datarefs,
  `cmd once|begin|end`, `key`, `but`/`rel`, output lines like `uf <dataref> <value>`.
- `../ExtPlane-Panel` — an existing Qt/QML desktop+Android+RaspberryPi client for the
  same protocol. Not usable as code (C++/QML vs. Swift), but useful as UX reference:
  freeform drag/resize "edit mode", multiple numbered pages, per-instrument settings
  dialog, per-item persisted geometry, and a large instrument catalog.

## Technology choice

Native **Swift + SwiftUI**, using Xcode's multiplatform app template: one SwiftUI
module targeting iOS/iPadOS and native macOS as separate build targets sharing nearly
all code (views, the `Network.framework` socket layer, Codable/UserDefaults
persistence). Preferred over Mac Catalyst because the layout editor's drag/resize
interaction should feel like a native mouse/trackpad interaction on Mac, not a
translated touch UI — `DragGesture` already works the same on both, so this costs
little. Expect a handful of `#if os(iOS)` / `#if os(macOS)` branches, mainly for
macOS's Settings/Preferences window (Cmd+,) and menu bar vs. an in-app settings
screen.

Why: the app only needs to run on Apple platforms, so a native codebase avoids the
plugin/bridging tax that Flutter/React Native would add for something as low-level as
a raw persistent TCP socket with a custom text protocol. Apple's `Network.framework`
(`NWConnection`) is built for exactly this and works identically across iOS/iPadOS/
macOS.

Key frameworks:

- **Network.framework** (`NWConnection`) — TCP connection to ExtPlane, line-based I/O.
- **SwiftUI** — all UI, including the instrument widgets and the layout editor.
- **Swift's `Observation` framework** (`@Observable`) or Combine — pushing live
  dataref updates from the client into the views.
- **Codable + JSON files / `UserDefaults`** — persisting connection settings, page
  layouts, and button configurations.

## Architecture

```
ExtPlaneClient (networking + protocol)
   -> owns the NWConnection, connect/reconnect/backoff
   -> encodes outgoing commands (sub/unsub/set/get/cmd/key/but/rel)
   -> decodes incoming lines into typed events
   -> publishes per-dataref values to subscribers

DataRefStore
   -> in-memory registry of current values, keyed by dataref path
   -> reference-counts subscriptions (multiple widgets may want the same dataref)
   -> is what SwiftUI views actually observe

Instrument widgets (SwiftUI views)
   -> declare which dataref(s) they need + desired accuracy
   -> render purely off DataRefStore values (dumb/presentational)
   -> e.g. AltimeterView, AirspeedView, AttitudeIndicatorView

Layout system
   -> Page: an ordered list of placed instruments (id, type, frame, per-instrument config)
   -> LayoutStore: loads/saves Page[] as JSON
   -> Edit mode: drag to move, handle to resize, tap to open per-instrument settings

Command/button screen
   -> ButtonConfig: label, icon, action (cmd once/begin-end, key id, or dataref set)
   -> Reuses the same edit-mode/layout mechanism as instrument pages where sensible

Settings / connection screen
   -> host + port entry, connect/disconnect, live status, last-used connection persisted
```

## App Store distribution readiness

Decided/settled up front so it doesn't need retrofitting later:

- **License: GPLv3 + an App Store "additional permission" exception.** Apple's
  Developer/Media Services terms impose extra restrictions on redistribution (tied to
  the user's Apple ID, no redistribution outside the Store) beyond what plain GPL
  allows downstream, which the FSF considers a real incompatibility with App Store
  distribution as-is. The app doesn't link against ExtPlane's GPL code (it's a
  separate process talking plain TCP), so GPLv3 is a choice, not an inherited
  obligation — but to honor the stated preference for GPLv3 while being App-Store-safe,
  add a short **GPLv3 §7 additional-permission clause** to the `LICENSE` file at repo
  setup time (step 1), granting the rights needed to convey the covered work through
  Apple's App Store despite its additional terms (same category of mechanism as GCC's
  Runtime Library Exception). Draft the exact clause text during step 1 and have it
  reviewed before the first public release — it's a legal document, not just
  boilerplate.
- **Apple Developer Program** enrollment ($99/yr) is required to distribute on the App
  Store even for a free app with no IAP.
- **Local Network permission**: add `NSLocalNetworkUsageDescription` to Info.plist as
  soon as the networking layer exists (step 2) — any TCP connection to a LAN IP
  triggers iOS's Local Network privacy prompt. Add `NSBonjourServices` only if/when
  mDNS discovery is added later.
- **Privacy Manifest** (`PrivacyInfo.xcprivacy`): required by Apple for apps using
  "required reason" APIs, which includes `UserDefaults`. Add it the moment settings
  persistence is introduced (step 4), not right before submission.
- **Export compliance**: set `ITSAppUsesNonExemptEncryption = NO` in Info.plist —
  the ExtPlane protocol is plaintext, so the app uses no encryption and can skip the
  questionnaire on every release.
- **The app only has a purpose with X-Plane + the ExtPlane plugin running and
  reachable on the network — say so clearly, not hide it.** No user-facing "demo
  mode": the first screen/onboarding should state the prerequisite plainly (X-Plane
  running, ExtPlane plugin installed and listening, same network), and the App Store
  description should do the same, to avoid confused reviews from people who tried it
  with nothing running. This mirrors how other companion/remote-control apps for
  specific external hardware or software are expected to work.
  - For **App Review** specifically, a self-contained demo mode isn't actually
    required: apps requiring specific external hardware/software are routinely
    approved based on clear **Reviewer Notes** (explain the ExtPlane prerequisite)
    plus a short demo video link showing the app driving a real X-Plane session —
    that's the plan for submission, not an in-app fallback.
  - A `MockExtPlaneConnection` is still worth building, but purely as **internal
    dev/test infrastructure** — it's what makes the protocol layer unit-testable and
    lets instrument widgets be worked on via SwiftUI Previews without a live socket.
    It's never exposed as a selectable mode in the shipped app.
- **Trademark/affiliation**: don't imply endorsement by Laminar Research in the name,
  icon, or description; "for use with X-Plane" is fine as a plain descriptor, plus a
  short non-affiliation disclaimer in the Store listing.
- **Mac distribution**: list the Mac target on the Mac App Store as part of the same
  App Store Connect listing ("Universal Purchase" — one free download unlocks iPhone,
  iPad, and Mac), rather than separate Developer ID distribution, to keep "easy to
  install" as a single answer. This requires App Sandbox, which means adding the
  `com.apple.security.network.client` entitlement for outgoing connections.

## Steps

1. **Project scaffolding**
   - Create the Xcode project using the multiplatform app template: one SwiftUI
     module with iOS/iPadOS and native macOS targets from the start (see Technology
     choice above).
   - Add the `LICENSE` file: GPLv3 text plus the App Store additional-permission
     clause described above.
   - Add SwiftLint + SwiftFormat (see Tooling below) and wire them into a build
     phase from day one, before the codebase grows.
   - Set up the Swift Testing target.

2. **ExtPlane protocol layer** (pure Swift, no UI — the highest-value code to test)
   - `ExtPlaneConnection`: wraps `NWConnection`, connect/disconnect, line framing
     (buffer + split on `\n`), send/receive.
   - `ExtPlaneCommand`: typed outgoing commands → wire strings (`sub`, `unsub`,
     `set`, `get`, `cmd once/begin/end`, `key`, `but`, `rel`).
   - `ExtPlaneEvent`: parse incoming lines (`EXTPLANE`, `EXTPLANE-VERSION`,
     `EXTPLANE-WARNING`, `u{i,f,d,ia,fa,b}` updates) into a typed enum.
   - Unit tests: command formatting, line parsing (including array datarefs like
     `ufa ... [0.1,0.2,0.3]` and base64 `data` datarefs), partial-line/buffering
     edge cases.

3. **DataRefStore**
   - Subscription reference counting (two gauges on screen both wanting
     `sim/flightmodel/misc/h_ind` should result in one `sub`, not two).
   - Publishes updates to SwiftUI (via `@Observable`).
   - Unit tests with a fake/mock connection standing in for the real socket.

4. **Connection settings screen**
   - Leads with a clear statement of the prerequisite: X-Plane running with the
     ExtPlane plugin installed and reachable on the same network — not just a bare
     host/port form.
   - Host/port form, "Connect" action, live connection status.
   - Persist last-used connection (`UserDefaults` is enough).

5. **First instruments (keep the v1 set small)**
   - Altimeter, airspeed indicator, attitude indicator — enough to validate the
     widget pattern (gauge view subscribes to dataref(s), renders, updates live).
   - Each instrument is self-contained: knows its dataref(s), accuracy, and how to
     draw itself from a value.

6. **Layout editor (one page first)**
   - Static grid or freeform canvas with drag + resize in an "edit mode" toggle,
     modeled on ExtPlane-Panel's interaction (drag handle, resize handle, tap for
     per-instrument settings sheet).
   - `Page` persisted as JSON; load on launch.

7. **Multiple pages / page switcher**
   - Swipeable or tab-based page list, each an independently laid-out `Page`.

8. **Command/button screen**
   - Configurable buttons mapped to `cmd once/begin/end` or `key` — gear, brakes,
     lights to start.
   - Press-and-hold support for `cmd begin`/`cmd end` style actions (e.g. starter).

9. **Polish / robustness**
   - Reconnect-on-drop, iOS background/foreground handling (iOS suspends the app and
     its socket within seconds of backgrounding — reconnect on foreground), error/
     warning surface (`EXTPLANE-WARNING` lines).
   - On iOS/iPadOS, set `UIApplication.shared.isIdleTimerDisabled = true` while
     connected so the screen doesn't auto-lock mid-flight (not applicable on Mac).
   - Expand instrument catalog as needed.

10. **Mac target refinement**
    - The macOS target already exists from step 1; this step is about polish, not
      bring-up — macOS-specific pieces like a Settings/Preferences window (Cmd+,)
      instead of an in-app settings screen, menu bar items, resizable-window layout
      assumptions, and verifying pointer/keyboard interaction in the layout editor.
    - Set up Mac App Store "Universal Purchase" listing alongside iOS (see App Store
      distribution readiness above) and the App Sandbox entitlement.

## Tooling (Swift equivalents of Python's black/mypy/pytest)

| Need | Python | Swift |
|---|---|---|
| Formatting | black | **SwiftFormat** |
| Linting / quality | flake8 / pylint | **SwiftLint** |
| Static typing | mypy | *(not needed — Swift is statically, strictly typed by the compiler itself)* |
| Unit tests | pytest | **Swift Testing** (`@Test` / `#expect`, modern) or XCTest (older, still common) |
| Dead code detection | — (vulture, sort of) | **Periphery** |

Notes:

- Swift's compiler enforces types at compile time always, so there's no gradual-typing
  gap for a tool like mypy to fill.
- The protocol/parsing/store layer (steps 2–3) has no SwiftUI dependency, so it's
  straightforward to unit test the way you'd test any plain-Python module — the
  SwiftUI views themselves are where testing gets less convenient, which is exactly
  why the plan keeps business logic out of the views.
- SwiftLint + SwiftFormat + the test target should all run in CI (see below) so
  style/quality issues are caught the same way a Python project would catch them.

## CI/CD (GitHub Actions)

The repo is public on GitHub, so GitHub Actions minutes are free regardless of
runner OS — no macOS-runner cost concern. Two tiers of workflow:

### 1. Build/test/lint (unsigned) — every push and PR

- `xcodebuild build` and `xcodebuild test` for both the iOS and macOS targets.
- SwiftLint + SwiftFormat (`--lint`) checks.
- No signing identity or secrets required at all — set this up first, right after
  step 1 (project scaffolding), so every change is verified from the start.

### 2. Release builds (signed) — on tag/release

Produces distributable artifacts for all three stated distribution channels:

- **Mac**: build, sign with Developer ID, notarize (`xcrun notarytool submit`),
  staple the ticket, zip, and attach to the GitHub Release — this is the direct
  "download the Mac app" path for people not using the Mac App Store.
- **iOS/iPadOS, TestFlight**: archive, export, upload to App Store Connect. TestFlight
  builds expire after 90 days, so this should be able to re-run on a schedule (not
  just on tags) to keep the current build fresh for external testers.
- **iOS/iPadOS, sideload path**: export an unsigned (or ad-hoc-signed) `.ipa` and
  attach it to the GitHub Release, for users of AltStore/SideStore/Sideloadly — no
  Apple review or App Store Connect involvement for this artifact.
- **Mac App Store / App Store submission**: same archive/upload mechanism as
  TestFlight, triggered manually (or on a release tag) rather than on a schedule,
  since actual store submissions shouldn't happen automatically on every commit.

Auth: use an **App Store Connect API key** (`.p8`, generated in App Store Connect)
rather than Apple ID + password/2FA — it's the supported non-interactive method for
CI. Store the API key, the Developer ID signing certificate (`.p12`, base64-encoded),
and the provisioning profile(s) as encrypted GitHub Actions repository secrets.
**Never commit any of these to the repo.** Fastlane (`brew install fastlane`,
mentioned earlier) is the common tool for orchestrating signing + notarizing +
uploading in one place, and is worth adopting for this tier rather than hand-rolling
raw `xcodebuild`/`notarytool`/`altool` invocations.

Not pursued: Ad Hoc distribution via manually-registered device UDIDs (capped at 100
devices/year, too much per-user friction) and the Apple Developer Enterprise Program
(against Apple's terms for public distribution outside a single organization, real
risk of certificate revocation).
