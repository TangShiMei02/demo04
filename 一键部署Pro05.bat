@echo off
chcp 65001 >nul

:: 获取仓库名
for %%F in ("%cd%") do set "repo_name=%%~nxF"
title Git 一键部署 - %repo_name%

:: 防呆检查
if not exist .git (
    echo [错误] 当前目录不是 Git 仓库！
    echo 请将本脚本放入包含 ".git" 文件夹的项目根目录中。
    echo.
    echo 10 秒后自动关闭...
    timeout /t 10 >nul
    exit /b
)
:: === 1. 选择推送通道 ===
choice /C HS /N /M "推送方式：H=HTTPS  S=SSH "
if %errorlevel%==1 (set "remote=https") else (set "remote=ssh")

:: === 2. 没有该 remote 就自动添加 ===
git remote | findstr /i "^%remote%$" >nul
if %errorlevel% neq 0 (
    echo 检测到缺少 %remote% 远程，正在自动添加...
    for /f "tokens=2" %%u in ('git remote -v ^| findstr /i origin.*fetch') do set "ori=%%u"
    if not defined ori (
        echo [错误] 请先确保已有 origin 远程地址！
        echo.
        pause >nul
        exit /b
    )
    :: 自动转换 origin 地址到对应协议
    setlocal enabledelayedexpansion
    if "%remote%"=="https" (
        set "newurl=!ori:git@github.com:=https://github.com/!"
    ) else (
        set "newurl=!ori:https://github.com/=git@github.com:!"
    )
    git remote add %remote% !newurl!
    endlocal
)

:: === 3. 更新说明 ===
set /p msg=请输入更新说明（直接回车=默认“update”）：
if "%msg%"=="" set msg=update

:: === 4. 自动获取当前分支 ===
for /f "tokens=3" %%b in ('git symbolic-ref --short HEAD 2^>nul') do set "branch=%%b"
if not defined branch set branch=main

:: === 5. 常规三板斧 ===
echo 正在添加文件...
git add .

echo 正在提交...
git commit -m "%msg%"
if %errorlevel% neq 0 (
    echo [错误] 提交失败，已终止后续推送！
    echo.
    pause >nul
    exit /b
)

echo 正在推送到 %remote% (%branch%)...
git push %remote% %branch%
if %errorlevel% neq 0 (
    echo [错误] 推送失败，请检查网络或权限！
    echo.
    pause >nul
    exit /b
)

echo ==================================================
echo 🚀 项目 %repo_name% 已成功部署到 %remote%！
echo 分支：%branch% ｜ 说明：“%msg%”
echo 30 秒后刷新网页即可看到更新
echo ==================================================
timeout /t 30 >nul