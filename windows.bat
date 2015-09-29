@echo off

powershell -NoProfile -NoLogo -Command "if (Get-VpnConnection | findstr "Railgun"){Remove-VpnConnection Railgun -Force};Add-VpnConnection Railgun h.lv5.ac -L2tpPsk railgun -RememberCredential -Force"

if errorlevel 1 (
    echo Error occured adding vpn connection.
) else (
    echo Railgun vpn added.
)

pause
