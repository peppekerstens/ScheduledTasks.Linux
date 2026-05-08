<#
.Synopsis
    List all systemd timer-based scheduled tasks with their next run time.
.Description
    Uses Get-ScheduledTask and Get-ScheduledTaskInfo to display a summary of all
    scheduled tasks on a Linux system, showing name, state and timing.
.Notes
    Requires ScheduledTasks.Linux on Linux, or the built-in ScheduledTasks module on Windows.
    Expected output shape:
        TaskName         State    NextRunTime
        --------         -----    -----------
        apt-daily        Ready    05/09/2026 01:00:00
        logrotate        Ready    05/09/2026 00:00:00
#>
param()

# On Windows, load the built-in module
if (-not $IsLinux) {
    Import-Module ScheduledTasks -ErrorAction Stop
}

$tasks = Get-ScheduledTask

$results = foreach ($task in $tasks) {
    try {
        $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
    } catch {
        $info = $null
    }

    [PSCustomObject]@{
        TaskName    = $task.TaskName
        TaskPath    = $task.TaskPath
        State       = $task.State
        Description = $task.Description
        NextRunTime = if ($info) { $info.NextRunTime } else { $null }
        LastRunTime = if ($info) { $info.LastRunTime } else { $null }
    }
}

$results | Sort-Object TaskName | Format-Table -AutoSize
