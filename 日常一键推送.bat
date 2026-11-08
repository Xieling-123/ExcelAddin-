@echo off
chcp 936 >nul
title Git 日常一键推送工具 (发布包专用)
setlocal enabledelayedexpansion

:: ==============================================================
:: 1. 配置区 (Configuration)
:: ==============================================================
set "LOCAL_DIR=C:\Users\20503\Desktop\Exceladdin1发布安装卸载"
set "BRANCH=main"

:: 切换工作目录
cd /d "%LOCAL_DIR%"
if errorlevel 1 (
    echo [ERROR] 找不到目录: %LOCAL_DIR%
    pause
    exit /b
)

:: ==============================================================
:: 2. 主函数 (Main)
:: ==============================================================
echo ===================================================
echo 开始执行日常推送流程...
echo ===================================================

:: 检查 Git 环境
call :CheckGit
if !errorlevel! neq 0 goto :End

:: 检查是否有变动
call :CheckChanges
if !errorlevel! equ 1 (
    echo [INFO] 未检测到文件变动，无需备份。
    goto :End
)

:: 获取当前时间
call :GetCurrentTime

:: 执行提交和推送
call :CommitAndPush

echo.
echo ===================================================
echo [SUCCESS] 日常备份推送完成！
echo ===================================================
goto :End

:: ==============================================================
:: 3. 函数区 (Functions)
:: ==============================================================

:CheckGit
    git --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] 未检测到 Git 环境，请先安装 Git！
        exit /b 1
    )
    exit /b 0

:CheckChanges
    :: 检测工作区和暂存区是否有变动（如果有输出，说明有变动）
    for /f %%i in ('git status --porcelain') do exit /b 0
    :: 如果没输出，说明没变动，返回 1
    exit /b 1

:GetCurrentTime
    :: 获取形如 2023-11-09 15:30:00 的时间格式
    set "dt=%date:~0,4%-%date:~5,2%-%date:~8,2% %time:~0,2%:%time:~3,2%:%time:~6,2%"
    :: 如果小时是个位数（比如 9点），系统会生成 " 9:30"，这里替换空格为0
    set "dt=!dt: =0!"
    exit /b 0

:CommitAndPush
    echo [INFO] 检测到变动，正在添加文件...
    git add .
    
    echo [INFO] 正在提交代码 (时间: !dt!)...
    git commit -m "日常备份: !dt!"
    
    echo [INFO] 正在推送到 GitHub...
    git push origin %BRANCH%
    
    if !errorlevel! neq 0 (
        echo.
        echo [WARNING] 推送失败！可能原因：
        echo 1. 网络问题（连不上 GitHub，请开启加速器/VPN）
        echo 2. 仓库文件过大（GitHub 限制单个文件最大 100MB）
    )
    exit /b 0

:End
    :: 如果不想每次点完都按任意键，可以把下面这行删掉
    pause