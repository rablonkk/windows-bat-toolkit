@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Limpeza de Temporarios (by @rablonkk) v1.0.0

set "ISADMIN=0"
net session >nul 2>&1 && set "ISADMIN=1"

if "%ISADMIN%"=="0" (
    echo [!] Sem privilegio de administrador. As opcoes 2, 3 e 7 e parte da 6 exigem isso.
    choice /c SN /m "Reabrir como administrador agora"
    if not errorlevel 2 (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
        exit /b
    )
)

:menu
cls
echo ===== LIMPEZA DE TEMPORARIOS =====
echo  1. Temp do usuario (%%TEMP%%, CrashDumps, WER, INetCache)
echo  2. Temp do sistema (Windows\Temp, WER global)         [admin]
echo  3. Cache do Windows Update (SoftwareDistribution)     [admin]
echo  4. Cache de navegadores (Chrome, Edge, Brave, Firefox)
echo  5. Esvaziar Lixeira (irreversivel)
echo  6. Limpeza segura: 1 + 2 + 3 + 4
echo  7. Componentes do Windows (DISM, lento)               [admin]
echo.
echo  0. Sair
echo.
choice /c 12345670 /n /m "Opcao: "
set "n=%errorlevel%"
if %n%==8 exit /b

echo.
echo [i] Feche navegadores e instaladores antes de continuar. Arquivos em uso serao ignorados.
set "before=" & set "after="
call :getfree before

if %n%==1 call :uTemp
if %n%==2 call :sTemp
if %n%==3 call :wuCache
if %n%==4 call :browsers
if %n%==5 call :recycle
if %n%==6 (
    call :uTemp
    call :sTemp
    call :wuCache
    call :browsers
)
if %n%==7 call :dism

call :getfree after
call :report
echo.
pause
goto menu

:: ---------------- UTILITARIOS ----------------

:getfree
for /f %%a in ('powershell -NoProfile -Command "(Get-PSDrive %SystemDrive:~0,1%).Free"') do set "%~1=%%a"
exit /b

:report
if not defined before exit /b
if not defined after exit /b
for /f %%m in ('powershell -NoProfile -Command "[math]::Round((%after% - %before%)/1MB,1)"') do (
    echo.
    echo Espaco liberado em %SystemDrive% ^(aprox.^): %%m MB
)
exit /b

:needadmin
if "%ISADMIN%"=="1" exit /b 0
echo [!] Pulado: requer administrador.
exit /b 1

:: Apaga o CONTEUDO da pasta, nunca a pasta em si. Recusa caminhos curtos demais (ex.: raiz do drive).
:clean
set "p=%~1"
if not defined p exit /b
if not exist "%p%\" exit /b
call set "t=%%p:~10,1%%"
if not defined t echo [!] Caminho curto demais, ignorado: %p% & exit /b
del /f /s /q "%p%\*" >nul 2>&1
for /d %%d in ("%p%\*") do rd /s /q "%%d" >nul 2>&1
exit /b

:: ---------------- LIMPEZAS ----------------

:uTemp
echo.
echo --- Temp do usuario ---
call :clean "%TEMP%"
if /i not "%TEMP%"=="%LOCALAPPDATA%\Temp" call :clean "%LOCALAPPDATA%\Temp"
call :clean "%LOCALAPPDATA%\CrashDumps"
call :clean "%LOCALAPPDATA%\Microsoft\Windows\WER"
call :clean "%LOCALAPPDATA%\Microsoft\Windows\INetCache"
exit /b

:sTemp
echo.
echo --- Temp do sistema ---
call :needadmin || exit /b
call :clean "%SystemRoot%\Temp"
call :clean "%ProgramData%\Microsoft\Windows\WER"
exit /b

:wuCache
echo.
echo --- Cache do Windows Update ---
call :needadmin || exit /b
set "wu=" & set "bt="
sc query wuauserv | find "RUNNING" >nul && set "wu=1"
sc query bits | find "RUNNING" >nul && set "bt=1"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
call :clean "%SystemRoot%\SoftwareDistribution\Download"
if defined bt net start bits >nul 2>&1
if defined wu net start wuauserv >nul 2>&1
exit /b

:browsers
echo.
echo --- Cache de navegadores ---
call :chromium "%LOCALAPPDATA%\Google\Chrome\User Data"
call :chromium "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :chromium "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do call :clean "%%~fp\cache2"
exit /b

:chromium
for /d %%p in ("%~1\Default" "%~1\Profile *") do (
    call :clean "%%~fp\Cache"
    call :clean "%%~fp\Code Cache"
    call :clean "%%~fp\GPUCache"
)
exit /b

:recycle
echo.
choice /c SN /m "Esvaziar a Lixeira de todos os drives (irreversivel)"
if errorlevel 2 exit /b
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
exit /b

:dism
echo.
echo --- Limpeza de componentes do Windows (pode levar varios minutos) ---
call :needadmin || exit /b
dism /online /cleanup-image /startcomponentcleanup
exit /b