@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Remocao Adobe (by @rablonkk) v1.0.0

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
set "AUTO="
set "BK="

:menu
cls
echo ===== REMOCAO ADOBE =====
echo  1. Inventario (nao altera nada)
echo  2. Encerrar processos e servicos Adobe
echo  3. Desinstalar produtos (desinstaladores oficiais, com confirmacao por produto)
echo  4. Remover servicos, tarefas agendadas e itens de inicializacao
echo  5. Remover pastas residuais do sistema (Program Files, Common Files, ProgramData)
echo  6. Remover DADOS DO USUARIO (AppData: preferencias, presets, cache)
echo  7. Remover chaves de registro Adobe (com backup .reg)
echo  8. Remocao completa: 2 + 3 + 4 + 5 + 7 (nao inclui a 6)
echo.
echo  0. Sair
echo.
choice /c 123456780 /n /m "Opcao: "
set "n=%errorlevel%"
if %n%==9 exit /b
if %n%==1 call :inventario
if %n%==2 call :encerrar
if %n%==3 call :desinstalar
if %n%==4 call :servicos
if %n%==5 call :sistema
if %n%==6 call :usuario
if %n%==7 call :registro
if %n%==8 call :completo
echo.
pause
goto menu

:ask
choice /c SN /m "%~1"
if errorlevel 2 exit /b 1
exit /b 0

:confirm
if defined AUTO exit /b 0
call :ask "%~1"
exit /b %errorlevel%

:countprod
set "prod=0"
for /f "usebackq" %%c in (`powershell -NoProfile -Command "%PSK% @(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.Publisher -like 'Adobe*' -or $_.DisplayName -like 'Adobe*' }).Count"`) do set "prod=%%c"
exit /b

:mkbackup
if defined BK exit /b
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "stamp=%%t"
set "BK=%USERPROFILE%\Adobe_backup_%stamp%"
mkdir "%BK%" >nul 2>&1
exit /b

:rmdir
set "p=%~1"
if not defined p exit /b
if not exist "%p%\" exit /b
echo %p%| findstr /i /r /c:"\\Adobe$" >nul || exit /b
call set "t=%%p:~15,1%%"
if not defined t exit /b
echo   Removendo %p%
rd /s /q "%p%" >nul 2>&1
if not exist "%p%\" exit /b
takeown /f "%p%" /r >nul 2>&1
icacls "%p%" /grant *S-1-5-32-544:F /t /c /q >nul 2>&1
rd /s /q "%p%" >nul 2>&1
if exist "%p%\" echo   [!] Restou conteudo em uso. Reinicie o PC e execute esta opcao de novo.
exit /b

:show
if not exist "%~1\" exit /b
echo   %~1
powershell -NoProfile -Command "'      ' + ('{0:N0}' -f ((Get-ChildItem -LiteralPath '%~1' -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)) + ' MB'"
exit /b

:regdel
reg query "%~1" >nul 2>&1 || exit /b
reg export "%~1" "%BK%\%~2.reg" /y >nul 2>&1 || (echo   [!] Backup falhou, chave preservada: %~1 & exit /b)
reg delete "%~1" /f >nul 2>&1 && echo   Removida: %~1
exit /b

:inventario
echo.
echo === Produtos Adobe registrados ===
powershell -NoProfile -Command "%PSK% $a=@(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.Publisher -like 'Adobe*' -or $_.DisplayName -like 'Adobe*' } | Sort-Object DisplayName | ForEach-Object { '  ' + $_.DisplayName + '  ' + $_.DisplayVersion }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Servicos ===
powershell -NoProfile -Command "$a=@(Get-Service | Where-Object { $_.Name -like 'Adobe*' -or $_.DisplayName -like 'Adobe*' -or $_.Name -in 'AGMService','AGSService' } | ForEach-Object { '  ' + $_.Name + ' [' + $_.Status + ']' }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Tarefas agendadas ===
powershell -NoProfile -Command "$a=@(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Adobe*' } | ForEach-Object { '  ' + $_.TaskPath + $_.TaskName }); if ($a.Count -eq 0) { '  nenhuma' } else { $a }"
echo.
echo === Processos em execucao ===
powershell -NoProfile -Command "$a=@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Adobe*' -or $_.Path -like '*\Adobe\*' } | Sort-Object ProcessName -Unique | ForEach-Object { '  ' + $_.ProcessName }); if ($a.Count -eq 0) { '  nenhum' } else { $a }"
echo.
echo === Pastas do sistema ===
call :show "%ProgramFiles%\Adobe"
call :show "%pf86%\Adobe"
call :show "%ProgramFiles%\Common Files\Adobe"
call :show "%pf86%\Common Files\Adobe"
call :show "%ProgramData%\Adobe"
echo.
echo === Pastas do usuario ===
call :show "%APPDATA%\Adobe"
call :show "%LOCALAPPDATA%\Adobe"
echo.
echo === Chaves de registro ===
for %%r in ("HKCU\Software\Adobe" "HKLM\SOFTWARE\Adobe" "HKLM\SOFTWARE\WOW6432Node\Adobe") do reg query %%r >nul 2>&1 && echo   %%~r
echo.
echo Arquivos nao acessados por este batch: Creative Cloud Files, Documentos\Adobe, Imagens ^(catalogos Lightroom^), arquivo hosts.
exit /b

:encerrar
echo.
call :confirm "Encerra processos e servicos Adobe. Os apps da Adobe abertos, podem perder o trabalho atual nao salvo. Deseja continuar?" || exit /b
powershell -NoProfile -Command "Get-Service | Where-Object { $_.Name -like 'Adobe*' -or $_.DisplayName -like 'Adobe*' -or $_.Name -in 'AGMService','AGSService' } | ForEach-Object { Write-Host ('Parando servico: ' + $_.Name); Stop-Service -InputObject $_ -Force -ErrorAction SilentlyContinue }"
powershell -NoProfile -Command "Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Adobe*' -or $_.Path -like '*\Adobe\*' -or $_.ProcessName -in 'armsvc','CCXProcess','CCLibrary','Creative Cloud' } | ForEach-Object { Write-Host ('Encerrando: ' + $_.ProcessName); Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }"
exit /b

:desinstalar
echo.
echo === Desinstalacao ===
echo Apps primeiro, Creative Cloud por ultimo. Cada desinstalador abre a propria janela. Aguarde...
echo Dica: saia da conta no Creative Cloud antes, para liberar a ativacao.
echo.
powershell -NoProfile -Command "%PSK% $a=@(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { ($_.Publisher -like 'Adobe*' -or $_.DisplayName -like 'Adobe*') -and $_.UninstallString } | Sort-Object @{e={$_.DisplayName -like '*Creative Cloud*'}}, DisplayName); if ($a.Count -eq 0) { Write-Host 'Nenhum produto Adobe com desinstalador registrado.'; exit }; foreach ($p in $a) { $r = Read-Host ('Desinstalar ' + $p.DisplayName + ' ' + $p.DisplayVersion + '? [s/N]'); if ($r -ne 's') { continue }; $u = [string]$p.UninstallString; if ($u -match 'msiexec') { $u = ($u -replace '/I\{','/X{') + ' /passive /norestart' }; Start-Process -FilePath cmd.exe -ArgumentList ('/c ' + [char]34 + $u + [char]34) -Wait }"
exit /b

:servicos
echo.
call :confirm "Remover servicos, tarefas agendadas e itens de inicializacao da Adobe. Continuar" || exit /b
powershell -NoProfile -Command "Get-Service | Where-Object { $_.Name -like 'Adobe*' -or $_.DisplayName -like 'Adobe*' -or $_.Name -in 'AGMService','AGSService' } | ForEach-Object { Write-Host ('Removendo servico: ' + $_.Name); Stop-Service -InputObject $_ -Force -ErrorAction SilentlyContinue; sc.exe delete $_.Name | Out-Null }"
powershell -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Adobe*' } | ForEach-Object { Write-Host ('Removendo tarefa: ' + $_.TaskName); Unregister-ScheduledTask -InputObject $_ -Confirm:$false -ErrorAction SilentlyContinue }"
powershell -NoProfile -Command "foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') { if (Test-Path $k) { $it = Get-ItemProperty $k; foreach ($n in $it.PSObject.Properties.Name) { if ($n -like 'PS*') { continue }; $v = [string]$it.$n; if ($n -like 'Adobe*' -or $n -like 'Acrobat*' -or $v -like '*\Adobe\*') { Write-Host ('Removendo inicializacao: ' + $n); Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue } } } }"
exit /b

:sistema
echo.
call :countprod
if not "%prod%"=="0" call :ask "Ainda ha %prod% entradas Adobe instaladas. Apagar as pastas podem deixar arquivos orfãos e corrompidos. Deseja continuar mesmo assim?" || exit /b
call :confirm "Apagar pastas da Adobe, como Program Files, Common Files e ProgramData. Isso inclui Acrobat Reader e plug-ins de terceiros presentes nela. Deseja continuar?" || exit /b
call :rmdir "%ProgramFiles%\Adobe"
call :rmdir "%pf86%\Adobe"
call :rmdir "%ProgramFiles%\Common Files\Adobe"
call :rmdir "%pf86%\Common Files\Adobe"
call :rmdir "%ProgramData%\Adobe"
exit /b

:usuario
echo.
call :confirm "ATENCAO: apaga preferencias, workspaces, presets, pinceis e cache de midia do usuario atual no AppData. Essa acao e Irreversivel. Deseja continuar?" || exit /b
call :rmdir "%APPDATA%\Adobe"
call :rmdir "%LOCALAPPDATA%\Adobe"
exit /b

:registro
echo.
call :countprod
if not "%prod%"=="0" call :ask "Ainda ha %prod% entradas Adobe instaladas. Remover as chaves pode quebra-las. Deseja continuar mesmo assim?" || exit /b
call :confirm "Remover as chaves Software\Adobe do registro, com backup em .reg. Deseja continuar?" || exit /b
call :mkbackup
call :regdel "HKCU\Software\Adobe" HKCU_Adobe
call :regdel "HKLM\SOFTWARE\Adobe" HKLM_Adobe
call :regdel "HKLM\SOFTWARE\WOW6432Node\Adobe" HKLM_WOW6432_Adobe
echo   Backup das chaves em: %BK%
exit /b

:completo
echo.
echo Sequencia: encerrar, desinstalar, encerrar de novo, remover servicos, pastas do sistema e registro.
echo Nao remove dados do usuario ^(opcao 6^) nem a pasta Creative Cloud Files.
call :ask "Executar a remocao completa agora" || exit /b
set "AUTO=1"
call :encerrar
call :desinstalar
call :encerrar
call :servicos
call :sistema
call :registro
set "AUTO="
echo.
echo [OK] Concluido. Reinicie o PC e rode a opcao 1 para verificar o que restou.
exit /b