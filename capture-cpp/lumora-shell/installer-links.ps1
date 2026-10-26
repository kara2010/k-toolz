# Wird vom Installer beim Update aufgerufen (installer.nsi): biegt Verknuepfungen des Nutzers, die noch auf
# die alte Programmdatei lumora-shell.exe zeigen, auf die neue k-toolz.exe um. Die App selbst schreibt bei jedem
# Start nur die Startmenue-Eintraege der Werkzeuge neu - Desktop-Verknuepfungen und an die Taskleiste angeheftete
# Eintraege wuerden sonst ins Leere zeigen. Die App-Kennung (AppUserModelID) der angehefteten Eintraege bleibt
# unveraendert, die Gruppierung in der Taskleiste bleibt also erhalten.
# Aufruf: powershell -NoProfile -ExecutionPolicy Bypass -File installer-links.ps1 -NewDir "<Installationsordner>"
param([Parameter(Mandatory = $true)][string]$NewDir, [string[]]$Roots)   # -Roots nur fuer Tests (Standard: Ordner des Nutzers)
$ErrorActionPreference = 'SilentlyContinue'
$exe = Join-Path $NewDir 'k-toolz.exe'
$sh = New-Object -ComObject WScript.Shell
$roots = if ($Roots) { $Roots } else { @(
  [Environment]::GetFolderPath('Desktop'),
  [Environment]::GetFolderPath('Programs'),
  (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'),
  (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu')
) }
$n = 0
foreach ($r in $roots) {
  if (-not $r -or -not (Test-Path $r)) { continue }
  foreach ($f in (Get-ChildItem -Path $r -Filter *.lnk -Recurse -ErrorAction SilentlyContinue)) {
    try {
      $l = $sh.CreateShortcut($f.FullName)
      if ($l.TargetPath -notmatch '\\lumora-shell\.exe$') { continue }
      $oldDir = Split-Path $l.TargetPath -Parent
      $l.TargetPath = $exe
      $l.WorkingDirectory = $NewDir
      $icon = [string]$l.IconLocation
      if ($icon.StartsWith($oldDir, [StringComparison]::OrdinalIgnoreCase)) {
        $l.IconLocation = (($NewDir + $icon.Substring($oldDir.Length)) -replace '\\lumora-shell\.exe', '\k-toolz.exe')
      }
      $l.Save()
      $n++
    } catch { }
  }
}
"Verknuepfungen umgestellt: $n"
