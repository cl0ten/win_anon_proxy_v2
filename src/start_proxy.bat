@echo off
Powershell.exe -Command "Start-Process Powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%cd%\bootstrap.ps1""' -Verb RunAs"
