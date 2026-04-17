# ============================================================
# Cursor Config Auto-Sync
# 每次被 Windows 计划任务调用时运行：
# 1. 若有本地改动：add + commit + push
# 2. 若本地无改动但有未推送 commit：补 push
# 3. 全部错误写入 .sync.log，不抛出打断任务
# ============================================================

$ErrorActionPreference = 'Stop'
$repo    = "$env:USERPROFILE\.cursor"
$logFile = Join-Path $repo '.sync.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$ts] [$Level] $Message" | Out-File -Append -Encoding utf8 $logFile
}

function Trim-Log {
    if (-not (Test-Path $logFile)) { return }
    $lines = Get-Content $logFile -Encoding utf8
    if ($lines.Count -gt 1000) {
        $lines[-800..-1] | Set-Content $logFile -Encoding utf8
    }
}

try {
    Set-Location $repo

    $status = git status --porcelain 2>$null
    $hasLocalChanges = [bool]$status

    if ($hasLocalChanges) {
        $fileCount = ($status | Measure-Object).Count
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        git add -A 2>&1 | Out-Null
        git commit -m "auto-sync: $timestamp ($fileCount files)" 2>&1 | Out-Null
        Write-Log "committed $fileCount changed files"
    }

    $unpushed = git log 'origin/main..HEAD' --oneline 2>$null
    if ($unpushed) {
        $pushOutput = git push origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "pushed to origin/main"
        } else {
            Write-Log "push failed: $pushOutput" 'ERROR'
        }
    } elseif (-not $hasLocalChanges) {
        # 什么都没变，静默
    }

    Trim-Log
} catch {
    Write-Log "exception: $_" 'ERROR'
}
