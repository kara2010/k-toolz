# K-Toolz

🇬🇧 [English version](README.md)

Kostenlose Gaming-Werkzeuge für Windows, früher **Lumora**. Ein Download enthält
vier Werkzeuge und einen Spiele-Launcher. Jedes Werkzeug lässt sich einzeln
ein- und ausschalten.

| Werkzeug | Was es macht |
|---|---|
| **[PlainOSD](https://k-toolz.de/plainosd/)** | FPS, Frametimes, GPU- und CPU-Temperaturen, Last und Leistung über dem laufenden Spiel, ohne Afterburner |
| **[StreamToFriend](https://k-toolz.de/streamtofriend/)** | Link verschicken, Freunde schauen dein Spiel im Browser (Peer-to-Peer per WebRTC) |
| **[StutterHunter](https://k-toolz.de/stutterhunter/)** | Misst beim Spielen mit und nennt zu jedem Ruckler die wahrscheinliche Ursache in Klartext |
| **[WheelToPad](https://k-toolz.de/wheeltopad/)** | Macht aus Lenkrad, Joystick oder Flightstick einen virtuellen Xbox-Controller |
| **[Launcher](https://k-toolz.de/launcher/)** | Spiele aller Stores in einer Cover-Bibliothek, mit automatischem HDR und Gamepad-Steuerung |

Download & Infos: <https://k-toolz.de/>

<table>
<tr>
<td width="50%"><a href="https://k-toolz.de/plainosd/"><img src="https://k-toolz.de/overlay-einstellungen.webp" alt="PlainOSD-Einstellungen mit Overlay-Vorschau"></a><br><sub><b><a href="https://k-toolz.de/plainosd/">PlainOSD</a></b> – GPU, CPU & FPS live über dem Spiel</sub></td>
<td width="50%"><a href="https://k-toolz.de/streamtofriend/"><img src="https://k-toolz.de/stream.webp" alt="StreamToFriend mit Live-Vorschau und Teilen-Link"></a><br><sub><b><a href="https://k-toolz.de/streamtofriend/">StreamToFriend</a></b> – Link verschicken, Freunde schauen im Browser zu</sub></td>
</tr>
<tr>
<td><a href="https://k-toolz.de/stutterhunter/"><img src="https://k-toolz.de/analyse.webp" alt="StutterHunter-Bericht mit Klartext-Urteil, Kennzahlen und Frametime-Kurve"></a><br><sub><b><a href="https://k-toolz.de/stutterhunter/">StutterHunter</a></b> – findet heraus, <i>warum</i> ein Spiel ruckelt</sub></td>
<td><a href="https://k-toolz.de/wheeltopad/"><img src="https://k-toolz.de/eingabe-bruecke.webp" alt="WheelToPad: Lenkrad als virtueller Xbox-Controller"></a><br><sub><b><a href="https://k-toolz.de/wheeltopad/">WheelToPad</a></b> – Lenkrad, Joystick oder Flightstick als Xbox-Pad</sub></td>
</tr>
</table>

## Funktionen

- **[PlainOSD](https://k-toolz.de/plainosd/)** – FPS, Frametimes, GPU- und CPU-Werte
  im Spiel (eigene ETW-basierte Frame-Messung), mehrere Designs, per Hotkey schaltbar.
- **[StreamToFriend](https://k-toolz.de/streamtofriend/)** – ein laufendes Spiel direkt
  an jeden Browser streamen (eigene C++-Aufnahme + Hardware-Encoder → eigenes
  WebRTC/WHEP-Relay). Standardmäßig Full HD (1080p60), auf Wunsch bis 4K; AV1 oder
  H.264 je nach Decoder des Zuschauers; direkte Peer-to-Peer-Verbindung (inklusive
  IPv6-Direktweg); Gruppen-Streams mit Raumcodes; auf Wunsch Zutrittsschutz, der vor
  jedem Zuschauer erst fragt. Dazu die [Portfreigabe-Anleitung](https://k-toolz.de/streamtofriend/portfreigabe/)
  und StreamToFriend als [Discord-Alternative fürs Screen-Sharing](https://k-toolz.de/streamtofriend/discord-alternative/).
- **[StutterHunter](https://k-toolz.de/stutterhunter/)** – zeichnet während einer
  Sitzung Frametimes, Hintergrundprogramme, Treiber-Latenzen und GPU-Zustand auf und
  nennt zu jedem Ruckler die wahrscheinliche Ursache.
- **[WheelToPad](https://k-toolz.de/wheeltopad/)** – macht aus Joystick, Lenkrad oder
  Flightstick einen virtuellen Xbox-360-Controller (über den signierten
  Open-Source-Treiber ViGEmBus), damit Geräte, die sich als DirectInput melden, auch in
  Spielen funktionieren, die nur XInput akzeptieren. Visuelle Belegung, Live-Monitor,
  Auto-Kalibrierung, Achse↔Trigger und Taste↔Achse, getrennte Geräte (Lenkrad +
  Pedale) und Profile pro Spiel.
- **[Launcher](https://k-toolz.de/launcher/)** – findet Spiele von Steam,
  Microsoft Store / Xbox, EA, Epic, GOG u. a.; Cover und Artwork kommen automatisch;
  automatisches HDR pro Spiel; Spielzeit-Erfassung; die ganze Oberfläche lässt sich
  mit einem Xbox-Controller bedienen ([Couch-Gaming](https://k-toolz.de/launcher/couch-gaming/)).
- **Signiert** – alle Programmdateien und der Installer sind digital signiert
  (Certum Code Signing).

## Technik

K-Toolz besteht aus nativen C++-Programmen (siehe [`capture-cpp/`](capture-cpp/)):

- **k-toolz.exe** (`capture-cpp/lumora-shell`) – die App selbst; zeigt die
  Web-Oberfläche (`index.html` / `styles.css`) in einem WebView2-Fenster und
  übernimmt Tray, Hotkeys, Autostart, Launcher-Scan und Steuerung.
- **k-toolz-capture.exe** (`capture-cpp/lumora-capture`) – Bildschirmaufnahme,
  Skalierung / HDR und Hardware-Encoding (NVENC / AMF / QSV, AV1 & H.264, Opus-Ton),
  ausgegeben als MPEG-TS über UDP.
- **k-toolz-relay.exe** (`capture-cpp/lumora-relay`) – das eingebaute
  WebRTC/WHEP-Relay (libdatachannel).
- **k-toolz-elevate.exe** (`capture-cpp/lumora-elevate`) – ein kleiner Einmal-Helfer
  für die wenigen Vorgänge, die erhöhte Rechte brauchen.

Der Installer bringt zwei signierte Treiber mit, die nur auf Wunsch und nach einer
Signaturprüfung installiert werden: [ViGEmBus](https://github.com/nefarius/ViGEmBus)
1.22.0 für WheelToPad und [PawnIO](https://pawnio.eu) 2.2.0 für CPU-Temperatur und
-Leistung in PlainOSD. Nutzerdaten liegen unter `%APPDATA%\K-Toolz\`; ein vorhandenes
`%APPDATA%\lumora\` wird einmalig dorthin verschoben. Den signierten NSIS-Installer
erzeugt [`capture-cpp/lumora-shell/build-installer.ps1`](capture-cpp/lumora-shell/build-installer.ps1).

### Entwicklung

Jedes Programm baut mit CMake (Visual Studio 2022, x64), z. B. die Shell:

```powershell
cmake -S capture-cpp/lumora-shell -B capture-cpp/lumora-shell/build -G "Visual Studio 17 2022" -A x64
cmake --build capture-cpp/lumora-shell/build --config Release
```

Den vollständigen signierten Installer (Shell + gestagte Helfer) baut:

```powershell
cd capture-cpp/lumora-shell
powershell -NoProfile -ExecutionPolicy Bypass -File ./build-installer.ps1
```

Hilfs- und Diagnose-Skripte liegen in [`_testlab/`](_testlab/) und sind vom
Build ausgeschlossen. Die Helfer-Binaries unter `bin/` sind nicht im Repo – sie
werden aus [`capture-cpp/`](capture-cpp/) gebaut. Die früheren
Electron-Einstiegspunkte (`main.js`, electron-builder) liegen noch als Alt-Pfad im
Baum, werden aber nicht mehr ausgeliefert.

## Autor

K-Toolz wird entwickelt und gepflegt von **Karsten Radermacher**
(GitHub: [kara2010](https://github.com/kara2010)).
Copyright © 2026 Karsten Radermacher.

## Lizenz

K-Toolz ist freie Software unter der **GNU Affero General Public License v3.0**
([LICENSE](LICENSE)). Das bedeutet: Du darfst den Code nutzen, verändern und
weitergeben – aber jede abgeleitete oder darauf aufbauende Software (auch als
Netzwerkdienst betrieben) muss ihren vollständigen Quellcode unter derselben
Lizenz offenlegen.

**Marke:** Die Namen „K-Toolz", „PlainOSD", „StreamToFriend", „StutterHunter",
„WheelToPad" und „Lumora", die Logos und das Erscheinungsbild sind **nicht** Teil
der Lizenz. Forks müssen unter eigenem Namen und Branding auftreten und dürfen
nicht den Eindruck erwecken, das offizielle K-Toolz zu sein oder mit ihm in
Verbindung zu stehen.

## Beiträge

Fehlerberichte und Vorschläge sind als GitHub-Issues willkommen!
**Pull Requests werden derzeit nicht angenommen** – K-Toolz bleibt bewusst ein
Ein-Personen-Projekt, damit der Autor die alleinige Urheberschaft (und damit
volle Lizenzhoheit über künftige Versionen) behält.
