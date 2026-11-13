@echo off
chcp 65001 >nul
echo.
echo  Salvar a chave do ElevenLabs (fica FORA do projeto, nunca vai para o GitHub)
echo  ---------------------------------------------------------------------------
echo.
set /p KEY=Cole a chave aqui (clique com o botao direito para colar) e aperte Enter:
if "%KEY%"=="" (
  echo Nenhuma chave colada. Nada foi salvo.
  pause
  exit /b 1
)
if not exist "%USERPROFILE%\Documents\HerdeiroDosCeus_chave" mkdir "%USERPROFILE%\Documents\HerdeiroDosCeus_chave"
<nul set /p ="%KEY%" > "%USERPROFILE%\Documents\HerdeiroDosCeus_chave\elevenlabs.txt"
set KEY=
echo.
echo Chave salva em Documentos\HerdeiroDosCeus_chave\elevenlabs.txt
echo Testando a chave...
echo.
cd /d "%~dp0..\.."
python -X utf8 tools\audio\eleven.py status
echo.
pause
