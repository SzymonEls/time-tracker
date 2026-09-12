# TimeTracker

A macOS menu bar client for [AI-productivity-app](https://github.com/SzymonEls/AI-productivity-app).
It shows today's A/B/C project slots and starts or stops their timers without opening a browser.

## What it does

The menu bar shows the project you are on and how long you have been on it. Clicking the icon
drops down a panel with today's three blocks; clicking a block starts it, and clicking the one
that is running stops it. Starting a block while another runs switches — the server stops the
first one and says so.

Today's slots come from the web app's scheduler. This client does not book them; it tracks what
you already planned there.

## Requirements

- macOS 14 or newer
- An instance of the productivity app you can reach, and an API token from its account page
- Xcode Command Line Tools (`xcode-select --install`) — the full Xcode is not needed

## Build and install

```bash
make install
```

That compiles the binary, wraps it in `TimeTracker.app`, signs it and copies it to
`/Applications`. Then open it once from there and paste your server address and token into
Settings.

Other targets:

| Command | What it does |
|---|---|
| `make build` | Compile the binary alone — the quickest check that the code is valid |
| `make app` | Assemble `build/TimeTracker.app` without installing it |
| `make run` | Rebuild and relaunch, replacing a running copy |
| `make uninstall` | Quit it and remove it from `/Applications` |
| `make clean` | Throw away every build product |

## How a macOS app is put together

Coming from a web app, three things are different and worth knowing:

**There is no server and no deploy.** The product is a file. `swift build` compiles the Swift
sources into one native binary, and the `Makefile` then builds a directory around it:

```
TimeTracker.app/
  Contents/
    Info.plist           # the manifest: bundle id, version, what kind of app this is
    MacOS/TimeTracker    # the compiled binary
    Resources/           # assets, if there were any
```

Finder shows that directory as a single file. `open`ing it runs the binary inside.

**`Info.plist` is the config that macOS itself reads**, before your code runs. Two entries here
matter: `LSUIElement` is what makes this a menu bar app rather than a windowed one — no Dock
icon, no ⌘-Tab entry — and `NSAppTransportSecurity` reopens plain `http` for the local network,
so a dev instance on `127.0.0.1:5001` works while a public `http` server still does not.

**Signing is not optional, even locally.** `make app` signs the bundle ad-hoc (`codesign -s -`),
which costs nothing and works only on this Mac. It is not ceremony: macOS remembers granted
permissions against an app's signature and bundle id, so an unsigned app would be treated as a
different app after every rebuild and lose whatever you granted it. Handing the app to someone
else is the case that needs a paid Developer ID certificate and notarisation.

## Layout

| Path | What it holds |
|---|---|
| `Package.swift` | The target and its (currently no) dependencies — the `requirements.txt` of this world |
| `Makefile` | Compiles, bundles, signs, installs |
| `Resources/Info.plist` | The bundle manifest described above |
| `Sources/TimeTracker/TimeTrackerApp.swift` | Entry point: the menu bar scene and the shared objects |
| `Sources/TimeTracker/Models.swift` | The API's JSON, as Swift types |
| `Sources/TimeTracker/APIClient.swift` | Every request to the server, and every way one can fail |
| `Sources/TimeTracker/TimerStore.swift` | The state the views read, the clock and the polling |
| `Sources/TimeTracker/AppSettings.swift` | Server address and token |
| `Sources/TimeTracker/Keychain.swift` | Where the token is kept |
| `Sources/TimeTracker/Views/` | The menu bar label, the panel, one slot row, settings |

## Two decisions worth knowing

**The Keychain is never read while the app starts.** A Keychain read can stop dead waiting for
the system's "allow access" panel, and one on the launch path takes the whole app with it — no
menu bar item, no window, nothing to click. `AppSettings.load()` runs off the main thread, and
the first refresh waits for it.

**The elapsed time is counted here, not fetched.** The server sends the instant a timer started;
the menu bar counts from it. Otherwise showing a live clock would mean asking the server every
second what the time is.

## Debugging

There is no terminal to print to. The app logs through `os.Logger`:

```bash
log stream --predicate 'subsystem == "com.szymonels.timetracker"' --info --debug
```
