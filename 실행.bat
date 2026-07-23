@echo off
chcp 65001 >nul
echo 헬스보이짐 OT 시스템을 시작합니다...
start "" http://localhost:8766/
"C:\Users\home\AppData\Local\Programs\Python\Python312\python.exe" -m http.server 8766 --directory "%~dp0build\web"
