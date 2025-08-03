@echo off
rem this is so stupid, but it Works On My Machine(tm) so it's good enough
if not exist C:\windows\system32\bash.exe goto :err
bash build.sh
:err
echo ERROR: WSL is required to use this batch script.