$anonZipUrl = "https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.9.7/anon-live-windows-signed-amd64.zip"
$bootstrapScriptUrl = "https://raw.githubusercontent.com/cl0ten/win_anon_proxy_v2/refs/heads/main/src/bootstrap.ps1"
$iconUrl = "https://raw.githubusercontent.com/cl0ten/win_anon_proxy_v2/refs/heads/main/src/icon.ico"
$batchFileUrl = "https://raw.githubusercontent.com/cl0ten/win_anon_proxy_v2/refs/heads/main/src/start_proxy.bat"

$desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Anyone")
$srcPath = [System.IO.Path]::Combine($desktopPath, "src")
$anonZipPath = [System.IO.Path]::Combine($srcPath, "anon-temp.zip")
$shortcutPath = [System.IO.Path]::Combine($desktopPath, "Anyone Network Proxy.lnk")

if (!(Test-Path -Path $srcPath)) {
    New-Item -ItemType Directory -Path $srcPath | Out-Null
}

Write-Output "Downloading files..."
Invoke-WebRequest -Uri $anonZipUrl -OutFile $anonZipPath
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($anonZipPath, $srcPath)

$extractedAnonPath = [System.IO.Path]::Combine($srcPath, "anon.exe")
Remove-Item -Path $anonZipPath

Invoke-WebRequest -Uri $bootstrapScriptUrl -OutFile (Join-Path $srcPath "bootstrap.ps1")
Invoke-WebRequest -Uri $iconUrl -OutFile (Join-Path $srcPath "icon.ico")
Invoke-WebRequest -Uri $batchFileUrl -OutFile (Join-Path $srcPath "start_proxy.bat")

$batchFilePath = [System.IO.Path]::Combine($srcPath, "start_proxy.bat")
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $batchFilePath
$Shortcut.WorkingDirectory = $srcPath
$Shortcut.IconLocation = [System.IO.Path]::Combine($srcPath, "icon.ico")
$Shortcut.Save()

Write-Output "Installation complete! `nShortcut created in the Anyone folder on your desktop."
