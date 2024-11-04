$zipUrl = "https://github.com/cl0ten/win_anon_proxy_v2/archive/refs/heads/main.zip"
$desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Anyone")
$zipPath = [System.IO.Path]::Combine($desktopPath, "temp.zip")
$shortcutPath = [System.IO.Path]::Combine($desktopPath, "Anyone Network Proxy.lnk")

if (!(Test-Path -Path $desktopPath)) {
    New-Item -ItemType Directory -Path $desktopPath | Out-Null
}

Write-Output "Downloading zip file..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

Write-Output "Extracting files..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $desktopPath)

Remove-Item -Path $zipPath

$batchFilePath = [System.IO.Path]::Combine($desktopPath, "win_anon_proxy_v2-main\start_proxy.bat")
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $batchFilePath
$Shortcut.WorkingDirectory = "$desktopPath\win_anon_proxy_v2-main"
$Shortcut.IconLocation = "$desktopPath\win_anon_proxy_v2-main\src\icon.ico"
$Shortcut.Save()

Write-Output "Installation complete! Shortcut created in the Anyone folder on your desktop."
