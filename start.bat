@echo off
rem Save this file in ANSI encoding for best compatibility

rem Start from script directory
cd /d "%~dp0"
set "APP_HOME=%~dp0"
set "APP_LOG=%APP_HOME%app.log"
set "ENV_LOG=%APP_HOME%env.log"

rem ========== User configurable parameters ==========
rem HIDE: 1=hidden run (default), 0=visible run
set "HIDE=1"
rem ENGINE: specify hide method, options: auto | powershell  | wscript | cscript
rem   auto: automatic selection with multi-level fallback (default)
rem   powershell: use PowerShell to hide window
rem   wscript: use wscript.exe with VBScript to hide window
rem   cscript: use cscript.exe with VBScript to hide window
set "ENGINE=auto"

echo HIDE  ENGINE ok > "%APP_LOG%"

rem ========== Child process marker (internal use only) ==========
if /i "%~1"=="--child" (
  set "HIDDEN_MODE=1"
  if not "%~2"=="" (set "HIDE_ENGINE=%~2") else set "HIDE_ENGINE=unknown"
  goto :run
) else (
  set "HIDDEN_MODE=0"
  set "HIDE_ENGINE=visible"
)

rem ========== Hidden startup mechanism with multi-level fallback ==========
if "%HIDE%"=="1" (
  echo [%date% %time%] Parent process PID=%RANDOM%: Starting with HIDE=1 ENGINE=%ENGINE% >> "%APP_LOG%"
  
  rem If specific engine is specified, jump directly to that method
  if /i "%ENGINE%"=="powershell" (
    echo [%date% %time%] Forced to use PowerShell method >> "%APP_LOG%"
    goto :hide_powershell
  )

  if /i "%ENGINE%"=="wscript" (
    echo [%date% %time%] Forced to use wscript method >> "%APP_LOG%"
    goto :hide_wscript
  )
  if /i "%ENGINE%"=="cscript" (
    echo [%date% %time%] Forced to use cscript method >> "%APP_LOG%"
    goto :hide_cscript
  )

  rem ENGINE=auto: try methods in order (PowerShell  -> wscript -> cscript)
  
  :hide_powershell
  rem Try multiple PowerShell paths for better compatibility
  set "PS_EXE="
  
  rem Method 1: Standard 64-bit location
  set "PS_TEST=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
  if exist "%PS_TEST%" (
    set "PS_EXE=%PS_TEST%"
    echo [%date% %time%] [AUTO] Found PowerShell at: System32 >> "%APP_LOG%"
    goto :ps_found
  )
  
  rem Method 2: SysNative (for 32-bit process on 64-bit system)
  set "PS_TEST=%SystemRoot%\SysNative\WindowsPowerShell\v1.0\powershell.exe"
  if exist "%PS_TEST%" (
    set "PS_EXE=%PS_TEST%"
    echo [%date% %time%] [AUTO] Found PowerShell at: SysNative >> "%APP_LOG%"
    goto :ps_found
  )
  
  rem Method 3: Use 'where' command
  for /f "usebackq delims=" %%P in (`where powershell.exe 2^>nul`) do (
    set "PS_EXE=%%P"
    echo [%date% %time%] [AUTO] Found PowerShell via where: %%P >> "%APP_LOG%"
    goto :ps_found
  )
  
  rem PowerShell not found
  echo [%date% %time%] [AUTO] PowerShell not found, trying next method >> "%APP_LOG%"
  echo [%date% %time%] [AUTO] SystemRoot=%SystemRoot% >> "%APP_LOG%"
  if /i not "%ENGINE%"=="auto" goto :visible_fallback
  goto :hide_wscript
  
  :ps_found
  echo [%date% %time%] [AUTO] Trying PowerShell hide method >> "%APP_LOG%"
  echo [%date% %time%] [AUTO] PowerShell exe: %PS_EXE% >> "%APP_LOG%"
  start "" /min "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "& '%~f0' --child powershell"
  echo [%date% %time%] [AUTO] PowerShell start command executed, parent exiting >> "%APP_LOG%"
  exit /b 0


  :hide_wscript
  echo [%date% %time%] [AUTO] Trying wscript hide method >> "%APP_LOG%"
  set "_VBS=%TEMP%\run_%~n0_%RANDOM%.vbs"
  (
    echo Set WshShell = CreateObject("WScript.Shell"^)
    echo WshShell.Run """%~f0"" --child wscript", 0, False
  ) > "%_VBS%"
  where wscript.exe >nul 2>&1
  if %ERRORLEVEL%==0 (
    start "" /min wscript //nologo "%_VBS%"
    timeout /t 1 /nobreak >nul
    del "%_VBS%" >nul 2>&1
    echo [%date% %time%] [AUTO] wscript start command executed, parent exiting >> "%APP_LOG%"
    exit /b 0
  ) else (
    del "%_VBS%" >nul 2>&1
    echo [%date% %time%] [AUTO] wscript not found, trying next method >> "%APP_LOG%"
  )
  if /i not "%ENGINE%"=="auto" goto :visible_fallback

  :hide_cscript
  echo [%date% %time%] [AUTO] Trying cscript hide method >> "%APP_LOG%"
  set "_VBS=%TEMP%\run_%~n0_%RANDOM%.vbs"
  (
    echo Set WshShell = CreateObject("WScript.Shell"^)
    echo WshShell.Run """%~f0"" --child cscript", 0, False
  ) > "%_VBS%"
  where cscript.exe >nul 2>&1
  if %ERRORLEVEL%==0 (
    start "" /min cscript //nologo "%_VBS%"
    timeout /t 1 /nobreak >nul
    del "%_VBS%" >nul 2>&1
    echo [%date% %time%] [AUTO] cscript start command executed, parent exiting >> "%APP_LOG%"
    exit /b 0
  ) else (
    del "%_VBS%" >nul 2>&1
    echo [%date% %time%] [AUTO] cscript not found >> "%APP_LOG%"
  )
  if /i not "%ENGINE%"=="auto" goto :visible_fallback
)

:visible_fallback
rem All hide methods failed or HIDE=0: run in visible window
echo [INFO] Running in visible window (hide disabled or all methods failed)...
echo [%date% %time%] Fallback to visible mode >> "%APP_LOG%"

:run
rem Enable delayed expansion for classpath building
setlocal EnableDelayedExpansion

rem Capture current environment for debugging
set > "%ENV_LOG%" 2>nul

rem Log session start
echo ========================================== >> "%APP_LOG%"
echo [%date% %time%] === Child Process Started === >> "%APP_LOG%"
echo [%date% %time%] HIDDEN_MODE=%HIDDEN_MODE% HIDE_ENGINE=%HIDE_ENGINE% >> "%APP_LOG%"
echo [%date% %time%] Script Path: "%~f0" >> "%APP_LOG%"
echo [%date% %time%] APP_HOME: %APP_HOME% >> "%APP_LOG%"
echo [%date% %time%] Current Directory: %CD% >> "%APP_LOG%"
echo [%date% %time%] Command Line Args: %* >> "%APP_LOG%"

rem Find Java executable: prioritize bundled JRE, fallback to system Java
set "JAVA_EXE="
if exist "%APP_HOME%jre1.8.0_251\bin\java.exe" (
  set "JAVA_EXE=%APP_HOME%jre1.8.0_251\bin\java.exe"
  echo [%date% %time%] Using bundled JRE: "%JAVA_EXE%" >> "%APP_LOG%"
) else (
  echo [%date% %time%] Bundled JRE not found, searching system Java... >> "%APP_LOG%"
  for /f "usebackq delims=" %%J in (`where java 2^>nul`) do (
    set "JAVA_EXE=%%~J"
    goto :have_java
  )
  rem Fallback: try java command directly
  java -version >nul 2>&1 && set "JAVA_EXE=java"
)

:have_java
rem Exit if Java not found
if not defined JAVA_EXE (
  echo [%date% %time%] ERROR: Java not found >> "%APP_LOG%"
  echo [%date% %time%] Please install Java or place jre1.8.0_251 in script directory >> "%APP_LOG%"
  echo [%date% %time%] HIDDEN_MODE=%HIDDEN_MODE% HIDE_ENGINE=%HIDE_ENGINE% >> "%APP_LOG%"
  if "%HIDDEN_MODE%"=="0" (
    echo.
    echo ERROR: Java not found
    echo Please install Java or place jre1.8.0_251 folder in the script directory
    echo.
    pause
  )
  endlocal & exit /b 1
)



rem Log Java information
echo [%date% %time%] Java Executable: "%JAVA_EXE%" >> "%APP_LOG%"
echo [%date% %time%] Java Version Info: >> "%APP_LOG%"
"%JAVA_EXE%" -version >> "%APP_LOG%" 2>&1

rem Verify classes directory exists
if not exist "%APP_HOME%classes\" (
  echo [%date% %time%] ERROR: classes directory not found: "%APP_HOME%classes" >> "%APP_LOG%"
  if "%HIDDEN_MODE%"=="0" (
    echo.
    echo ERROR: classes directory not found
    echo Expected location: %APP_HOME%classes
    echo.
    pause
  )
  endlocal & exit /b 1
)

rem Build classpath: start with classes directory
set "APP_CLASSPATH=%APP_HOME%classes"

rem Add all JAR files from lib directory if it exists
if exist "%APP_HOME%lib\" (
  echo [%date% %time%] Scanning lib directory for JAR files... >> "%APP_LOG%"
  for %%J in ("%APP_HOME%lib\*.jar") do (
    set "APP_CLASSPATH=!APP_CLASSPATH!;%%~J"
    echo [%date% %time%]   Added JAR: %%~nxJ >> "%APP_LOG%"
  )
) else (
  echo [%date% %time%] WARNING: lib directory not found (no JAR dependencies will be loaded) >> "%APP_LOG%"
)

rem Check if main class file exists
if exist "%APP_HOME%classes\com\rdsp\zero\VerifyTool.class" (
  echo [%date% %time%] Main class file verified: VerifyTool.class >> "%APP_LOG%"
) else (
  echo [%date% %time%] WARNING: Main class file not found >> "%APP_LOG%"
  echo [%date% %time%] Expected: %APP_HOME%classes\com\rdsp\zero\VerifyTool.class >> "%APP_LOG%"
  if "%HIDDEN_MODE%"=="0" (
    echo WARNING: Main class file may not exist
    echo Expected: com\rdsp\zero\VerifyTool.class
  )
)


rem Log execution details
echo [%date% %time%] Final CLASSPATH: %APP_CLASSPATH% >> "%APP_LOG%"
echo [%date% %time%] Main Class: com.zero.VerifyTool >> "%APP_LOG%"
echo [%date% %time%] Command: "%JAVA_EXE%" -cp "%APP_CLASSPATH%" com.zero.VerifyTool >> "%APP_LOG%"
echo [%date% %time%] Starting Java application... >> "%APP_LOG%"

rem Execute Java application with output redirected to log
"%JAVA_EXE%" -cp "%APP_CLASSPATH%" com.zero.VerifyTool >> "%APP_LOG%" 2>&1
set "RC=!ERRORLEVEL!"

rem Log exit status
echo [%date% %time%] Java application exited with code: !RC! >> "%APP_LOG%"
echo [%date% %time%] === Run Session Ended === >> "%APP_LOG%"

rem Show error message in visible mode if Java failed
if "%HIDDEN_MODE%"=="0" (
  if !RC! neq 0 (
    echo.
    echo ==========================================
    echo Java application exited abnormally
    echo Exit code: !RC!
    echo Please check app.log for detailed error information
    echo Log location: %APP_LOG%
    echo ==========================================
    echo.
    pause
  ) else (
    echo.
    echo Java application completed successfully
    echo.
  )
)

rem Exit with Java's exit code
endlocal & exit /b %RC%
