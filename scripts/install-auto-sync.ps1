# ============================================================
# 一次性安装：把 auto-sync.ps1 注册为 Windows 计划任务
# 用法：
#   以当前用户身份（不需要管理员）在 PowerShell 里直接跑一次：
#     powershell -NoProfile -ExecutionPolicy Bypass -File
#       "$env:USERPROFILE\.cursor\scripts\install-auto-sync.ps1"
# 卸载：
#     Unregister-ScheduledTask -TaskName "CursorConfigAutoSync" -Confirm:$false
# ============================================================

$taskName    = 'CursorConfigAutoSync'
$scriptPath  = Join-Path $env:USERPROFILE '.cursor\scripts\auto-sync.ps1'
$intervalMin = 15

if (-not (Test-Path $scriptPath)) {
    Write-Error "找不到同步脚本：$scriptPath"
    exit 1
}

# 若已存在同名任务先删
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "已删除旧任务 $taskName，将重新注册"
}

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# 登录时立即开始，然后每 15 分钟跑一次，持续有效
$trigger = New-ScheduledTaskTrigger `
    -AtLogOn

$trigger.Repetition = (New-ScheduledTaskTrigger `
    -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes $intervalMin) `
    -RepetitionDuration ([TimeSpan]::FromDays(3650))).Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "每 $intervalMin 分钟把 %USERPROFILE%\.cursor\ 的改动自动 commit + push 到 GitHub" `
    -RunLevel Limited | Out-Null

Write-Host ""
Write-Host "已注册计划任务：$taskName"
Write-Host "  - 每 $intervalMin 分钟自动同步一次"
Write-Host "  - 开机/登录时立即跑一次"
Write-Host "  - 日志写到 %USERPROFILE%\.cursor\.sync.log"
Write-Host ""
Write-Host "可以手动触发一次测试："
Write-Host "  Start-ScheduledTask -TaskName $taskName"
Write-Host ""
Write-Host "查看最近日志："
Write-Host "  Get-Content `"`$env:USERPROFILE\.cursor\.sync.log`" -Tail 20"
Write-Host ""
Write-Host "卸载："
Write-Host "  Unregister-ScheduledTask -TaskName $taskName -Confirm:`$false"
