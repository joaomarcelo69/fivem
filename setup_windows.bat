@echo off
REM Download e Setup Automático FXServer - Português
REM Para Windows

echo 🇵🇹 Setup Automático - Servidor FiveM Português
echo ================================================

REM Criar pastas
mkdir fxserver_download 2>nul
mkdir servidor-pt 2>nul

echo [INFO] Baixando repositório...
git clone https://github.com/joaomarcelo69/fivem.git servidor-pt
cd servidor-pt

echo.
echo [INFO] Downloads necessários:
echo.
echo 1. FXServer (Windows):
echo    https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
echo    ^(Baixa a versão mais recente e extrai para: servidor-pt\fxserver\^)
echo.
echo 2. MariaDB (Windows):
echo    https://mariadb.org/download/
echo    ^(Instala com password root: fivemrootpass^)
echo.
echo 3. Node.js (Windows):
echo    https://nodejs.org/
echo    ^(Instala versão LTS^)
echo.

echo [INFO] Após instalar as dependências, executa:
echo.
echo   setup_final.bat
echo.

REM Criar script final
echo @echo off > setup_final.bat
echo echo [INFO] Configurando dependências Node.js... >> setup_final.bat
echo cd fxserver\resources\screenshot-basic >> setup_final.bat
echo npm install >> setup_final.bat
echo npm run build >> setup_final.bat
echo cd ..\..\.. >> setup_final.bat
echo. >> setup_final.bat
echo echo [INFO] Criando base de dados... >> setup_final.bat
echo mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS qbcore;" >> setup_final.bat
echo mysql -u root -p qbcore ^< server-data\sql\qbcore_min_schema.sql >> setup_final.bat
echo mysql -u root -p qbcore ^< server-data\sql\pt_schema.sql >> setup_final.bat
echo. >> setup_final.bat
echo echo [INFO] Criando script de arranque... >> setup_final.bat
echo echo @echo off ^> start_server.bat >> setup_final.bat
echo echo echo 🇵🇹 Iniciando Servidor FiveM Português... ^>^> start_server.bat >> setup_final.bat
echo echo echo Acede: 127.0.0.1:30125 ^>^> start_server.bat >> setup_final.bat
echo echo echo txAdmin: http://127.0.0.1:40120 ^>^> start_server.bat >> setup_final.bat
echo echo echo. ^>^> start_server.bat >> setup_final.bat
echo echo cd fxserver ^>^> start_server.bat >> setup_final.bat
echo echo FXServer.exe +exec server.cfg ^>^> start_server.bat >> setup_final.bat
echo. >> setup_final.bat
echo echo. >> setup_final.bat
echo echo 🎉 Setup Completo! >> setup_final.bat
echo echo ================= >> setup_final.bat
echo echo. >> setup_final.bat
echo echo [INFO] Para iniciar o servidor: >> setup_final.bat
echo echo   start_server.bat >> setup_final.bat
echo echo. >> setup_final.bat
echo echo [INFO] Depois conecta no FiveM: >> setup_final.bat
echo echo   IP: 127.0.0.1:30125 >> setup_final.bat
echo echo. >> setup_final.bat
echo echo [IMPORTANTE] Adiciona a tua license key em server-data\server.cfg! >> setup_final.bat
echo echo. >> setup_final.bat

echo [INFO] Scripts criados!
echo [INFO] Segue as instruções acima para completar o setup.

pause