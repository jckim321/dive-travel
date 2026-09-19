@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo 관리자 권한이 필요합니다. 확인을 눌러 주세요.
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
netsh advfirewall firewall delete rule name="Dive Travel LAN web 8112" >nul 2>&1
netsh advfirewall firewall add rule name="Dive Travel LAN web 8112" dir=in action=allow protocol=TCP localport=8112 profile=any
echo.
echo TCP 8112 을 방화벽에서 열었습니다.
echo 휴대폰/태블릿에서 아래 주소로 여세요. https 가 아닙니다.
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do echo   http://%%b:8112
)
echo.
pause
