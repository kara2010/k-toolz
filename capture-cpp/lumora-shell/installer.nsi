; K-Toolz - NSIS-Installer der C++-Shell. EIN Installer fuer alle Produkte (byte-identisch):
; der DATEINAME entscheidet, was eingeschaltet wird ($EXEFILE, siehe .onInit):
;   PlainOSD-Setup-*.exe / StreamToFriend-Setup-*.exe / StutterHunter-Setup-*.exe /
;   WheelToPad-Setup-*.exe  -> Produktmodus: keine Auswahlseite, Willkommensseite mit
;                              Produktname, Startmenue-Eintrag des Produkts, Erststart im Modus.
;   K-Toolz-Setup-*.exe (und jeder andere Name, auch der Update-Feed) -> Auswahlseite
;                              "Was moechtest du nutzen?", alles vorausgewaehlt.
; Installiert wird IMMER alles; die Auswahl steuert nur die Modulwahl, die die Shell beim
; ersten Start aus HKCU\Software\K-Toolz uebernimmt (InstallModules = Erstinstallation,
; AddModules = Produkt-Installer auf bestehender Installation fuegt nur das Werkzeug hinzu).
; Modi (automatisch erkannt):
;   UPDATE   -> Installation vorhanden (k-toolz / lumora-native / lumora): gleiches Verzeichnis,
;               keine Fragen, Modulwahl bleibt (Basis fuer das stille Auto-Update /S).
;   FRISCH   -> nach $LOCALAPPDATA\Programs\k-toolz.
; Eine Electron-Altinstallation (Lumora.exe) wird ueber ihren Uninstaller sauber abgeloest.
; Deinstallation: fragt (ausser bei /S), ob Einstellungen (%APPDATA%\lumora) mit weg sollen.
; Aufruf: makensis /DVERSION=x.y.z /DSRCDIR=<Staging> installer.nsi
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "x64.nsh"   ; DisableX64FSRedirection: 64-bit-System32 aus dem 32-bit-Installer sehen

!ifndef VERSION
  !define VERSION "0.1.0"
!endif
!ifndef SRCDIR
  !define SRCDIR "stage"
!endif

Name "K-Toolz ${VERSION}"
OutFile "K-Toolz-Setup-${VERSION}.exe"
RequestExecutionLevel user
SetCompressor /SOLID lzma

; Versionsressource des Installers (Explorer-Eigenschaften, SmartScreen-Anzeige, Task-Manager)
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "K-Toolz"
VIAddVersionKey "FileDescription" "K-Toolz Setup"
VIAddVersionKey "CompanyName" "Karsten Radermacher"
VIAddVersionKey "LegalCopyright" "Karsten Radermacher"
VIAddVersionKey "FileVersion" "${VERSION}.0"
VIAddVersionKey "ProductVersion" "${VERSION}.0"

Var Migrate          ; "1" = alter Electron-Namensraum (Ordner lumora, Uninstall-Key lumora)
Var IsUpdate         ; "1" = Installation war schon da (Update-Lauf)
Var WasLumora        ; "1" = Bestandsinstallation aus Lumora-Zeiten (Ordner lumora-native/lumora)
Var Mode             ; Produktschluessel aus dem Dateinamen: osd/stream/stutter/wheel - oder "all"
Var ProdName         ; Anzeigename fuer Willkommen/Finish: Produktname oder "K-Toolz"
Var RunArgs          ; Startargumente fuer "jetzt starten" (--mode=<modul> im Produktmodus)
Var ModOsd
Var ModStream
Var ModStutter
Var ModWheel
Var ModLauncher
Var ModList          ; Komma-Liste der gewaehlten Module
Var ModCount
Var Dlg
Var CbOsd
Var CbStream
Var CbStutter
Var CbWheel
Var CbLauncher

; --- Optik: K-Toolz-Logo, Welcome/Finish-Bitmap (164x314), Kopfbild (150x57) ---
!define MUI_ICON "app.ico"
!define MUI_UNICON "app.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "installer-welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "installer-welcome.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "installer-header.bmp"
!define MUI_HEADERIMAGE_RIGHT
!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "$(S_WelcomeTitle)"
!define MUI_WELCOMEPAGE_TEXT "$(S_WelcomeText)"
!insertmacro MUI_PAGE_WELCOME
Page custom modPage modPageLeave
!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\lumora-shell.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "$RunArgs"
!define MUI_FINISHPAGE_RUN_TEXT "$(S_RunNow)"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

LangString S_WelcomeTitle ${LANG_GERMAN} "Willkommen bei $ProdName"
LangString S_WelcomeTitle ${LANG_ENGLISH} "Welcome to $ProdName"
LangString S_WelcomeText ${LANG_GERMAN} "$(S_Pitch)$\r$\n$\r$\nK-Toolz ist Open Source (AGPL v3), kostenlos und besteht aus eigenem, signiertem Code. Kein Konto, keine Registrierung.$\r$\n$\r$\nKlicke auf Weiter, um fortzufahren."
LangString S_WelcomeText ${LANG_ENGLISH} "$(S_Pitch)$\r$\n$\r$\nK-Toolz is open source (AGPL v3), free and consists of our own signed code. No account, no registration.$\r$\n$\r$\nClick Next to continue."
LangString S_PitchAll ${LANG_GERMAN} "Vier Werkzeuge und ein Launcher fuer PC-Gamer in einem Download: PlainOSD (FPS-Overlay), StreamToFriend (Streaming an Freunde), StutterHunter (Ruckler-Analyse), WheelToPad (Lenkrad als Gamepad) und ein Launcher fuer alle deine Spiele."
LangString S_PitchAll ${LANG_ENGLISH} "Four tools and one launcher for PC gamers in a single download: PlainOSD (FPS overlay), StreamToFriend (streaming to friends), StutterHunter (stutter analysis), WheelToPad (wheel as gamepad) and a launcher for all your games."
LangString S_PitchOsd ${LANG_GERMAN} "FPS, Temperaturen und Auslastung als Overlay im Spiel - ohne Afterburner, ohne Konto. Teil von K-Toolz: die anderen Werkzeuge bleiben abgeschaltet, bis du sie in den Einstellungen einschaltest."
LangString S_PitchOsd ${LANG_ENGLISH} "FPS, temperatures and load as an in-game overlay - no Afterburner, no account. Part of K-Toolz: the other tools stay switched off until you enable them in the settings."
LangString S_PitchStream ${LANG_GERMAN} "Dein Spiel an Freunde streamen - direkt vom PC, ohne Konto. Teil von K-Toolz: die anderen Werkzeuge bleiben abgeschaltet, bis du sie in den Einstellungen einschaltest."
LangString S_PitchStream ${LANG_ENGLISH} "Stream your game to friends - straight from your PC, no account. Part of K-Toolz: the other tools stay switched off until you enable them in the settings."
LangString S_PitchStutter ${LANG_GERMAN} "Findet heraus, warum dein Spiel ruckelt: Frametimes, Treiber-Latenzen und Hintergrundprogramme mit Befund. Teil von K-Toolz: die anderen Werkzeuge bleiben abgeschaltet, bis du sie in den Einstellungen einschaltest."
LangString S_PitchStutter ${LANG_ENGLISH} "Finds out why your game stutters: frame times, driver latencies and background programs with a verdict. Part of K-Toolz: the other tools stay switched off until you enable them in the settings."
LangString S_PitchWheel ${LANG_GERMAN} "Lenkrad oder Joystick als Xbox-Controller fuer jedes Spiel. Teil von K-Toolz: die anderen Werkzeuge bleiben abgeschaltet, bis du sie in den Einstellungen einschaltest."
LangString S_PitchWheel ${LANG_ENGLISH} "Wheel or joystick as an Xbox controller for any game. Part of K-Toolz: the other tools stay switched off until you enable them in the settings."
LangString S_Pitch ${LANG_GERMAN} "$(S_PitchAll)"
LangString S_Pitch ${LANG_ENGLISH} "$(S_PitchAll)"
LangString S_ModTitle ${LANG_GERMAN} "Was moechtest du nutzen?"
LangString S_ModTitle ${LANG_ENGLISH} "What would you like to use?"
LangString S_ModSub ${LANG_GERMAN} "Es wird immer alles installiert (3,8 MB). Du kannst jedes Werkzeug spaeter in den Einstellungen ein- oder ausschalten."
LangString S_ModSub ${LANG_ENGLISH} "Everything is always installed (3.8 MB). You can switch every tool on or off later in the settings."
LangString S_ModOsd ${LANG_GERMAN} "PlainOSD - FPS, Temperaturen und Auslastung als Overlay im Spiel"
LangString S_ModOsd ${LANG_ENGLISH} "PlainOSD - FPS, temperatures and load as an in-game overlay"
LangString S_ModStream ${LANG_GERMAN} "StreamToFriend - dein Spiel an Freunde streamen, ohne Konto"
LangString S_ModStream ${LANG_ENGLISH} "StreamToFriend - stream your game to friends, no account"
LangString S_ModStutter ${LANG_GERMAN} "StutterHunter - findet heraus, warum dein Spiel ruckelt"
LangString S_ModStutter ${LANG_ENGLISH} "StutterHunter - finds out why your game stutters"
LangString S_ModWheel ${LANG_GERMAN} "WheelToPad - Lenkrad oder Joystick als Xbox-Controller"
LangString S_ModWheel ${LANG_ENGLISH} "WheelToPad - wheel or joystick as an Xbox controller"
LangString S_ModLauncher ${LANG_GERMAN} "Launcher - alle deine Spiele aus Steam, Epic, GOG && Co. in einer Bibliothek"
LangString S_ModLauncher ${LANG_ENGLISH} "Launcher - all your games from Steam, Epic, GOG && co. in one library"
LangString S_ModNone ${LANG_GERMAN} "Bitte mindestens ein Werkzeug auswaehlen."
LangString S_ModNone ${LANG_ENGLISH} "Please select at least one tool."
LangString S_RunNow ${LANG_GERMAN} "$ProdName jetzt starten"
LangString S_RunNow ${LANG_ENGLISH} "Launch $ProdName now"
LangString S_RemoveData ${LANG_GERMAN} "Sollen auch deine Einstellungen, Spielzeiten und die Spiele-Bibliothek entfernt werden?$\n$\nJa = alles restlos entfernen ($APPDATA\lumora)$\nNein = Einstellungen behalten (empfohlen, falls du K-Toolz spaeter erneut installierst)"
LangString S_RemoveData ${LANG_ENGLISH} "Also remove your settings, playtimes and game library?$\n$\nYes = remove everything ($APPDATA\lumora)$\nNo = keep settings (recommended if you might reinstall K-Toolz later)"
LangString S_VcMissing ${LANG_GERMAN} "K-Toolz benoetigt die Microsoft Visual C++ Laufzeit, die auf diesem PC fehlt und gerade nicht geladen werden konnte (keine Internetverbindung?).$\n$\nBitte einmal 'Microsoft Visual C++ Redistributable (x64)' installieren - danach startet K-Toolz normal."
LangString S_VcMissing ${LANG_ENGLISH} "K-Toolz needs the Microsoft Visual C++ runtime, which is missing on this PC and could not be downloaded right now (no internet connection?).$\n$\nPlease install 'Microsoft Visual C++ Redistributable (x64)' once - K-Toolz will then start normally."

; Verzeichnis-Seite bei Updates ueberspringen (Ziel steht fest)
Function dirPre
  ${If} $IsUpdate == "1"
    Abort
  ${EndIf}
FunctionEnd

; Produkt aus dem eigenen Dateinamen (StrCmp vergleicht ohne Gross/Klein)
Function detectMode
  StrCpy $Mode "all"
  StrCpy $ProdName "K-Toolz"
  StrCpy $RunArgs ""
  StrCpy $0 $EXEFILE 9
  StrCmp $0 "PlainOSD-" 0 +4
    StrCpy $Mode "osd"
    StrCpy $ProdName "PlainOSD"
    Goto modeDone
  StrCpy $0 $EXEFILE 15
  StrCmp $0 "StreamToFriend-" 0 +4
    StrCpy $Mode "stream"
    StrCpy $ProdName "StreamToFriend"
    Goto modeDone
  StrCpy $0 $EXEFILE 14
  StrCmp $0 "StutterHunter-" 0 +4
    StrCpy $Mode "stutter"
    StrCpy $ProdName "StutterHunter"
    Goto modeDone
  StrCpy $0 $EXEFILE 11
  StrCmp $0 "WheelToPad-" 0 +4
    StrCpy $Mode "wheel"
    StrCpy $ProdName "WheelToPad"
    Goto modeDone
modeDone:
  ${If} $Mode != "all"
    StrCpy $RunArgs "--mode=$Mode"
  ${EndIf}
FunctionEnd

Function .onInit
  Call detectMode
  ; Vorauswahl: Produktmodus = nur das Produkt, sonst alles
  ${If} $Mode == "all"
    StrCpy $ModOsd "1"
    StrCpy $ModStream "1"
    StrCpy $ModStutter "1"
    StrCpy $ModWheel "1"
    StrCpy $ModLauncher "1"
  ${Else}
    StrCpy $ModOsd "0"
    StrCpy $ModStream "0"
    StrCpy $ModStutter "0"
    StrCpy $ModWheel "0"
    StrCpy $ModLauncher "0"
    ${If} $Mode == "osd"
      StrCpy $ModOsd "1"
    ${ElseIf} $Mode == "stream"
      StrCpy $ModStream "1"
    ${ElseIf} $Mode == "stutter"
      StrCpy $ModStutter "1"
    ${ElseIf} $Mode == "wheel"
      StrCpy $ModWheel "1"
    ${EndIf}
  ${EndIf}

  ; --- 1) UPDATE-Erkennung: Installation schon da? (lumora-shell.exe = Marker) ---
  StrCpy $IsUpdate "0"
  StrCpy $Migrate "0"
  StrCpy $WasLumora "0"
  ${If} ${FileExists} "$LOCALAPPDATA\Programs\k-toolz\lumora-shell.exe"
    StrCpy $IsUpdate "1"
    StrCpy $INSTDIR "$LOCALAPPDATA\Programs\k-toolz"
    Goto lbl_done
  ${EndIf}
  ${If} ${FileExists} "$LOCALAPPDATA\Programs\lumora-native\lumora-shell.exe"
    StrCpy $IsUpdate "1"
    StrCpy $WasLumora "1"
    StrCpy $INSTDIR "$LOCALAPPDATA\Programs\lumora-native"
    Goto lbl_done
  ${EndIf}
  ${If} ${FileExists} "$LOCALAPPDATA\Programs\lumora\lumora-shell.exe"
    StrCpy $IsUpdate "1"
    StrCpy $Migrate "1"
    StrCpy $WasLumora "1"
    StrCpy $INSTDIR "$LOCALAPPDATA\Programs\lumora"
    Goto lbl_done
  ${EndIf}

  ; --- 2) Frische Installation: Sprachauswahl (entfaellt bei /S), eigener Ordner ---
  !insertmacro MUI_LANGDLL_DISPLAY
  StrCpy $INSTDIR "$LOCALAPPDATA\Programs\k-toolz"
lbl_done:
  ; Willkommens-Text je Produkt (LangStrings werden erst jetzt aufgeloest)
  ${If} $Mode == "osd"
    StrCpy $1 "$(S_PitchOsd)"
  ${ElseIf} $Mode == "stream"
    StrCpy $1 "$(S_PitchStream)"
  ${ElseIf} $Mode == "stutter"
    StrCpy $1 "$(S_PitchStutter)"
  ${ElseIf} $Mode == "wheel"
    StrCpy $1 "$(S_PitchWheel)"
  ${Else}
    StrCpy $1 "$(S_PitchAll)"
  ${EndIf}
  ; $(S_Pitch) verweist auf $(S_PitchAll); fuer den Produkttext den Welcome-Text direkt setzen
  ${If} $Mode != "all"
    StrCpy $ProdName $ProdName
  ${EndIf}
FunctionEnd

; --- Auswahlseite: nur bei neutralem Namen, frischer Installation, nicht still ---
Function modPage
  ${If} $Mode != "all"
    Abort
  ${EndIf}
  ${If} $IsUpdate == "1"
    Abort
  ${EndIf}
  ${If} ${Silent}
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "$(S_ModTitle)" "$(S_ModSub)"
  nsDialogs::Create 1018
  Pop $Dlg
  ${If} $Dlg == error
    Abort
  ${EndIf}
  ${NSD_CreateCheckbox} 0 8u 100% 12u "$(S_ModOsd)"
  Pop $CbOsd
  ${NSD_Check} $CbOsd
  ${NSD_CreateCheckbox} 0 26u 100% 12u "$(S_ModStream)"
  Pop $CbStream
  ${NSD_Check} $CbStream
  ${NSD_CreateCheckbox} 0 44u 100% 12u "$(S_ModStutter)"
  Pop $CbStutter
  ${NSD_Check} $CbStutter
  ${NSD_CreateCheckbox} 0 62u 100% 12u "$(S_ModWheel)"
  Pop $CbWheel
  ${NSD_Check} $CbWheel
  ${NSD_CreateCheckbox} 0 80u 100% 12u "$(S_ModLauncher)"
  Pop $CbLauncher
  ${NSD_Check} $CbLauncher
  nsDialogs::Show
FunctionEnd

Function modPageLeave
  ${NSD_GetState} $CbOsd $ModOsd
  ${NSD_GetState} $CbStream $ModStream
  ${NSD_GetState} $CbStutter $ModStutter
  ${NSD_GetState} $CbWheel $ModWheel
  ${NSD_GetState} $CbLauncher $ModLauncher
  ${If} $ModOsd != 1
  ${AndIf} $ModStream != 1
  ${AndIf} $ModStutter != 1
  ${AndIf} $ModWheel != 1
  ${AndIf} $ModLauncher != 1
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(S_ModNone)"
    Abort
  ${EndIf}
FunctionEnd

; Komma-Liste + Anzahl aus den Schaltern; Anzeigename-Regel: genau eins -> Produktname
Function buildModList
  StrCpy $ModList ""
  StrCpy $ModCount 0
  ${If} $ModOsd == 1
    StrCpy $ModList "$ModList,osd"
    IntOp $ModCount $ModCount + 1
    StrCpy $ProdName "PlainOSD"
    StrCpy $RunArgs "--mode=osd"
  ${EndIf}
  ${If} $ModStream == 1
    StrCpy $ModList "$ModList,stream"
    IntOp $ModCount $ModCount + 1
    StrCpy $ProdName "StreamToFriend"
    StrCpy $RunArgs "--mode=stream"
  ${EndIf}
  ${If} $ModStutter == 1
    StrCpy $ModList "$ModList,stutter"
    IntOp $ModCount $ModCount + 1
    StrCpy $ProdName "StutterHunter"
    StrCpy $RunArgs "--mode=stutter"
  ${EndIf}
  ${If} $ModWheel == 1
    StrCpy $ModList "$ModList,wheel"
    IntOp $ModCount $ModCount + 1
    StrCpy $ProdName "WheelToPad"
    StrCpy $RunArgs "--mode=wheel"
  ${EndIf}
  ${If} $ModLauncher == 1
    StrCpy $ModList "$ModList,launcher"
    IntOp $ModCount $ModCount + 1
    StrCpy $ProdName "K-Toolz Launcher"
    StrCpy $RunArgs "--mode=launcher"
  ${EndIf}
  StrCpy $ModList $ModList "" 1   ; fuehrendes Komma weg
  ${If} $ModCount != 1
    StrCpy $ProdName "K-Toolz"
    StrCpy $RunArgs ""
  ${EndIf}
FunctionEnd

; Startmenue-Eintrag eines Werkzeugs: $0 = Name, $1 = Modulschluessel, $2 = Icon-Datei
!macro ToolShortcut name key icofile
  CreateShortCut "$SMPROGRAMS\${name}.lnk" "$INSTDIR\lumora-shell.exe" "--mode=${key}" "$INSTDIR\icons\${icofile}.ico" 0
!macroend

Section "K-Toolz"
  ; Laufende App IMMER beenden (sonst sperrt lumora-shell.exe das Kopieren)
  DetailPrint "Beende laufende K-Toolz-Prozesse..."
  nsExec::Exec 'taskkill /F /IM lumora-shell.exe'
  nsExec::Exec 'taskkill /F /IM lumora-capture-native.exe'
  nsExec::Exec 'taskkill /F /IM lumora-media-relay.exe'
  Sleep 400

  ; Geplante Aufgaben (Broker) entfernen - GEMESSEN: ohne Erhoehung "Zugriff verweigert", die Zeilen
  ; wirken also nur, wenn jemand den Installer als Administrator startet. Der verlaessliche Weg ist
  ; die App: jede erhoehte Registrierung loescht die alten Namen mit (kUnregisterLegacy in main.cpp).
  nsExec::Exec 'schtasks /Delete /F /TN K-Toolz-FPS'
  nsExec::Exec 'schtasks /Delete /F /TN K-Toolz-Sensors'
  nsExec::Exec 'schtasks /Delete /F /TN K-Toolz-Analyze'
  ; Namen aus Lumora-Zeiten (Bestandsinstallationen)
  nsExec::Exec 'schtasks /Delete /F /TN LumoraOSD-FPS'
  nsExec::Exec 'schtasks /Delete /F /TN LumoraOSD-Sensors'
  nsExec::Exec 'schtasks /Delete /F /TN LumoraOSD-Analyze'

  ; --- Electron-Altinstallation (Lumora.exe) sauber abloesen ---
  ${If} ${FileExists} "$LOCALAPPDATA\Programs\lumora\Uninstall Lumora.exe"
  ${AndIfNot} $INSTDIR == "$LOCALAPPDATA\Programs\lumora"
    DetailPrint "Deinstalliere die alte Lumora-Version (Electron)..."
    nsExec::Exec 'taskkill /F /IM Lumora.exe'
    Sleep 700
    ExecWait '"$LOCALAPPDATA\Programs\lumora\Uninstall Lumora.exe" /S _?=$LOCALAPPDATA\Programs\lumora'
    Sleep 500
    RMDir /r "$LOCALAPPDATA\Programs\lumora"
    DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "com.lumora.app"
  ${EndIf}
  ${If} $Migrate == "1"
    nsExec::Exec 'taskkill /F /IM Lumora.exe'
    Sleep 700
    ${If} ${FileExists} "$INSTDIR\Uninstall Lumora.exe"
      DetailPrint "Deinstalliere die vorhandene Electron-Version..."
      ExecWait '"$INSTDIR\Uninstall Lumora.exe" /S _?=$INSTDIR'
      Sleep 500
      Delete "$INSTDIR\Uninstall Lumora.exe"
      RMDir /r "$INSTDIR\resources"
      RMDir /r "$INSTDIR\locales"
      Delete "$INSTDIR\Lumora.exe"
      Delete "$INSTDIR\*.pak"
    ${EndIf}
    DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "com.lumora.app"
  ${EndIf}

  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}\*.*"

  ; WebView2-Runtime pruefen (Evergreen, per-machine ODER per-user); fehlt sie, installiert
  ; der mitgelieferte Microsoft-Bootstrapper sie nach (Win10-Absicherung).
  ReadRegStr $0 HKLM "SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  StrCmp $0 "" 0 wv2ok
  ReadRegStr $0 HKCU "SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  StrCmp $0 "" 0 wv2ok
  DetailPrint "WebView2-Runtime wird installiert..."
  ExecWait '"$INSTDIR\MicrosoftEdgeWebview2Setup.exe" /silent /install'
wv2ok:

  ; Visual-C++-Laufzeit (vcruntime140/msvcp140): auf fast allen Win11-Maschinen vorhanden;
  ; fuer die Ausnahmen das offizielle Redist nachladen (on-demand, nicht gebundelt).
  ${If} ${RunningX64}
    StrCpy $1 ""
    ${DisableX64FSRedirection}
    ${IfNot} ${FileExists} "$SYSDIR\vcruntime140.dll"
      StrCpy $1 "fehlt"
    ${ElseIfNot} ${FileExists} "$SYSDIR\msvcp140.dll"
      StrCpy $1 "fehlt"
    ${EndIf}
    ${EnableX64FSRedirection}
    ${If} $1 == "fehlt"
      DetailPrint "Visual-C++-Laufzeit fehlt - wird von Microsoft geladen..."
      nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile \"$TEMP\vc_redist.x64.exe\" -UseBasicParsing } catch { exit 1 }"'
      Pop $2
      ${If} ${FileExists} "$TEMP\vc_redist.x64.exe"
        DetailPrint "Visual-C++-Laufzeit wird installiert..."
        ExecWait '"$TEMP\vc_redist.x64.exe" /install /quiet /norestart'
        Delete "$TEMP\vc_redist.x64.exe"
      ${Else}
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(S_VcMissing)"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ; --- Modulwahl an die Shell uebergeben + Verknuepfungen ---
  Call buildModList
  ${If} $IsUpdate == "0"
    ; Erstinstallation: Auswahl (Kachelseite oder Produktname) -> InstallModules
    WriteRegStr HKCU "Software\K-Toolz" "InstallModules" "$ModList"
    ${If} $ModOsd == 1
      !insertmacro ToolShortcut "PlainOSD" "osd" "plainosd"
    ${EndIf}
    ${If} $ModStream == 1
      !insertmacro ToolShortcut "StreamToFriend" "stream" "streamtofriend"
    ${EndIf}
    ${If} $ModStutter == 1
      !insertmacro ToolShortcut "StutterHunter" "stutter" "stutterhunter"
    ${EndIf}
    ${If} $ModWheel == 1
      !insertmacro ToolShortcut "WheelToPad" "wheel" "wheeltopad"
    ${EndIf}
    ${If} $ModLauncher == 1
      !insertmacro ToolShortcut "K-Toolz Launcher" "launcher" "k-toolz"
    ${EndIf}
    ${If} $ModCount == 1
      ; ein Werkzeug: Desktop heisst wie das Werkzeug, startet im Modus
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\$Mode.ico" 0
    ${Else}
      CreateShortCut "$SMPROGRAMS\K-Toolz.lnk" "$INSTDIR\lumora-shell.exe" "" "$INSTDIR\icons\k-toolz.ico" 0
      CreateShortCut "$DESKTOP\K-Toolz.lnk" "$INSTDIR\lumora-shell.exe" "" "$INSTDIR\icons\k-toolz.ico" 0
    ${EndIf}
  ${Else}
    ; Update: Modulwahl bleibt. Produkt-Installer auf bestehender Installation fuegt sein
    ; Werkzeug hinzu (die Shell mischt AddModules beim naechsten Start ein).
    ${If} $Mode != "all"
      WriteRegStr HKCU "Software\K-Toolz" "AddModules" "$Mode"
    ${EndIf}
    ; Startmenue zieht die Shell beim Start nach (je aktivem Werkzeug, Suite ab zwei).
    StrCpy $ProdName "K-Toolz"
    StrCpy $RunArgs ""
  ${EndIf}

  ; Desktop-Icon im Produktmodus bei einer frischen Einzelinstallation: Icon-Datei heisst
  ; nach dem PNG-Namen, nicht nach dem Schluessel - Zuordnung hier nachziehen
  ${If} $IsUpdate == "0"
  ${AndIf} $ModCount == 1
    ${If} $Mode == "osd"
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\plainosd.ico" 0
    ${ElseIf} $Mode == "stream"
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\streamtofriend.ico" 0
    ${ElseIf} $Mode == "stutter"
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\stutterhunter.ico" 0
    ${ElseIf} $Mode == "wheel"
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\wheeltopad.ico" 0
    ${Else}
      CreateShortCut "$DESKTOP\$ProdName.lnk" "$INSTDIR\lumora-shell.exe" "$RunArgs" "$INSTDIR\icons\k-toolz.ico" 0
    ${EndIf}
  ${EndIf}

  ; --- Umsteiger von Lumora: alte Verknuepfungen weg, EINE Uebergangs-Verknuepfung im Startmenue
  ;     ("Lumora (jetzt K-Toolz)", nur dieses Release - der naechste Installer loescht sie wieder),
  ;     Desktop "Lumora" wird zu "K-Toolz". Apps & Features sagt "(frueher Lumora)". ---
  ${If} $WasLumora == "1"
    Delete "$SMPROGRAMS\Lumora.lnk"
    CreateShortCut "$SMPROGRAMS\Lumora (jetzt K-Toolz).lnk" "$INSTDIR\lumora-shell.exe" "" "$INSTDIR\icons\k-toolz.ico" 0
    ${If} ${FileExists} "$DESKTOP\Lumora.lnk"
      Delete "$DESKTOP\Lumora.lnk"
      CreateShortCut "$DESKTOP\K-Toolz.lnk" "$INSTDIR\lumora-shell.exe" "" "$INSTDIR\icons\k-toolz.ico" 0
    ${EndIf}
  ${EndIf}

  ; Apps & Features: EIN Eintrag "K-Toolz". Alte Schluessel der Lumora-Zeit entfernen.
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\lumora"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\lumora-native"
  ${If} $WasLumora == "1"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "DisplayName" "K-Toolz (früher Lumora)"
  ${Else}
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "DisplayName" "K-Toolz"
  ${EndIf}
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "Publisher" "Karsten Radermacher"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "DisplayIcon" "$INSTDIR\lumora-shell.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz" "URLInfoAbout" "https://k-toolz.de/"

  ; Tote Verknuepfungen aus der Umstiegszeit (Electron-AUMID, Beta-Namen)
  Delete "$SMPROGRAMS\Electron.lnk"
  Delete "$DESKTOP\Electron.lnk"
  Delete "$SMPROGRAMS\Lumora Native (Beta).lnk"
  Delete "$DESKTOP\Lumora Native (Beta).lnk"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Silent-Install = Auto-Update-Kontext: die App danach IMMER wieder starten
  ${If} ${Silent}
    Exec '"$INSTDIR\lumora-shell.exe"'
  ${EndIf}
SectionEnd

Section "Uninstall"
  nsExec::Exec 'taskkill /F /IM lumora-shell.exe'
  nsExec::Exec 'taskkill /F /IM lumora-capture-native.exe'
  nsExec::Exec 'taskkill /F /IM lumora-media-relay.exe'
  Sleep 400
  Delete "$SMPROGRAMS\K-Toolz.lnk"
  Delete "$DESKTOP\K-Toolz.lnk"
  Delete "$SMPROGRAMS\K-Toolz Launcher.lnk"
  Delete "$SMPROGRAMS\PlainOSD.lnk"
  Delete "$DESKTOP\PlainOSD.lnk"
  Delete "$SMPROGRAMS\StreamToFriend.lnk"
  Delete "$DESKTOP\StreamToFriend.lnk"
  Delete "$SMPROGRAMS\StutterHunter.lnk"
  Delete "$DESKTOP\StutterHunter.lnk"
  Delete "$SMPROGRAMS\WheelToPad.lnk"
  Delete "$DESKTOP\WheelToPad.lnk"
  Delete "$SMPROGRAMS\Lumora.lnk"
  Delete "$DESKTOP\Lumora.lnk"
  Delete "$SMPROGRAMS\Lumora (jetzt K-Toolz).lnk"
  Delete "$SMPROGRAMS\Lumora Native (Beta).lnk"
  Delete "$DESKTOP\Lumora Native (Beta).lnk"
  ; Autostart (neuer und alter Name), lumora://-Protokoll, Uebergabe-Schluessel
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "K-Toolz"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "Lumora"
  DeleteRegKey HKCU "Software\Classes\lumora"
  DeleteRegKey HKCU "Software\K-Toolz"
  ; von der App angelegte geplante Aufgaben (Broker) entfernen
  ; Erhoeht (eine UAC-Abfrage): die von der App angelegten Aufgaben lassen sich nur so entfernen.
  ; Lehnt der Nutzer ab, bleiben sie liegen - sie starten nichts von selbst (kein Ausloeser).
  nsExec::Exec 'powershell -NoProfile -WindowStyle Hidden -Command "Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList @(\"-NoProfile\",\"-Command\",\"Get-ScheduledTask -TaskName K-Toolz-FPS,K-Toolz-Sensors,K-Toolz-Analyze,LumoraOSD-FPS,LumoraOSD-Sensors,LumoraOSD-Analyze -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:0\")"'
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\k-toolz"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\lumora"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\lumora-native"

  ; Einstellungen: fragen (ausser Silent - dort IMMER behalten)
  ${IfNot} ${Silent}
    MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "$(S_RemoveData)" IDNO keepData
    RMDir /r "$APPDATA\lumora"
keepData:
  ${EndIf}
SectionEnd
