@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: 检查管理员权限
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 请求管理员权限...
    PowerShell -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    exit /b
)

cls
echo ==================================================
echo                 Git安装与配置工具
echo ==================================================
echo.
echo 警告: 此脚本将安装Git并配置相关设置，
echo 可能会修改系统设置。请确保您了解操作风险。
echo.
choice /C YN /N /M "是否继续? [Y/N]: "
if errorlevel 2 (
    echo 已取消操作。
    timeout /t 2 /nobreak
    exit /b
)

:: 创建日志文件
set "logfile=%~dp0git-setup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "logfile=%logfile: =0%"
echo 开始安装和配置Git - %date% %time% > "%logfile%"

cls
echo ==================================================
echo                 安装Git
echo ==================================================
echo.
echo 正在检查Git是否已安装...
git --version >nul 2>&1
if %errorlevel% EQU 0 (
    echo Git已安装。若要重新安装，请您开启代理环境；若不重新安装则开始初始化配置。
    echo 版本: 
    git --version
    echo.
    choice /C YN /N /M "是否重新安装? [Y/N]: "
    if errorlevel 2 goto CONFIGURE_GIT
)

echo 正在下载Git安装程序...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe', '%TEMP%\Git-2.42.0.2-64-bit.exe')" >> "%logfile%" 2>&1

echo 正在安装Git...
start /wait "" "%TEMP%\Git-2.42.0.2-64-bit.exe" /SILENT /NORESTART >> "%logfile%" 2>&1

echo 正在验证安装...
git --version
if %errorlevel% EQU 0 (
    echo Git安装成功。
    echo Git安装成功 >> "%logfile%"
) else (
    echo Git安装失败。
    echo Git安装失败 >> "%logfile%"
    pause
    goto EXIT
)

:CONFIGURE_GIT
cls
echo ==================================================
echo                配置Git
echo ==================================================
echo.

set /p git_username="请输入您的Git用户名: "
set /p git_email="请输入您的Git邮箱: "

echo 设置 Git 用户名和邮箱...
git config --global user.name "%git_username%"
git config --global user.email "%git_email%"

echo 设置 Git 默认分支名称为main...
git config --global init.defaultBranch main

echo 设置 Git 使用LF换行符...
git config --global core.autocrlf input

echo 生成 SSH 密钥...
ssh-keygen -t ed25519 -C "%git_email%" -f "%USERPROFILE%\.ssh\id_ed25519" -N "" >> "%logfile%" 2>&1

echo 正在启动 SSH 代理...
powershell -Command "Start-Service ssh-agent" >> "%logfile%" 2>&1

echo 将 SSH 密钥添加到代理...
ssh-add "%USERPROFILE%\.ssh\id_ed25519" >> "%logfile%" 2>&1

set "desktop=%USERPROFILE%\Desktop"
set "pubkey_file=%desktop%\git_ssh_public_key.txt"
echo 您的 SSH 公钥已保存到: %pubkey_file%
type "%USERPROFILE%\.ssh\id_ed25519.pub" > "%pubkey_file%"

echo.
echo ==================================================
echo                  SSH 公钥信息
echo ==================================================
echo.
type "%USERPROFILE%\.ssh\id_ed25519.pub"
echo.
echo ==================================================
echo 公钥已复制到剪贴板并保存到桌面
echo 请将此公钥添加到您的账户。
echo ==================================================
echo.

:: 复制公钥到剪贴板
powershell -Command "Get-Content '%USERPROFILE%\.ssh\id_ed25519.pub' | Set-Clipboard"

:EXIT
cls
echo ==================================================
echo                 Git安装与配置工具
echo ==================================================
echo.
echo Git已成功安装并配置。
echo.
echo 安装日志已保存到: %logfile%
echo.
echo SSH公钥已保存到桌面: git_ssh_public_key.txt
echo 公钥内容已复制到剪贴板
echo.
echo 请将SSH公钥添加到您的Git服务提供商账户。
echo.
timeout /t 10 /nobreak
exit /b