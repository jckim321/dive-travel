#Requires -RunAsAdministrator
# 아이폰/안드로이드가 노트북 LAN 웹서버(TCP 8112)에 들어오도록 방화벽을 엽니다.
# Public 프로필은 인바운드를 막으므로 Wi-Fi를 Private로도 바꿉니다.
Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'Wi-Fi*' } | ForEach-Object {
  Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private
  Write-Host ("네트워크 '{0}' 을 Private 로 바꿨습니다." -f $_.Name)
}
$ruleName = 'Dive Travel LAN web 8112'
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8112 -Profile Any | Out-Null
Get-NetFirewallRule -DisplayName 'Dive Travel LAN dart.exe' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
$dart = (Get-Command dart -ErrorAction SilentlyContinue).Source
if ($dart) {
  New-NetFirewallRule -DisplayName 'Dive Travel LAN dart.exe' -Direction Inbound -Action Allow -Program $dart -Profile Any | Out-Null
}
Write-Host '방화벽에서 TCP 8112 인바운드를 허용했습니다.'
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object {
  Write-Host ("휴대폰에서 열 주소: http://{0}:8112" -f $_.IPAddress)
}
