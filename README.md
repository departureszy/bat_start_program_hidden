Windows bat 后台运行的方式
参数参考以下注释
rem ========== User configurable parameters ==========
rem HIDE: 1=hidden run (default), 0=visible run
set "HIDE=1"
rem ENGINE: specify hide method, options: auto | powershell  | wscript | cscript
rem   auto: automatic selection with multi-level fallback (default)
rem   powershell: use PowerShell to hide window
rem   wscript: use wscript.exe with VBScript to hide window
rem   cscript: use cscript.exe with VBScript to hide window
set "ENGINE=auto"

mshta方式未验证通过，此脚本放弃此方式
