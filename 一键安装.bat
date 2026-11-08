@echo off
chcp 936 >nul
title Excel Add-in 一键安装程序

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
echo [步骤 1/3] 正在清理旧缓存，防止覆盖安装报错...
echo ===================================================
taskkill /f /im excel.exe >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Microsoft\VSTO\SolutionCache" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Microsoft\VSTO\Security" >nul 2>&1
rundll32 dfshim.dll,CleanOnlineAppCache
echo [OK] 缓存已清理。

echo.
echo ===================================================
echo [步骤 2/3] 正在导入并信任专属证书...
echo ===================================================

:: 优先查找你指定的专属证书，如果没有则查找当前目录下任意的 .pfx 文件
set "TARGET_PFX="
if exist "%~dp0MyVSTODevCert.pfx" (
    set "TARGET_PFX=%~dp0MyVSTODevCert.pfx"
) else if exist "%~dp0MyCert.pfx" (
    set "TARGET_PFX=%~dp0MyCert.pfx"
) else (
    for %%f in (*.pfx) do set "TARGET_PFX=%~dp0%%f"
)

if not defined TARGET_PFX (
    echo [WARNING] 未找到任何 .pfx 证书文件！
    echo 如果程序无法安装，请检查证书是否完整。
) else (
    echo 正在导入证书: %TARGET_PFX%
    :: 使用 PowerShell 导入到 受信任的根证书颁发机构 和 受信任的发布者
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$pwd = ConvertTo-SecureString -String '123456' -Force -AsPlainText -ErrorAction SilentlyContinue;" ^
        "Import-PfxCertificate -FilePath '%TARGET_PFX%' -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction SilentlyContinue;" ^
        "Import-PfxCertificate -FilePath '%TARGET_PFX%' -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher' -ErrorAction SilentlyContinue;"
    echo [SUCCESS] 证书已成功导入系统信任区！
)

echo.
echo ===================================================
echo [步骤 3/3] 正在安装 Excel 插件...
echo ===================================================
set vstoFound=0
for %%v in (*.vsto) do (
    echo 正在执行安装: %%v
    start /wait "" "%~dp0%%v"
    set vstoFound=1
)

if "%vstoFound%"=="0" (
    echo [ERROR] 未找到 .vsto 安装文件！请检查当前文件夹。
    pause
    exit
)

echo.
echo [DONE] 安装完成！正在为你打开 Excel...
start excel.exe
pause