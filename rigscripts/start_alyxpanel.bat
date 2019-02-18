@echo off

echo .
echo .
echo      Press ENTER twice to RESTART MATLAB
echo      and start ~ALYXPANEL~.
echo .
echo      Otherwise, CLOSE THIS WINDOW.
echo .

SET /P trashvariable=...
SET /P trashvariable=once more restarts MATLAB

taskkill /F /IM matlab.exe
start matlab -r "ap = eui.AlyxPanel; ap.login;"