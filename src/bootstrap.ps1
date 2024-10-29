$tempFolder = [System.IO.Path]::GetTempPath()
$anonPath = "$PSScriptRoot\anon.exe"
$anonrcTempPath = Join-Path $tempFolder "anonrc"

function Create-Anonrc {
    $anonrcContent = @"
SocksPort 127.0.0.1:9050
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
DNSPort 53
HTTPTunnelPort 1080
ClientRejectInternalAddresses 1
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
"@
    Set-Content -Path $anonrcTempPath -Value $anonrcContent -Force
}

function Set-ProxySettings {
    param([bool]$EnableProxy)

    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    if ($EnableProxy) {
        Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value 1
        $proxyServerValue = "http=127.0.0.1:1080; https=127.0.0.1:1080; socks=127.0.0.1:9050"
        Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxyServerValue
        Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value "<local>"
        Write-Host "`nProxy has been enabled and configured to use the Anyone Network."
    }
    else {
        Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value 0
        Remove-ItemProperty -Path $registryPath -Name ProxyServer -ErrorAction SilentlyContinue
        Write-Host "Proxy has been disabled."
    }
}

function Start-AnonProxy {
    if (-not (Test-Path $anonPath)) {
        Write-Host "Error: Anon executable not found at $anonPath"
        return
    }

    Create-Anonrc

    $anonProcess = Get-Process anon -ErrorAction SilentlyContinue
    if ($anonProcess) {
        Write-Host "Anon is already running."
    } else {
        Start-Process -FilePath $anonPath -ArgumentList "-f $anonrcTempPath" -NoNewWindow
        Write-Host "Starting Anon proxy..."
        Start-Sleep -Seconds 5

        if (-not (Get-Process anon -ErrorAction SilentlyContinue)) {
            Write-Host "Failed to start Anon proxy. Exiting."
            return
        }
    }

    Set-ProxySettings -EnableProxy $true
}

function Stop-AnonProxy {
    $anonProcess = Get-Process anon -ErrorAction SilentlyContinue
    if ($anonProcess) {
        Stop-Process -Name anon -Force
        Write-Host "Anon proxy has been stopped."
    } else {
        Write-Host "Anon is not running."
    }

    Set-ProxySettings -EnableProxy $false
    Remove-Item -Path $anonrcTempPath -ErrorAction SilentlyContinue
    Write-Host "Temporary files have been cleaned up."
}

function Configure-FirewallRules {
    param([bool]$EnableRules)

    if ($EnableRules) {
        if (-not (Get-NetFirewallRule -DisplayName "Redirect-DNS-to-Anon" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Redirect-DNS-to-Anon" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Block
            Write-Host "`nFirewall rule added to redirect DNS traffic."
        }
    }
    else {
        Remove-NetFirewallRule -DisplayName "Redirect-DNS-to-Anon" -ErrorAction SilentlyContinue
        Write-Host "Firewall rule removed for DNS redirection."
    }
}

function Check-IP {
    param([bool]$UseProxy = $false)

    $checkUrl = "https://check.en.anyone.tech/"
    $proxyAddress = "http://127.0.0.1:1080"

    try {
        if ($UseProxy) {
            $response = Invoke-WebRequest -Uri $checkUrl -Proxy $proxyAddress
        } else {
            $response = Invoke-WebRequest -Uri $checkUrl
        }

        if ($response.Content -match 'Your IP address appears to be:.*?<strong>(.*?)<\/strong>') {
            return $matches[1]
        } else {
            Write-Host "Could not fetch IP address."
        }
    } catch {
        Write-Host "Failed to fetch IP address: $_"
    }

    return $null
}

$useFirewall = Read-Host "`nDo you want to apply DNS firewall redirection? (Y/N)"
if ($useFirewall -match '^(Y|y)$') {
    Configure-FirewallRules -EnableRules $true
}

try {
#    $realIPAddress = Check-IP -UseProxy $false

    Start-AnonProxy

    $proxyIPAddress = Check-IP -UseProxy $true

#    if ($realIPAddress) {
#        Write-Host "`nReal IP address: $realIPAddress"
#    }
    if ($proxyIPAddress) {
        Write-Host "IP address through Anon proxy: $proxyIPAddress"
        Write-Host "`n#################"
        Write-Host "Keep this window open and check your IP at:`n https://check.en.anyone.tech"
        Write-Host "`nThis script is experimental and intended for testing purposes only. It configures the Anon proxy to route web traffic through the network, but it doesn't guarantee that ALL system traffic will be tunneled through the proxy."
        Write-Host "Certain applications or network protocols may bypass the proxy settings. Use with caution, and verify your network activity to ensure the desired level of anonymity."
        Write-Host "#################"
        Write-Host "`nPress Ctrl+C or close this window to disable the proxy service.`n"
    }

    while ($true) {
        Start-Sleep -Seconds 3
        $anonProcess = Get-Process anon -ErrorAction SilentlyContinue
        if (-not $anonProcess) {
            Write-Host "Anon process has stopped."
            break
        }
    }
}
finally {
    Stop-AnonProxy
    Configure-FirewallRules -EnableRules $false
    Write-Host "Proxy settings and rules cleaned up. Exiting."
}
