rem Delete old copy of mod from Minetest mods folder and copy over WIP one
@echo off
set MODNAME=tmapisample
set MTMODSDIR=E:\MineTest\minetest-5.0.0-win64\mods

del /Q /S %MTMODSDIR%\%MODNAME% >nul 2>nul
rmdir /Q /S %MTMODSDIR%\%MODNAME%\ >nul 2>nul
xcopy /E /Y %MODNAME%\* %MTMODSDIR%\%MODNAME%\ >nul 2>nul