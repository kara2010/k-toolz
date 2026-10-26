# K-Toolz

🇩🇪 [Deutsche Version](README.de.md)

Free gaming tools for Windows, formerly **Lumora**. One download contains four
tools plus a game launcher. Each tool can be switched on and off on its own.

| Tool | What it does |
|---|---|
| **[PlainOSD](https://k-toolz.de/en/plainosd/)** | FPS, frametimes, GPU and CPU temperatures, load and power over the running game, without Afterburner |
| **[StreamToFriend](https://k-toolz.de/en/streamtofriend/)** | Send a link, friends watch your game in the browser (peer-to-peer WebRTC) |
| **[StutterHunter](https://k-toolz.de/en/stutterhunter/)** | Measures while you play and names the likely cause of every stutter in plain language |
| **[WheelToPad](https://k-toolz.de/en/wheeltopad/)** | Turns a wheel, joystick or flight stick into a virtual Xbox controller |
| **[Launcher](https://k-toolz.de/en/launcher/)** | Games from all stores in one cover library, with automatic HDR and gamepad control |

Download & info: <https://k-toolz.de/en/>

<table>
<tr>
<td width="50%"><a href="https://k-toolz.de/en/plainosd/"><img src="https://k-toolz.de/overlay-einstellungen.webp" alt="PlainOSD settings with overlay preview"></a><br><sub><b><a href="https://k-toolz.de/en/plainosd/">PlainOSD</a></b> – GPU, CPU & FPS live over the game</sub></td>
<td width="50%"><a href="https://k-toolz.de/en/streamtofriend/"><img src="https://k-toolz.de/stream.webp" alt="StreamToFriend with live preview and share link"></a><br><sub><b><a href="https://k-toolz.de/en/streamtofriend/">StreamToFriend</a></b> – send a link, friends watch in the browser</sub></td>
</tr>
<tr>
<td><a href="https://k-toolz.de/en/stutterhunter/"><img src="https://k-toolz.de/analyse.webp" alt="StutterHunter report with verdict, key figures and frame time graph"></a><br><sub><b><a href="https://k-toolz.de/en/stutterhunter/">StutterHunter</a></b> – finds out <i>why</i> a game stutters</sub></td>
<td><a href="https://k-toolz.de/en/wheeltopad/"><img src="https://k-toolz.de/eingabe-bruecke.webp" alt="WheelToPad mapping a wheel to a virtual Xbox controller"></a><br><sub><b><a href="https://k-toolz.de/en/wheeltopad/">WheelToPad</a></b> – wheel, joystick or flight stick as a virtual Xbox pad</sub></td>
</tr>
</table>

## Features

- **[PlainOSD](https://k-toolz.de/en/plainosd/)** – FPS, frametimes, GPU and CPU
  readings in-game (own ETW-based frame timing), several designs, hotkey toggle.
- **[StreamToFriend](https://k-toolz.de/en/streamtofriend/)** – stream a running game
  straight to any browser (own C++ capture + hardware encoder → own WebRTC/WHEP
  relay). Full HD (1080p60) by default, up to 4K; AV1 or H.264 depending on the
  viewer's decoder; direct peer-to-peer connection (including an IPv6 direct path);
  group streams with room codes; optional access control that asks before anyone
  may watch. See the [port forwarding guide](https://k-toolz.de/en/streamtofriend/port-forwarding/)
  and StreamToFriend as a [Discord screen-share alternative](https://k-toolz.de/en/streamtofriend/discord-alternative/).
- **[StutterHunter](https://k-toolz.de/en/stutterhunter/)** – records frame times,
  background programs, driver latencies and GPU state during a session and names
  the likely cause of every stutter.
- **[WheelToPad](https://k-toolz.de/en/wheeltopad/)** – turns a joystick, wheel or
  flight stick into a virtual Xbox 360 controller (via the signed open-source driver
  ViGEmBus), so devices that report as DirectInput work in games that only accept
  XInput. Visual mapping, live input monitor, auto-calibration, axis↔trigger and
  button↔axis remapping, separate devices (wheel + pedals) and per-game profiles.
- **[Launcher](https://k-toolz.de/en/launcher/)** – finds games from Steam,
  Microsoft Store / Xbox, EA, Epic, GOG and more; covers and artwork are fetched
  automatically; automatic HDR per game; playtime tracking; the whole UI can be
  driven with an Xbox controller ([couch gaming](https://k-toolz.de/en/launcher/couch-gaming/)).
- **Signed** – all executables and the installer are digitally signed
  (Certum Code Signing).

## Technology

K-Toolz is a set of native C++ programs (see [`capture-cpp/`](capture-cpp/)):

- **k-toolz.exe** (`capture-cpp/lumora-shell`) – the app itself; hosts the web UI
  (`index.html` / `styles.css`) in a WebView2 window and owns tray, hotkeys,
  autostart, launcher scanning and orchestration.
- **k-toolz-capture.exe** (`capture-cpp/lumora-capture`) – screen capture,
  scaling / HDR and hardware encoding (NVENC / AMF / QSV, AV1 & H.264, Opus audio),
  published as MPEG-TS over UDP.
- **k-toolz-relay.exe** (`capture-cpp/lumora-relay`) – the built-in WebRTC/WHEP
  relay (libdatachannel).
- **k-toolz-elevate.exe** (`capture-cpp/lumora-elevate`) – a small one-shot helper
  for the few operations that need elevation.

The installer bundles two signed drivers, which are only installed on request
after a signature check: [ViGEmBus](https://github.com/nefarius/ViGEmBus) 1.22.0
for WheelToPad and [PawnIO](https://pawnio.eu) 2.2.0 for CPU
temperature and power in PlainOSD. User data lives under `%APPDATA%\K-Toolz\`;
an existing `%APPDATA%\lumora\` is moved there once. The signed NSIS installer is
produced by [`capture-cpp/lumora-shell/build-installer.ps1`](capture-cpp/lumora-shell/build-installer.ps1).

### Development

Each program builds with CMake (Visual Studio 2022, x64), e.g. the shell:

```powershell
cmake -S capture-cpp/lumora-shell -B capture-cpp/lumora-shell/build -G "Visual Studio 17 2022" -A x64
cmake --build capture-cpp/lumora-shell/build --config Release
```

The full signed installer (shell + staged helpers) is built via:

```powershell
cd capture-cpp/lumora-shell
powershell -NoProfile -ExecutionPolicy Bypass -File ./build-installer.ps1
```

Helper and diagnostic scripts live in [`_testlab/`](_testlab/) and are not
part of the build. Helper binaries under `bin/` are not committed; they are built
from [`capture-cpp/`](capture-cpp/). The former Electron entry points (`main.js`,
electron-builder) remain in the tree as a legacy path that is no longer shipped.

## Author

K-Toolz is developed and maintained by **Karsten Radermacher**
(GitHub: [kara2010](https://github.com/kara2010)).
Copyright © 2026 Karsten Radermacher.

## License

K-Toolz is free software under the **GNU Affero General Public License v3.0**
([LICENSE](LICENSE)). That means you may use, modify and redistribute the
code – but any derived software or software built on top of it (including
when operated as a network service) must publish its complete source code
under the same license.

**Trademark:** The names "K-Toolz", "PlainOSD", "StreamToFriend", "StutterHunter",
"WheelToPad" and "Lumora", the logos and the visual identity are **not** part of
the license. Forks must use their own name and branding and must not give the
impression of being the official K-Toolz or being affiliated with it.

## Contributing

Bug reports and suggestions are welcome as GitHub issues!
**Pull requests are currently not accepted** – K-Toolz deliberately remains a
one-person project so the author retains sole authorship (and with it full
licensing authority over future versions).
