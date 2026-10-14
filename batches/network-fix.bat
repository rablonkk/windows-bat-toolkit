@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Wi-Fi/Ethernet Fix (by @rablonkk) v1.1.0

set "ISADMIN=0"
net session >nul 2>&1 && set "ISADMIN=1"

:menu
cls
echo ===== DIAGNOSTICO =====
echo  1. IP (ipconfig /all)        2. Gateway (roteador)
echo  3. Internet por IP           4. DNS (resolucao de nome)
echo  5. Adaptadores de ethernet / Wi-Fi       6. Proxy (WinHTTP + WinINET)
echo  7. Diagnostico completo (1-6)
echo.
echo ===== CORRECAO =====
echo  A. Limpar o cache do DNS          B. Renovar IP (release/renew)
echo  C. Resetar proxy             D. Reiniciar adaptadores
echo  E. Reset Winsock + IP (admin + reiniciar o PC)
echo  F. Correcao automatica (A, C, B, D + teste final)
echo.
echo  0. Sair
echo.
if "%ISADMIN%"=="0" echo [!] Sem privilegio de administrador: as opcoes B, D, E e uma parte da opcao C, vao falhar.
choice /c 1234567ABCDEF0 /n /m "Opcao: "
set "n=%errorlevel%"

if %n%==14 exit /b
if %n% LEQ 6 call :d%n%
if %n%==7 for %%a in (1 2 3 4 5 6) do call :d%%a
if %n%==8 call :fA
if %n%==9 call :fB
if %n%==10 call :fC
if %n%==11 call :fD
if %n%==12 call :fE
if %n%==13 call :fF
echo.
pause
goto menu

:: ---------------- DIAGNOSTICO ----------------

:d1
echo.
echo --- [1] Configuracao IP ---
ipconfig /all
exit /b

:d2
echo.
echo --- [2] Gateway ---
call :getgw
if not defined gw (
    echo [FALHA] Sem gateway IPv4: cabo/Wi-Fi desconectado, DHCP falhou ou adaptador desativado.
    exit /b
)
echo Gateway: !gw!
ping -n 2 -w 2000 !gw!
exit /b

:d3
echo.
echo --- [3] Conectividade por IP ---
ping -n 2 -w 2000 1.1.1.1
ping -n 2 -w 2000 8.8.8.8
echo.
echo Leitura: gateway responde e 1.1.1.1/8.8.8.8 nao = problema no modem/ISP.
exit /b

:d4
echo.
echo --- [4] DNS (resolvedor atual) ---
nslookup google.com
echo.
echo --- [4] DNS (resolvedor externo 1.1.1.1) ---
nslookup google.com 1.1.1.1
echo.
echo Leitura: externo resolve e atual nao = DNS do roteador/ISP com defeito (troque o DNS).
exit /b

:d5
echo.
echo --- [5] Adaptadores ---
netsh interface show interface
echo.
echo --- [5] Wi-Fi ---
netsh wlan show interfaces 2>nul || echo Sem interface Wi-Fi ou servico WLAN AutoConfig parado.
exit /b

:d6
echo.
echo --- [6] Proxy WinHTTP (servicos do sistema) ---
netsh winhttp show proxy
echo.
echo --- [6] Proxy WinINET (navegadores / Windows Settings) ---
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL 2>nul
exit /b

:getgw
set "gw="
for /f "tokens=3" %%g in ('route print -4 ^| findstr /r /c:"^ *0\.0\.0\.0 *0\.0\.0\.0 "') do (
    echo %%g| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul && if not defined gw set "gw=%%g"
)
exit /b

:: ---------------- CORRECAO ----------------

:req
if "%ISADMIN%"=="1" exit /b 0
echo [!] Requer administrador: botao direito no .bat ^> Executar como administrador.
exit /b 1

:fA
echo.
echo --- Limpando cache DNS ---
ipconfig /flushdns
exit /b

:fB
echo.
echo --- Renovando IP ---
call :req || exit /b
ipconfig /release
ipconfig /renew
exit /b

:fC
echo.
echo --- Resetando proxy ---
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
if "%ISADMIN%"=="1" (
    netsh winhttp reset proxy
) else (
    echo [!] WinHTTP nao resetado: requer administrador.
)
exit /b

:fD
echo.
echo --- Reiniciando adaptadores fisicos ativos (a conexao cai por alguns segundos) ---
call :req || exit /b
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Restart-NetAdapter -Confirm:$false"
timeout /t 8 /nobreak >nul
exit /b

:fE
echo.
echo --- Reset Winsock + pilha TCP/IP ---
call :req || exit /b
choice /c SN /m "Isso exige reiniciar o PC e remove configuracoes de IP estatico. Continuar"
if errorlevel 2 exit /b
netsh winsock reset
netsh int ip reset
echo.
echo [OK] Reinicie o computador para aplicar.
exit /b

:fF
call :fA
call :fC
call :fB
call :fD
echo.
echo === Teste final ===
call :d2
call :d3
call :d4
exit /b