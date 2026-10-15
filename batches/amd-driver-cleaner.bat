@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Reparo e Limpeza de Drivers de Video AMD (by @rablonkk) v1.0.0

set "ISADMIN=0"
net session >nul 2>&1 && set "ISADMIN=1"
if "%ISADMIN%"=="1" goto :start
echo [!] Este script precisa de administrador.
choice /c SN /m "Reabrir como administrador agora"
if errorlevel 2 exit /b
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:start
set "pf86=%ProgramFiles(x86)%"
set "PSK=$k='HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*';"
set "PSD=Get-WindowsDriver -Online -All | Where-Object { ($_.ClassGuid -eq '{4d36e968-e325-11ce-bfc1-08002be10318}' -and $_.ProviderName -match '^(Advanced Micro Devices|AMD|ATI Technologies)') -or $_.OriginalFileName -match '\\(amdfendr|amdfendrmgr|atihdw[^\\]*)\.inf$' }"
set "PSP='RadeonSoftware','cncmd','AMDRSServ','AMDRSSrcExt','atieclxx','atiesrxx','amdow','AMDNoiseSuppression','amdfendrsr'"
set "AUTO="
set "BK="

:menu
cls
echo ===== REPARO DE DRIVERS DE VIDEO AMD =====
if defined SAFEBOOT_OPTION echo [i] Windows em MODO SEGURO. Use a opcao 8 para desfazer o boot seguro ao terminar.
echo.
echo  1. Diagnostico (nao altera nada)
echo  2. Reparo leve: limpar caches de shader + reiniciar o adaptador de video
echo  3. Desinstalar AMD Software / Adrenalin (confirmacao por produto)
echo  4. Remover pacotes de driver de video AMD do Driver Store
echo  5. Remover residuos: servicos, tarefas, pastas, caches e registro (com backup)
echo  6. Limpeza completa: 3 + 4 + 5
echo  7. Bloquear / liberar drivers via Windows Update
echo  8. Modo seguro: ativar no proximo boot / desativar
echo.
echo  0. Sair
echo.
choice /c 123456780 /n /m "Opcao: "
set "n=%errorlevel%"
if %n%==9 exit /b
if %n%==1 call :diag
if %n%==2 call :leve
if %n%==3 call :software
if %n%==4 call :drivers
if %n%==5 call :residuos
if %n%==6 call :completo
if %n%==7 call :wu
if %n%==8 call :safemode
echo.
pause
goto menu

:: UTILITARIOS

:ask
choice /c SN /m "%~1"
if errorlevel 2 exit /b 1
exit /b 0

:confirm
if defined AUTO exit /b 0
call :ask "%~1"
exit /b %errorlevel%

:mkbackup
if defined BK exit /b
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "stamp=%%t"
set "BK=%USERPROFILE%\AMD_backup_%stamp%"
mkdir "%BK%" >nul 2>&1
exit /b

:rmdir
set "p=%~1"
if not defined p exit /b
echo %p%| findstr /i /r /c:"^[A-Za-z]:\\." >nul || exit /b
if not exist "%p%\" exit /b
echo   Removendo %p%
rd /s /q "%p%" >nul 2>&1
if not exist "%p%\" exit /b
takeown /f "%p%" /r >nul 2>&1
icacls "%p%" /grant *S-1-5-32-544:F /t /c /q >nul 2>&1
rd /s /q "%p%" >nul 2>&1
if exist "%p%\" echo   [!] Restou conteudo em uso. Reinicie e execute de novo.
exit /b

:exist
if exist "%~1\" echo   %~1
exit /b

:regdel
reg query "%~1" >nul 2>&1 || exit /b
reg export "%~1" "%BK%\%~2.reg" /y >nul 2>&1 || (echo   [!] Backup falhou, chave preservada: %~1 & exit /b)
reg delete "%~1" /f >nul 2>&1 && echo   Removida: %~1
exit /b

:matar
powershell -NoProfile -Command "Get-Service | Where-Object { $_.Name -in 'AMD External Events Utility','AMD Crash Defender Service' } | ForEach-Object { Write-Host ('Parando servico: ' + $_.Name); Stop-Service -InputObject $_ -Force -ErrorAction SilentlyContinue }"
powershell -NoProfile -Command "Get-Process -Name %PSP% -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ('Encerrando: ' + $_.ProcessName); Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }"
exit /b

:caches
call :rmdir "%LOCALAPPDATA%\AMD\DxCache"
call :rmdir "%LOCALAPPDATA%\AMD\DxcCache"
call :rmdir "%LOCALAPPDATA%\AMD\GLCache"
call :rmdir "%LOCALAPPDATA%\AMD\VkCache"
call :rmdir "%LOCALAPPDATA%\D3DSCache"
exit /b

:: ACOES

:diag
echo.
echo === GPU(s) e driver(s) em uso ===
powershell -NoProfile -Command "$a=@(Get-CimInstance Win32_VideoController | ForEach-Object { '  ' + $_.Name + ' | driver ' + $_.DriverVersion + ' | ' + ('{0:yyyy-MM-dd}' -f $_.DriverDate) + ' | status ' + $_.Status + ' | cod. erro ' + $_.ConfigManagerErrorCode }); if ($a.Count -eq 0) { '  nenhuma' } else { $a }"
echo.
echo === Pacotes de driver(s) AMD ^(pode levar alguns segundos^) ===
powershell -NoProfile -Command "$a=@(%PSD% | Sort-Object Date | ForEach-Object { '  ' + $_.Driver + '  v' + $_.Version + '  ' + ('{0:yyyy-MM-dd}' -f $_.Date) + '  ' + (Split-Path $_.OriginalFileName -Leaf) }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Versão do AMD Adrenalin Edition instalado ===
powershell -NoProfile -Command "%PSK% $a=@(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^(AMD Software|Radeon Software|AMD Radeon|AMD Catalyst|ATI Catalyst)' -and $_.DisplayName -notmatch 'Chipset|Ryzen' } | Sort-Object DisplayName | ForEach-Object { '  ' + $_.DisplayName + '  ' + $_.DisplayVersion }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Travamentos da(s) GPU(s) nos ultimos 7 dias ^(evento 4101: driver parou de responder^) ===
powershell -NoProfile -Command "$e=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Display';Id=4101;StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue); '  Ocorrencias: ' + $e.Count; if ($e.Count -gt 0) { '  Ultima: ' + $e[0].TimeCreated }"
echo.
echo === Processos dos driver(s) da AMD em execucao ===
powershell -NoProfile -Command "$a=@(Get-Process -Name %PSP% -ErrorAction SilentlyContinue | ForEach-Object { '  ' + $_.ProcessName }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Estado do sistema ===
set "wust=liberados"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate 2>nul | find "0x1" >nul && set "wust=BLOQUEADOS"
echo   Drivers via Windows Update: %wust%
if defined SAFEBOOT_OPTION echo   Modo seguro: ATIVO nesta sessao
bcdedit /enum {current} 2>nul | findstr /i safeboot >nul && echo   Boot em modo seguro AGENDADO para o proximo reinicio
echo.
echo === Pastas e chaves dos driver(s) da AMD presentes neste sistema ===
call :exist "%SystemDrive%\AMD"
call :exist "%ProgramFiles%\AMD\CNext"
call :exist "%ProgramFiles%\AMD\CIM"
call :exist "%ProgramFiles%\ATI Technologies"
call :exist "%pf86%\ATI Technologies"
call :exist "%ProgramData%\ATI"
call :exist "%LOCALAPPDATA%\AMD\CN"
call :exist "%APPDATA%\ATI"
for %%r in ("HKLM\SOFTWARE\ATI Technologies" "HKLM\SOFTWARE\WOW6432Node\ATI Technologies" "HKCU\Software\ATI" "HKCU\Software\AMD\CN" "HKLM\SOFTWARE\AMD\CN") do reg query %%r >nul 2>&1 && echo   %%~r
exit /b

:leve
echo.
call :confirm "Esse procedimento ira fechar o AMD Adrenalin Software, limpar o cache dos shaders e reiniciar o adaptador de video da AMD. (A sua tela pode piscar durante esse processo). Deseja continuar? *S = SIM / N = NAO*" || exit /b
call :matar
call :caches
powershell -NoProfile -Command "Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'PCI\VEN_1002*' -and $_.Status -eq 'OK' } | ForEach-Object { Write-Host ('Reiniciando adaptador: ' + $_.FriendlyName); Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false; Start-Sleep -Seconds 3; Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false }"
echo.
echo Se a tela nao voltar ao normal, reinicie o PC.
exit /b

:software
echo.
echo === Desinstalacao do AMD Adrenalin Edition ===
echo Os desinstaladores da AMD abrem as suas proprias janelas. Aguarde...
echo.
call :matar
powershell -NoProfile -Command "%PSK% $a=@(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^(AMD Software|Radeon Software|AMD Radeon|AMD Catalyst|ATI Catalyst)' -and $_.DisplayName -notmatch 'Chipset|Ryzen' -and $_.UninstallString } | Sort-Object DisplayName); if ($a.Count -eq 0) { Write-Host 'Nenhum AMD Software registrado.'; exit }; foreach ($p in $a) { $r = Read-Host ('Desinstalar ' + $p.DisplayName + ' ' + $p.DisplayVersion + '? [s/N]'); if ($r -ne 's') { continue }; $u = [string]$p.UninstallString; if ($u -match 'msiexec') { $u = ($u -replace '/I\{','/X{') + ' /passive /norestart' }; Start-Process -FilePath cmd.exe -ArgumentList ('/c ' + [char]34 + $u + [char]34) -Wait }"
exit /b

:drivers
echo.
echo === Removendo pacotes de driver(s) da AMD ===
powershell -NoProfile -Command "$a=@(%PSD% | ForEach-Object { '  ' + $_.Driver + '  v' + $_.Version + '  ' + (Split-Path $_.OriginalFileName -Leaf) }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
call :confirm "Remover estes pacotes do Driver Store. A tela pode piscar e voltar ao driver basico da Microsoft. Continuar" || exit /b
call :matar
powershell -NoProfile -Command "%PSD% | ForEach-Object { Write-Host ('Removendo ' + $_.Driver); pnputil.exe /delete-driver $_.Driver /uninstall /force }"
echo.
echo Reinicie o PC antes de instalar o driver novo.
exit /b

:residuos
echo.
call :confirm "Remover servicos, tarefas, pastas, caches e chaves de registro da AMD relacionadas a GPU. Nao afeta drivers de chipset nem Ryzen Master. Deseja continuar?" || exit /b
call :matar
echo --- Servicos e tarefas ---
powershell -NoProfile -Command "Get-Service | Where-Object { $_.Name -in 'AMD External Events Utility','AMD Crash Defender Service' } | ForEach-Object { Write-Host ('Removendo servico: ' + $_.Name); Stop-Service -InputObject $_ -Force -ErrorAction SilentlyContinue; sc.exe delete $_.Name | Out-Null }"
powershell -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -in 'StartCN','StartDVR' } | ForEach-Object { Write-Host ('Removendo tarefa: ' + $_.TaskName); Unregister-ScheduledTask -InputObject $_ -Confirm:$false -ErrorAction SilentlyContinue }"
powershell -NoProfile -Command "foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') { if (Test-Path $k) { $it = Get-ItemProperty $k; foreach ($n in $it.PSObject.Properties.Name) { if ($n -like 'PS*') { continue }; $v = [string]$it.$n; if ($n -in 'AMDNoiseSuppression','RadeonSoftware' -or $v -like '*\AMD\CNext\*') { Write-Host ('Removendo inicializacao: ' + $n); Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue } } } }"
echo --- Pastas e caches ---
call :rmdir "%SystemDrive%\AMD"
call :rmdir "%ProgramFiles%\AMD\CNext"
call :rmdir "%ProgramFiles%\AMD\CIM"
call :rmdir "%ProgramFiles%\ATI Technologies"
call :rmdir "%pf86%\ATI Technologies"
call :rmdir "%ProgramData%\ATI"
call :rmdir "%LOCALAPPDATA%\AMD\CN"
call :rmdir "%APPDATA%\ATI"
call :caches
rd "%LOCALAPPDATA%\AMD" >nul 2>&1
echo --- Registro ---
call :mkbackup
call :regdel "HKLM\SOFTWARE\ATI Technologies" HKLM_ATI
call :regdel "HKLM\SOFTWARE\WOW6432Node\ATI Technologies" HKLM_WOW6432_ATI
call :regdel "HKCU\Software\ATI" HKCU_ATI
call :regdel "HKCU\Software\AMD\CN" HKCU_AMD_CN
call :regdel "HKLM\SOFTWARE\AMD\CN" HKLM_AMD_CN
call :regdel "HKCU\Software\AMD\DVR" HKCU_AMD_DVR
echo   Backup das chaves em: %BK%
exit /b

:completo
echo.
echo Sequencia: desinstalar AMD Adrenalin Edition, remover pacotes de driver(s) e remover residuos.
echo Dica: antes de rodar, baixe o driver novo e DESCONECTE a rede ^(ou use a opcao 7^).
call :ask "Executar a limpeza completa agora" || exit /b
set "AUTO=1"
call :software
call :drivers
call :residuos
set "AUTO="
echo.
echo [OK] Concluido. Reinicie o PC e instale o driver novo.
exit /b

:wu
echo.
echo Bloquear impede o Windows Update de instalar drivers da AMD automaticamente e sobrescrever a instalacao limpa.
echo Em PCs corporativos, politicas de grupo podem sobrepor esta configuracao.
choice /c BLC /n /m "Bloquear [B], Liberar [L] ou Cancelar [C]? "
set "w=%errorlevel%"
if %w%==1 call :wuBloquear
if %w%==2 call :wuLiberar
exit /b

:wuBloquear
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f
echo Drivers via Windows Update: BLOQUEADOS. Lembre de liberar depois ^(opcao 7, L^).
exit /b

:wuLiberar
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /f
echo Drivers via Windows Update: liberados.
exit /b

:safemode
echo.
if defined SAFEBOOT_OPTION echo [i] Voce esta no Modo Seguro agora.
choice /c ADC /n /m "Ativar modo seguro no proximo boot [A], Desativar [D] ou Cancelar [C]? "
set "s=%errorlevel%"
if %s%==1 call :smOn
if %s%==2 call :smOff
exit /b

:smOn
set "bl="
for /f "usebackq" %%b in (`powershell -NoProfile -Command "try { if ((Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop).ProtectionStatus -eq 'On') { 'ON' } } catch { }"`) do set "bl=%%b"
if /i "%bl%"=="ON" call :ask "O BitLocker esta ativo no drive do sistema. Mudar o boot pode exigir a chave de recuperacao. Voce tem a chave? Continuar" || exit /b
bcdedit /set {current} safeboot minimal
echo.
echo O PC continuara iniciando em Modo Seguro ate voce rodar esta opcao com D.
call :ask "Reiniciar agora no Modo Seguro" && shutdown /r /t 5 /c "Reiniciando em Modo Seguro"
exit /b

:smOff
bcdedit /deletevalue {current} safeboot
echo.
call :ask "Reiniciar agora no modo normal" && shutdown /r /t 5 /c "Reiniciando em modo normal"
exit /b