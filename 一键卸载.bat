@echo off
chcp 936 >nul
title Excel 插件一键卸载清理程序 (终极彻底版)

:: ==============================================================
:: ?? 请在这里修改为你实际发布的插件名称（注册表里的名字，非中文）
:: ==============================================================
set "PLUGIN_NAME=ExcelAddIn1"

:: ==============================================================
:: 1. 自动获取管理员权限
:: ==============================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

echo ===================================================
echo [1/5] 正在关闭 Excel 及相关进程...
echo ===================================================
taskkill /f /im excel.exe >nul 2>&1
taskkill /f /im setup.exe >nul 2>&1
taskkill /f /im VSTOInstaller.exe >nul 2>&1
echo [OK] 进程已清理。

echo.
echo ===================================================
echo [2/5] 正在清理 VSTO 及 Office 底层缓存...
echo ===================================================
:: 清理 VSTO 缓存（解决重装报错的核心）
rd /s /q "%LOCALAPPDATA%\Microsoft\VSTO\SolutionCache" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Microsoft\VSTO\Security" >nul 2>&1
:: 清理 Office 缓存
rd /s /q "%LOCALAPPDATA%\Microsoft\Office\16.0\WebServiceCache" >nul 2>&1
:: 清理加载项缓存（有些老式插件会残留在这里）
rd /s /q "%APPDATA%\Microsoft\AddIns" >nul 2>&1
:: 清理 ClickOnce 缓存
rundll32 dfshim.dll,CleanOnlineAppCache >nul 2>&1
echo [OK] 底层缓存清理完毕！

echo.
echo ===================================================
echo [3/5] 正在清理注册表残留 (HKCU 与 HKLM)...
echo ===================================================
:: 针对当前用户清理
reg delete "HKCU\Software\Microsoft\Office\Excel\Addins\%PLUGIN_NAME%" /f >nul 2>&1
:: 针对本机所有用户清理
reg delete "HKLM\Software\Microsoft\Office\Excel\Addins\%PLUGIN_NAME%" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Office\Excel\Addins\%PLUGIN_NAME%" /f >nul 2>&1

:: 清理 VSTO 信任列表中的历史记录
reg delete "HKCU\Software\Microsoft\VSTO\Security\Inclusion" /f >nul 2>&1

:: 清理 Excel 启动时强加载的顽固残留 (Options 里的 OPEN 键)
:: 注意：这里如果你有其他的合法插件，也会被清理，请谨慎使用。
for /f "tokens=1*" %%a in ('reg query "HKCU\Software\Microsoft\Office\Excel\Options" 2^>nul ^| findstr /i "OPEN"') do (
    reg delete "HKCU\Software\Microsoft\Office\Excel\Options" /v "%%a" /f >nul 2>&1
)
echo [OK] 注册表残留清理完毕！

echo.
echo ===================================================
echo [4/5] 尝试自动卸载安装包...
echo ===================================================
:: 尝试通过 WMI 查找并卸载（这里用通用名称，如果找不到需手动去控制面板）
:: 注意：如果你的安装包名字很特殊，这步可能无法静默卸载，会退回到第5步
powershell -NoProfile -Command "Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*%PLUGIN_NAME%*' } | ForEach-Object { $_.Uninstall() }" >nul 2>&1
echo [OK] 自动卸载指令已发送。

echo.
echo ===================================================
echo [5/5] 打开控制面板，请手动检查并完成最后一步卸载...
echo ===================================================
:: 弹窗提示用户
mshta vbscript:msgbox("缓存、注册表及残留已彻底清理完毕！" & vbCrLf & vbCrLf & "如果【控制面板】中仍有残留项，请右键点击【卸载】！" & vbCrLf & "如果提示需要卸载程序，直接点【是】即可忽略。", 64, "清理完成")(window.close)

:: 打开控制面板的“程序和功能”界面
start appwiz.cpl

echo.
echo ===================================================
echo 脚本执行结束。按任意键退出。
pause >nul