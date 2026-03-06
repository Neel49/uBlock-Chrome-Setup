@echo off
:: Run the uBlock Chrome setup script. Close Chrome first.
powershell -ExecutionPolicy Bypass -File "%~dp0Install-uBlock-Chrome.ps1"
pause
