$ErrorActionPreference = 'Stop'
$NabuHome = if ($env:NABU_HOME) { $env:NABU_HOME } else { Join-Path $HOME 'Nabu' }
$Ref = if ($env:NABU_REF) { $env:NABU_REF } else { 'main' }
$Tools = Join-Path $NabuHome 'tools'
if ([Environment]::Is64BitOperatingSystem -eq $false -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { throw 'This installer supports Windows x64.' }
New-Item -ItemType Directory -Force -Path $NabuHome, (Join-Path $NabuHome 'bin'), (Join-Path $NabuHome 'cases'), (Join-Path $NabuHome 'projects'), (Join-Path $NabuHome 'reports'), (Join-Path $NabuHome 'samples'), $Tools | Out-Null
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Windows Package Manager (winget) is required.' }
function Ensure-WinGetPackage($Id) {
    & winget list --id $Id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) { return }
    & winget install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "WinGet installation failed: $Id ($LASTEXITCODE)" }
}
Ensure-WinGetPackage 'Git.Git'
Ensure-WinGetPackage 'Python.Python.3.13'
Ensure-WinGetPackage 'Microsoft.OpenJDK.21'
$PythonCandidate = Join-Path $HOME 'AppData/Local/Programs/Python/Python313/python.exe'
$Python = if (Test-Path $PythonCandidate) { $PythonCandidate } else { (Get-Command python -ErrorAction Stop).Source }
$Venv = Join-Path $NabuHome 'venv'
& $Python -m venv $Venv
if ($LASTEXITCODE -ne 0) { throw "Python virtual environment creation failed." }
$VenvPython = Join-Path $Venv 'Scripts/python.exe'
& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "pip installation failed." }
& $VenvPython -m pip install --upgrade angr==9.2.186 semgrep==1.180.0
if ($LASTEXITCODE -ne 0) { throw "Analysis dependency installation failed." }
$GhidraHome = Join-Path $Tools 'ghidra'
if (-not (Test-Path (Join-Path $GhidraHome 'support/analyzeHeadless.bat'))) {
$Api = Invoke-RestMethod 'https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest'
$Asset = $Api.assets | Where-Object { $_.name -match 'PUBLIC.*\.zip$' } | Select-Object -First 1
if (-not $Asset) { throw 'Could not find a Ghidra release archive.' }
$Archive = Join-Path $Tools 'ghidra.zip'
Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Archive
if ($Asset.digest -notmatch '^sha256:([0-9a-fA-F]{64})$') { throw 'Ghidra release has no SHA-256 digest.' }
$Expected = $Matches[1].ToLowerInvariant()
$Actual = (Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($Actual -ne $Expected) { throw 'Ghidra archive checksum mismatch.' }
Expand-Archive -Path $Archive -DestinationPath $Tools -Force
$Extracted = Get-ChildItem $Tools -Directory | Where-Object { $_.Name -like 'ghidra_*_PUBLIC' } | Select-Object -First 1
if (-not $Extracted) { throw 'Ghidra archive did not contain the expected directory.' }
Move-Item $Extracted.FullName $GhidraHome
Remove-Item $Archive -Force
}
$RadareHome = Join-Path $Tools 'radare2'
$R2 = Get-ChildItem $RadareHome -Filter 'r2.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $R2) {
    $Release = Invoke-RestMethod 'https://api.github.com/repos/radareorg/radare2/releases/latest'
    $RadareAsset = $Release.assets | Where-Object { $_.name -match '^radare2-[0-9.]+-w64\.zip$' } | Select-Object -First 1
    if (-not $RadareAsset) { throw 'Windows radare2 archive was not found.' }
    $RadareArchive = Join-Path $Tools 'radare2.zip'
    Invoke-WebRequest $RadareAsset.browser_download_url -OutFile $RadareArchive
    if ($RadareAsset.digest -notmatch '^sha256:([0-9a-fA-F]{64})$') { throw 'radare2 release has no SHA-256 digest.' }
    if ((Get-FileHash $RadareArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Matches[1].ToLowerInvariant()) { throw 'radare2 archive checksum mismatch.' }
    Expand-Archive $RadareArchive -DestinationPath $RadareHome -Force
    Remove-Item $RadareArchive -Force
    $R2 = Get-ChildItem $RadareHome -Filter 'r2.exe' -Recurse | Select-Object -First 1
    if (-not $R2) { throw 'radare2 archive did not contain r2.exe.' }
}
$Raw = Join-Path $NabuHome 'nabu.py'
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nasimubd/Nabu/$Ref/scripts/nabu.py" -OutFile $Raw
$Headless = Join-Path $GhidraHome 'support/analyzeHeadless.bat'
$Jdk = Get-ChildItem 'C:/Program Files/Microsoft' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'jdk-21*' } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $Jdk) { throw 'OpenJDK 21 was installed but could not be located.' }
@"
`$env:NABU_HOME = '$NabuHome'
`$env:NABU_GHIDRA_HEADLESS = '$Headless'
`$env:JAVA_HOME = '$($Jdk.FullName)'
`$env:PATH = '$($R2.DirectoryName);C:/Program Files/Git/cmd;' + `$env:PATH
`$env:PATH = '$(Join-Path $NabuHome 'bin');$(Join-Path $Venv 'Scripts');' + `$env:PATH
& '$VenvPython' '$Raw' @args
"@ | Set-Content (Join-Path $NabuHome 'bin/nabu.ps1')
Write-Output "Nabu installed at $NabuHome"
Write-Output "Run: & '$(Join-Path $NabuHome 'bin/nabu.ps1')' doctor"

& (Join-Path $NabuHome "bin/nabu.ps1") doctor
if ($LASTEXITCODE -ne 0) { throw "Nabu environment verification failed." }
