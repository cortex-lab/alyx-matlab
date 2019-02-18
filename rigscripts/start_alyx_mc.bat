@echo off

echo .
echo .
echo      Press ENTER twice to RESTART MATLAB
echo      and start ~ALYX and MC~.
echo .
echo      Otherwise, CLOSE THIS WINDOW.
echo .

SET /P trashvariable=...
SET /P trashvariable=once more restarts MATLAB

taskkill /F /IM matlab.exe
start matlab -r "m = mc; ap = eui.AlyxPanel; ap.login; m.AlyxPanel.login"