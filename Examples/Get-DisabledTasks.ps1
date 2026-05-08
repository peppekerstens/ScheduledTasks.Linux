<#
.Synopsis
    Show only disabled (inactive) scheduled tasks.
.Description
    Filters the output of Get-ScheduledTask to show only tasks in a Disabled state.
    Useful for auditing which tasks are present but not active.
.Notes
    Requires ScheduledTasks.Linux on Linux, or the built-in ScheduledTasks module on Windows.
    Expected output: a table of disabled tasks (may be empty if all tasks are enabled).
#>
param()

if (-not $IsLinux) {
    Import-Module ScheduledTasks -ErrorAction Stop
}

$disabled = Get-ScheduledTask | Where-Object { $_.State -eq 'Disabled' }

if ($disabled) {
    Write-Host "Disabled tasks ($($disabled.Count) found):" -ForegroundColor Yellow
    $disabled | Format-Table TaskName, TaskPath, Description -AutoSize
} else {
    Write-Host "No disabled tasks found." -ForegroundColor Green
}
