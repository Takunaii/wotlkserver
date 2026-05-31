@echo off

echo Starting AzerothCore DB...
docker compose up -d

timeout /t 5

echo Starting World Server...
start "" server\core\build\bin\Release\worldserver.exe

timeout /t 5

echo Starting Auth Server...
start "" server\core\build\bin\Release\authserver.exe

timeout /t 10

echo Launching WoW Client...
start "" "C:\Users\User\Documents\WoTLK 3.3.5a\Wow.exe"
