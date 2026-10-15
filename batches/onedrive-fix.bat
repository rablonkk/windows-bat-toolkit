@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Reparo do OneDrive (by @rablonkk) v1.1.0

set "ISADMIN=0"
net session >nul 2>&1 && set "ISADMIN=1"
if "%ISADMIN%"=="0" goto :start
echo [!] Voce abriu este aquivo batch como ADMINISTRADOR. Para correcao do OneDrive o correto e executar o batch SEM administrador,
echo     na sua propria conta de usuario. Configuracoes e credenciais sao registrads por usuario no Windows, e se a conta admin for
echo     diferente, o script atuaria no perfil errado. As etapas que precisam de admin pedem
echo     elevacao sozinhas.
choice /c SN /m "Continuar mesmo assim"
if errorlevel 2 exit /b

:start
set "pf86=%ProgramFiles(x86)%"
set "BK="
set "stamp="

:menu
call :findod
cls
echo ===== REPARO DO ONEDRIVE =====
echo  Este script NAO apaga nem mexe nos arquivos da sua pasta OneDrive.
echo.
echo  1. Diagnostico (nao altera nada)
echo  2. Reiniciar o OneDrive
echo  3. Corrigir login: hora, servicos de conta Microsoft e credenciais em cache
echo  4. Reset oficial do OneDrive (onedrive.exe /reset)
echo  5. Reset profundo: credenciais + pasta settings (backup) + reset oficial
echo  6. Remover politica que bloqueia o OneDrive (DisableFileSync)
echo  7. Desinstalar o aplicativo OneDrive (nao apaga seus arquivos)
echo  8. Instalar / reinstalar o OneDrive (usa o instalador do proprio Windows)
echo.
echo  0. Sair
echo.
choice /c 123456780 /n /m "Opcao: "
set "n=%errorlevel%"
if %n%==9 exit /b
if %n%==1 call :diag
if %n%==2 call :reiniciar
if %n%==3 call :login
if %n%==4 call :reset
if %n%==5 call :profundo
if %n%==6 call :politica
if %n%==7 call :uninstall
if %n%==8 call :install
echo.
pause
goto menu

:ask
choice /c SN /m "%~1"
if errorlevel 2 exit /b 1
exit /b 0

:findod
set "OD="
if exist "%LocalAppData%\Microsoft\OneDrive\OneDrive.exe" set "OD=%LocalAppData%\Microsoft\OneDrive\OneDrive.exe"
if not defined OD if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" set "OD=%ProgramFiles%\Microsoft OneDrive\OneDrive.exe"
if not defined OD if exist "%pf86%\Microsoft OneDrive\OneDrive.exe" set "OD=%pf86%\Microsoft OneDrive\OneDrive.exe"
exit /b

:findsetup
set "SETUP="
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" set "SETUP=%SystemRoot%\SysWOW64\OneDriveSetup.exe"
if not defined SETUP if exist "%SystemRoot%\System32\OneDriveSetup.exe" set "SETUP=%SystemRoot%\System32\OneDriveSetup.exe"
exit /b

:mkstamp
if defined stamp exit /b
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "stamp=%%t"
exit /b

:mkbackup
if defined BK exit /b
call :mkstamp
set "BK=%USERPROFILE%\OneDrive_fix_backup_%stamp%"
mkdir "%BK%" >nul 2>&1
exit /b

:elev
powershell -NoProfile -Command "try { Start-Process -FilePath cmd.exe -ArgumentList '/c %~1' -Verb RunAs -Wait -ErrorAction Stop } catch { Write-Host '[!] Elevacao cancelada ou negada.' }"
exit /b

:matar
if defined OD "%OD%" /shutdown >nul 2>&1
timeout /t 2 /nobreak >nul
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im FileCoAuth.exe >nul 2>&1
taskkill /f /im FileSyncHelper.exe >nul 2>&1
exit /b

:iniciar
if not defined OD exit /b
start "" explorer.exe "%OD%"
exit /b

:credenciais
echo   Removendo credenciais em cache do OneDrive...
for /f "tokens=2* delims==" %%a in ('cmdkey /list ^| findstr /i /c:"OneDrive Cached Credential"') do cmdkey /delete:"%%a" >nul 2>&1 && echo   Removida: %%a
exit /b

:kfm
set "KFM="
for /f "usebackq" %%k in (`powershell -NoProfile -Command "$p=Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'; if (([string]$p.Desktop + [string]$p.Personal + [string]$p.'My Pictures') -like '*OneDrive*') { 'KFM' }"`) do set "KFM=1"
exit /b

:diag
echo.
echo Obs: Nos logs desse batch, pode mostrar o seu e-mail. Oculte antes de compartilhar.
echo.
echo === Instalacao ===
if not defined OD echo   OneDrive.exe nao encontrado
if defined OD echo   %OD%
if defined OD powershell -NoProfile -Command "'  versao: ' + (Get-Item -LiteralPath '%OD%').VersionInfo.FileVersion"
call :findsetup
if defined SETUP echo   Instalador do Windows disponivel: %SETUP%
if not defined SETUP echo   Instalador do Windows NAO encontrado
echo.
echo === Processo ===
tasklist /fi "imagename eq OneDrive.exe" | find /i "OneDrive.exe" >nul && echo   OneDrive em execucao || echo   OneDrive NAO esta em execucao
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive >nul 2>&1 && echo   Entrada de inicializacao: presente || echo   Entrada de inicializacao: AUSENTE
echo.
echo === Contas vinculadas ===
powershell -NoProfile -Command "$a=@(Get-ChildItem 'HKCU:\Software\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { $p = Get-ItemProperty $_.PSPath; '  ' + $_.PSChildName + ' | ' + $p.UserEmail + ' | ' + $p.UserFolder }); if ($a.Count -eq 0) { '  nenhuma conta vinculada' } else { $a }"
echo.
echo === Pastas redirecionadas ===
powershell -NoProfile -Command "$p=Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'; foreach ($n in 'Desktop','Personal','My Pictures') { '  ' + $n + ' -> ' + [Environment]::ExpandEnvironmentVariables([string]$p.$n) }"
echo.
echo === Politicas que podem bloquear o OneDrive ===
set "pol="
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" 2>nul | findstr /i "DisableFileSync" && set "pol=1"
reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive" 2>nul | findstr /i "DisableFileSync" && set "pol=1"
if defined pol echo   Valor 0x1 = OneDrive BLOQUEADO por politica internas.
if not defined pol echo   nenhuma politica de bloqueio encontrada
echo.
echo === Hora e servicos de login ===
echo   Data/hora do PC: %date% %time%
for /f "delims=" %%z in ('tzutil /g') do echo   Fuso: %%z
powershell -NoProfile -Command "Get-Service wlidsvc,TokenBroker -ErrorAction SilentlyContinue | ForEach-Object { '  ' + $_.Name + '  status=' + $_.Status + '  inicio=' + $_.StartType }"
echo.
echo === Proxy do usuario ===
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2>nul
echo.
echo === Conectividade com os servidores de login e sincronizacao ===
powershell -NoProfile -Command "foreach ($h in 'login.live.com','login.microsoftonline.com','onedrive.live.com') { $ok = Test-NetConnection -ComputerName $h -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue; '  ' + $h + ':443  ' + $(if ($ok) { 'OK' } else { 'FALHOU' }) }"
echo.
echo === Espaco em disco ===
powershell -NoProfile -Command "'  Livre em ' + $env:SystemDrive + ' : ' + [math]::Round((Get-PSDrive $env:SystemDrive.Substring(0,1)).Free / 1GB, 1) + ' GB'"
echo.
echo === Credenciais em cache do OneDrive ===
cmdkey /list | findstr /i /c:"OneDrive Cached Credential" || echo   nenhuma
exit /b

:reiniciar
echo.
if not defined OD echo [!] OneDrive nao encontrado. Use a opcao 8 para instalar. & exit /b
call :matar
call :iniciar
echo OneDrive reiniciado. Aguarde alguns segundos pelo icone na bandeja.
exit /b

:login
echo.
echo Nenhum arquivo e afetado. Voce precisara entrar na sua conta novamente.
call :ask "Executar" || exit /b
echo.
echo --- Hora e servicos ^(UAC^) ---
call :elev "net start w32time & w32tm /resync & sc config wlidsvc start= demand & sc config TokenBroker start= demand & sc start wlidsvc & sc start TokenBroker"
echo.
echo --- Credenciais ---
call :matar
call :credenciais
call :iniciar
echo.
echo Pronto. Tente entrar na conta pelo OneDrive. Se continuar falhando, use a opcao 5.
exit /b

:reset
echo.
if not defined OD echo [!] OneDrive nao encontrado. Use a opcao 8 para instalar. & exit /b
echo O reset desconecta TODAS as contas ^(pessoal e trabalho^) e refaz a sincronizacao.
echo Os arquivos locais e da nuvem NAO sao apagados, mas a ressincronizacao pode ser longa e demorada
call :ask "Tem certeza que deseja continuar?" || exit /b
"%OD%" /reset
echo Aguardando o OneDrive reiniciar...
timeout /t 15 /nobreak >nul
tasklist /fi "imagename eq OneDrive.exe" | find /i "OneDrive.exe" >nul || call :iniciar
echo Se o OneDrive nao abrir sozinho em alguns minutos, inicie-o pelo menu Iniciar.
exit /b

:profundo
echo.
if not defined OD echo [!] OneDrive nao encontrado. Use a opcao 8 para instalar. & exit /b
echo Reset profundo para laco de login ou erro persistente:
echo   - remove credenciais em cache;
echo   - renomeia a pasta settings do OneDrive ^(vira backup, nada e apagado^);
echo   - executa o reset oficial da Microsoft;
echo Os arquivos da pasta OneDrive NAO sao alterados e nem removidos. Voce precisara entrar na sua conta novamente apos
echo esse procedimento.
call :ask "Tem certeza que deseja continuar?" || exit /b
call :mkstamp
call :matar
call :credenciais
if exist "%LocalAppData%\Microsoft\OneDrive\settings\" ren "%LocalAppData%\Microsoft\OneDrive\settings" "settings.bak_%stamp%"
if exist "%LocalAppData%\Microsoft\OneDrive\settings\" echo   [!] Nao foi possivel renomear a pasta settings ^(em uso^). Reinicie o PC e tente de novo.
if not exist "%LocalAppData%\Microsoft\OneDrive\settings\" echo   Pasta settings preservada como settings.bak_%stamp%
"%OD%" /reset
echo Aguardando o OneDrive reiniciar...
timeout /t 15 /nobreak >nul
tasklist /fi "imagename eq OneDrive.exe" | find /i "OneDrive.exe" >nul || call :iniciar
echo Se o OneDrive nao abrir sozinho em alguns minutos, inicie-o pelo menu Iniciar.
exit /b

:politica
echo.
set "pol="
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" 2>nul | findstr /i "DisableFileSync" && set "pol=1"
reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive" 2>nul | findstr /i "DisableFileSync" && set "pol=1"
if not defined pol echo Nenhuma politica de bloqueio encontrada. & exit /b
echo.
echo [!] Em computadores empresariais ou escolares, essas politicas sao do administrador de TI e podem voltar sozinhas.
call :ask "Remover os valores DisableFileSync e DisableFileSyncNGSC" || exit /b
call :mkbackup
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "%BK%\HKLM_policy_OneDrive.reg" /y >nul 2>&1
reg export "HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "%BK%\HKCU_policy_OneDrive.reg" /y >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSync /f >nul 2>&1
call :elev "reg delete HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive /v DisableFileSyncNGSC /f & reg delete HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive /v DisableFileSync /f"
echo Backup em: %BK%
echo Reinicie o OneDrive ^(opcao 2^) ou o PC.
exit /b

:uninstall
echo.
call :findsetup
if not defined SETUP echo [!] OneDriveSetup.exe nao encontrado no Windows. & exit /b
call :kfm
if defined KFM echo [!] Documentos ou Imagens estao redirecionados para o OneDrive.
if defined KFM echo     Desinstalar sem desfazer isso pode deixar essas pastas vazias ou fora do lugar.
if defined KFM call :ask "Tem certeza que deseja continuar?" || exit /b
call :ask "Desinstalar o aplicativo OneDrive. Os arquivos da pasta OneDrive NAO sao apagados. Continuar" || exit /b
call :matar
set "PM="
echo %OD%| findstr /i /c:"Program Files" >nul && set "PM=1"
if defined PM call :elev "%SETUP% /uninstall"
if not defined PM "%SETUP%" /uninstall
timeout /t 10 /nobreak >nul
call :findod
if defined OD echo [!] OneDrive ainda existe neste computador. A desinstalacao pode ter falhado ou ainda estar em andamento.
if not defined OD echo OneDrive desinstalado.
echo.
call :ask "Deseja mover tambem os dados do OneDrive para uma pasta backup? (AppData\Local\Microsoft\OneDrive)" || exit /b
call :mkbackup
if exist "%LocalAppData%\Microsoft\OneDrive\" ren "%LocalAppData%\Microsoft\OneDrive" "OneDrive.bak_%stamp%"
reg export "HKCU\Software\Microsoft\OneDrive" "%BK%\HKCU_OneDrive.reg" /y >nul 2>&1 && reg delete "HKCU\Software\Microsoft\OneDrive" /f >nul 2>&1
echo Backup do registro em: %BK%
echo Pasta do aplicativo preservada como OneDrive.bak_%stamp% em AppData\Local\Microsoft.
exit /b

:install
echo.
call :findsetup
if not defined SETUP echo [!] OneDriveSetup.exe nao encontrado no Windows. Baixe o instalador no site da Microsoft. & exit /b
call :ask "Instalar ou reinstalar o OneDrive agora" || exit /b
start "" /wait "%SETUP%"
echo Se a tela de login nao abrir, inicie o OneDrive pelo menu Iniciar.
exit /b