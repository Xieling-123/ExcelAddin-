@echo off
chcp 936 >nul
title Git 首次推送工具 (发布包专用)
setlocal enabledelayedexpansion

:: ==============================================================
:: 1. 配置区 (Configuration)
:: ==============================================================
set "LOCAL_DIR=C:\Users\20503\Desktop\Exceladdin1发布安装卸载"
set "GIT_URL=https://github.com/Xieling-123/ExcelAddin-.git"
set "BRANCH=main"
set "COMMIT_MSG=首次提交：ExcelAddin1 发布安装卸载包"

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
echo 开始执行首次推送流程...
echo ===================================================

:: 调用函数检查环境
call :CheckGit
if !errorlevel! neq 0 goto :End

:: 调用函数生成忽略文件（极其重要：防止证书泄露）
call :CreateGitIgnore

:: 调用函数初始化仓库
call :InitRepo

:: 调用函数配置远程地址
call :ConfigRemote

:: 调用函数执行推送
call :PushCode

echo.
echo ===================================================
echo [SUCCESS] 首次推送完成！请去 GitHub 刷新页面查看。
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
    echo [OK] Git 环境检测通过。
    exit /b 0

:CreateGitIgnore
    :: 【安全防线】如果本地没有 .gitignore，自动生成一个，拦截私钥证书和系统垃圾文件
    if not exist ".gitignore" (
        echo [INFO] 正在生成 .gitignore 文件...
        echo # 拦截所有私钥证书，防止泄露 >> .gitignore
        echo *.pfx >> .gitignore
        echo *.p12 >> .gitignore
        echo. >> .gitignore
        echo # 拦截系统自动生成的文件 >> .gitignore
        echo .vs/ >> .gitignore
        echo bin/ >> .gitignore
        echo obj/ >> .gitignore
        echo *.user >> .gitignore
        echo *.tmp >> .gitignore
    )
    exit /b 0

:InitRepo
    if not exist ".git" (
        echo [INFO] 正在初始化本地 Git 仓库...
        git init
        :: 强制将主分支重命名为 main
        git branch -M %BRANCH%
    ) else (
        echo [INFO] 本地已是 Git 仓库，跳过初始化。
    )
    exit /b 0

:ConfigRemote
    git remote get-url origin >nul 2>&1
    if errorlevel 1 (
        echo [INFO] 正在关联远程仓库...
        git remote add origin %GIT_URL%
    ) else (
        echo [INFO] 远程仓库已存在，正在更新地址...
        git remote set-url origin %GIT_URL%
    )
    exit /b 0

:PushCode
    echo [INFO] 正在添加文件到暂存区...
    git add .
    echo [INFO] 正在提交文件...
    git commit -m "%COMMIT_MSG%"
    echo [INFO] 正在推送到远程仓库 (首次推送可能会弹窗要求登录 GitHub)...
    git push -u origin %BRANCH%
    
    if !errorlevel! neq 0 (
        echo.
        echo [WARNING] 推送失败！请检查网络连接（如果连不上 GitHub，请开启加速器/VPN）。
    )
    exit /b 0

:End
    pause