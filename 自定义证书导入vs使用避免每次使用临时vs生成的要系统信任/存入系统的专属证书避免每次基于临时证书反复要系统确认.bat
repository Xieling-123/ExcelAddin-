@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
title 生成并信任专属开发者证书

:: 1. 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: 2. 直接在当前脚本所在目录生成
cd /d "%~dp0"
set "PFX_FILE=%~dp0MyVSTODevCert.pfx"
set "PWD_STR=123456"

echo ========================================
echo 正在生成专属开发者证书...
echo 目标路径: %PFX_FILE%
echo 设置密码: %PWD_STR% (在VS中使用时需要输入)
echo ----------------------------------------

:: 如果已有旧文件则删除
if exist "%PFX_FILE%" del /f /q "%PFX_FILE%"

:: 执行 PowerShell 脚本生成证书
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=MyVSTODevCert' -CertStoreLocation 'Cert:\CurrentUser\My' -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256;" ^
    "  $pwd = ConvertTo-SecureString -String '%PWD_STR%' -Force -AsPlainText;" ^
    "  Export-PfxCertificate -Cert $cert -FilePath '%PFX_FILE%' -Password $pwd | Out-Null;" ^
    "  Write-Host '  [OK] 证书生成成功！' -ForegroundColor Green;" ^
    "} catch {" ^
    "  Write-Host '  [ERROR] 证书生成失败：' $_.Exception.Message -ForegroundColor Red;" ^
    "}"

:: 检查是否生成成功
if not exist "%PFX_FILE%" (
    echo.
    echo [致命错误] 无法生成证书文件，请截图上方报错信息。
    pause
    exit /b
)

echo.
echo 正在将证书导入系统信任区...
echo ----------------------------------------

:: 导入本机存储区 (带密码参数，防止失败)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$pwd = ConvertTo-SecureString -String '%PWD_STR%' -Force -AsPlainText; $c = Import-PfxCertificate -FilePath '%PFX_FILE%' -CertStoreLocation 'Cert:\LocalMachine\My' -Password $pwd -ErrorAction SilentlyContinue; if ($c) { Write-Host '  [OK] 个人存储区 (LocalMachine\My)' -ForegroundColor Green } else { Write-Host '  [FAIL] 个人存储区失败' -ForegroundColor Red }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$pwd = ConvertTo-SecureString -String '%PWD_STR%' -Force -AsPlainText; $c = Import-PfxCertificate -FilePath '%PFX_FILE%' -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $pwd -ErrorAction SilentlyContinue; if ($c) { Write-Host '  [OK] 根证书区 (LocalMachine\Root)' -ForegroundColor Green } else { Write-Host '  [FAIL] 根证书区失败' -ForegroundColor Red }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$pwd = ConvertTo-SecureString -String '%PWD_STR%' -Force -AsPlainText; $c = Import-PfxCertificate -FilePath '%PFX_FILE%' -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher' -Password $pwd -ErrorAction SilentlyContinue; if ($c) { Write-Host '  [OK] 发布者区 (LocalMachine\TrustedPublisher)' -ForegroundColor Green } else { Write-Host '  [FAIL] 发布者区失败' -ForegroundColor Red }"

echo ========================================
echo 操作完成！请查看当前文件夹下是否多出了 MyVSTODevCert.pfx。
echo.
pause