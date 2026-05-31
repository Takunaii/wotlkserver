@echo off

taskkill /IM worldserver.exe /F
taskkill /IM authserver.exe /F

docker compose down
