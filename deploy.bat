@echo off
setlocal
pushd "%~dp0"

set "TOMCAT_DIR=C:\apache-tomcat-10.1.28"
set "PROJECT_NAME=Biblio"
set "WAR_NAME=%PROJECT_NAME%.war"
set "TARGET_WAR=%~dp0target\%WAR_NAME%"
set "DEST_DIR=%TOMCAT_DIR%\webapps"

echo.
echo ========================
echo Déploiement de %PROJECT_NAME%
echo ========================

echo [0/4] Contenu initial du dossier target :
dir "%~dp0target"

echo [0.5/4] Contenu du webapps avant any change :
dir "%DEST_DIR%"

echo.
echo [1/4] mvn clean package...
call mvn clean package
if errorlevel 1 goto EndFail

echo.
echo [2/4] Vérification du .war...
if not exist "%TARGET_WAR%" (
  echo ERREUR : "%TARGET_WAR%" introuvable
  goto EndFail
) else echo OK : WAR présent.

echo.
echo [3/4] Suppression de l’ancienne version...
if exist "%DEST_DIR%\%WAR_NAME%" del /f /q "%DEST_DIR%\%WAR_NAME%"
if exist "%DEST_DIR%\%PROJECT_NAME%" rmdir /s /q "%DEST_DIR%\%PROJECT_NAME%"

echo.
echo [4/4] Copie du nouveau .war avec robocopy…
robocopy "%~dp0target" "%DEST_DIR%" "%WAR_NAME%" /NFL /NDL /NJH /NJS /nc /ns /np
if errorlevel 1 goto EndFail

echo.
echo Contenu du webapps après copie :
dir "%DEST_DIR%\%WAR_NAME%"

echo.
echo Déploiement terminé avec succès !
echo Accès : http://localhost:8090/%PROJECT_NAME%
echo.
pause
exit /b 0

:EndFail
echo.
echo **Déploiement interrompu**. Code d’erreur : %ERRORLEVEL%
pause
exit /b %ERRORLEVEL%


