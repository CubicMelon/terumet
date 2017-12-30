@echo off
set MODNAME=terumet
set MTMODSDIR=E:\MineTest\minetest-0.4.16-win64\mods

del /Q /S %MTMODSDIR%\%MODNAME% >nul 2>nul
rmdir /Q /S %MTMODSDIR%\%MODNAME%\ >nul 2>nul
xcopy /E /Y %MODNAME%\* %MTMODSDIR%\%MODNAME%\ >nul 2>nul