# Windows ホスト側のブートストラップ。WSL2 + WezTerm + Git + フォント + dotfiles repo を冪等に揃える。
#
# Usage (管理者 PowerShell で):
#   irm https://raw.githubusercontent.com/etherpoc/dotfiles/main/windows/bootstrap.ps1 | iex
#
#   または手動 clone 後:
#   pwsh -ExecutionPolicy Bypass -File $env:USERPROFILE\dotfiles\windows\bootstrap.ps1

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# 管理者権限チェック
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: 管理者として実行してください (右クリック > Run as administrator)" -ForegroundColor Red
    exit 1
}

$RepoUrl     = "https://github.com/etherpoc/dotfiles.git"
$DotfilesDir = Join-Path $env:USERPROFILE "dotfiles"

function Step([string]$msg) {
    Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Install-Winget {
    param([string]$Id, [string]$Name)
    Write-Host "  [$Name] checking..."
    $listed = winget list --id $Id -e --source winget 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed -match [regex]::Escape($Id))) {
        Write-Host "    already installed"
    } else {
        winget install --id $Id -e --source winget `
            --accept-source-agreements --accept-package-agreements --silent
    }
}

# 1. winget パッケージ
Step "Installing packages via winget"
Install-Winget -Id "wez.wezterm"               -Name "WezTerm"
Install-Winget -Id "Git.Git"                   -Name "Git for Windows"
Install-Winget -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal"

# 2. WSL2 + Ubuntu
Step "Installing WSL2 + Ubuntu"
$wslList = (wsl --list --quiet 2>$null) -replace "`0", ""
if ($wslList -match "Ubuntu") {
    Write-Host "  Ubuntu already installed"
} else {
    wsl --install -d Ubuntu --no-launch
    Write-Host "  Ubuntu installed (PC reboot may be required for full WSL2 setup)"
}

# 3. dotfiles repo clone
Step "Cloning dotfiles repo to $DotfilesDir"
$gitExe = "$env:ProgramFiles\Git\bin\git.exe"
if (-not (Test-Path $gitExe)) { $gitExe = "git" }  # PATH 経由のフォールバック

if (Test-Path (Join-Path $DotfilesDir ".git")) {
    Write-Host "  Repo exists; pulling latest"
    & $gitExe -C $DotfilesDir pull --ff-only
} else {
    & $gitExe clone $RepoUrl $DotfilesDir
}

# 4. wezterm.lua を %USERPROFILE%\.wezterm.lua に配置
Step "Placing wezterm.lua"
$weztermSrc = Join-Path $DotfilesDir "windows\wezterm.lua"
$weztermDst = Join-Path $env:USERPROFILE ".wezterm.lua"
Copy-Item -Path $weztermSrc -Destination $weztermDst -Force
Write-Host "  $weztermSrc -> $weztermDst"

# 5. フォントインストール (ユーザースコープ)
function Install-FontPack {
    param(
        [string]$Url,
        [string]$Name,
        [string]$FileFilter = "*.ttf",
        [string]$SubdirFilter = ""
    )
    Write-Host "  [$Name] downloading..."
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "dotfiles-fonts\$Name") -Force
    $zipPath = Join-Path $tempDir "font.zip"
    Invoke-WebRequest -Uri $Url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $userFonts = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    $regPath   = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    New-Item -ItemType Directory -Path $userFonts -Force | Out-Null
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

    $searchDir = $tempDir
    if ($SubdirFilter) {
        $matched = Get-ChildItem -Path $tempDir -Directory -Filter $SubdirFilter -Recurse | Select-Object -First 1
        if ($matched) { $searchDir = $matched.FullName }
    }

    $fonts = Get-ChildItem -Path $searchDir -Filter $FileFilter -Recurse
    foreach ($font in $fonts) {
        $dest = Join-Path $userFonts $font.Name
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $font.FullName -Destination $dest
        }
        $fontName = "$($font.BaseName) (TrueType)"
        Set-ItemProperty -Path $regPath -Name $fontName -Value $dest -Type String -Force
    }
    Write-Host "    installed $($fonts.Count) font file(s)"
}

Step "Installing fonts"

# JetBrainsMono Nerd Font
Install-FontPack `
    -Url "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" `
    -Name "JetBrainsMono"

# PlemolJP Console NF (latest release を API で解決)
# asset 名は時期によって PlemolJP_NF_v1.2.3.zip / PlemolJP_NF-v1.2.3.zip など揺れるので
# regex で吸収しつつ、PlemolJP_NF35_* (3:5 比率版) は除外。
try {
    $plemolApi = Invoke-RestMethod -Uri "https://api.github.com/repos/yuru7/PlemolJP/releases/latest" -UseBasicParsing
    $asset = $plemolApi.assets | Where-Object { $_.name -match '^PlemolJP_NF[-_]v.+\.zip$' } | Select-Object -First 1
    if ($asset) {
        Install-FontPack `
            -Url $asset.browser_download_url `
            -Name "PlemolJP" `
            -SubdirFilter "PlemolJPConsole_NF"
    } else {
        Write-Host "  PlemolJP_NF asset not found; available assets:" -ForegroundColor Yellow
        $plemolApi.assets | ForEach-Object { Write-Host "    - $($_.name)" -ForegroundColor Yellow }
    }
} catch {
    Write-Host "  PlemolJP fetch failed: $_" -ForegroundColor Yellow
}

# 6. 完了
Step "Done"
Write-Host ""
Write-Host "次の手順:" -ForegroundColor Green
Write-Host "  1. (初回のみ) WSL2 が新規導入された場合は PC 再起動 → スタートメニューから"
Write-Host "     Ubuntu を起動 → Unix ユーザー (etherpoc) とパスワードを設定"
Write-Host "  2. スタートメニューから WezTerm を起動 (以降の通常運用もこれ)"
Write-Host "  3. WezTerm 内で次を実行:"
Write-Host "       curl -fsSL https://raw.githubusercontent.com/etherpoc/dotfiles/main/scripts/install.sh | bash"
Write-Host ""
