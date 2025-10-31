@echo off
setlocal

rem --- SETTINGS (edit if needed) ---
set "SERVER=SERVERNAME"
set "BACKUP_DIR=D:\SQL Data\Automated Backups"
set "SQLCMD=C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe"
rem ---------------------------------

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"

for %%D in (FOLDERS) do (
  if not exist "%BACKUP_DIR%\%%D" mkdir "%BACKUP_DIR%\%%D" >nul 2>&1
  "%SQLCMD%" -S "%SERVER%" -E -b -Q "BACKUP DATABASE [%%D] TO DISK=N'%BACKUP_DIR%\%%D\%%D_%STAMP%.bak' WITH INIT, COPY_ONLY, CHECKSUM, STATS=10"
  if errorlevel 1 exit /b 1
)

exit /b 0
