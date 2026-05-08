function Get-ScheduledTaskInfo {
    <#
    .Synopsis
        Gets run history and next run time for a scheduled task on Linux.
    .Description
        Returns timing information for a systemd timer (last run, next run, number of missed runs).
        On Windows, delegates to the built-in ScheduledTasks\Get-ScheduledTaskInfo cmdlet.
    .Parameter TaskName
        The name of the task. Wildcards supported.
    .Parameter TaskPath
        The path (folder) of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/get-scheduledtaskinfo
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string[]]$TaskName,

        [Parameter()]
        [string]$TaskPath
    )

    if (-not $IsLinux) {
        ScheduledTasks\Get-ScheduledTaskInfo @PSBoundParameters
        return
    }

    # Get the tasks first to resolve names/paths
    $getTasks = @{}
    if ($PSBoundParameters.ContainsKey('TaskName')) { $getTasks['TaskName'] = $TaskName }
    if ($PSBoundParameters.ContainsKey('TaskPath')) { $getTasks['TaskPath'] = $TaskPath }
    $tasks = Get-ScheduledTask @getTasks

    foreach ($task in $tasks) {
        $unitName = $task.TaskName
        $showOutput = systemctl show "$unitName.timer" --no-pager 2>$null
        $props = @{}
        foreach ($kv in $showOutput) {
            $eq = $kv.IndexOf('=')
            if ($eq -gt 0) {
                $props[$kv.Substring(0, $eq)] = $kv.Substring($eq + 1)
            }
        }

        # Parse last trigger time
        $lastRun = $null
        if ($props['LastTriggerUSec'] -and $props['LastTriggerUSec'] -ne 'n/a' -and $props['LastTriggerUSec'] -ne '0') {
            try {
                $usec = [long]$props['LastTriggerUSec']
                $lastRun = [datetime]::UnixEpoch.AddMicroseconds($usec).ToLocalTime()
            } catch { Write-Debug $_.Exception.Message }
        }

        # Parse next elapse time
        $nextRun = $null
        if ($props['NextElapseUSecRealtime'] -and $props['NextElapseUSecRealtime'] -ne 'n/a' -and $props['NextElapseUSecRealtime'] -ne '0') {
            try {
                $usec = [long]$props['NextElapseUSecRealtime']
                $nextRun = [datetime]::UnixEpoch.AddMicroseconds($usec).ToLocalTime()
            } catch { Write-Debug $_.Exception.Message }
        }

        [PSCustomObject]@{
            PSTypeName         = 'ScheduledTasks.Linux.TaskInfo'
            TaskName           = $unitName
            TaskPath           = $task.TaskPath
            LastRunTime        = $lastRun
            LastTaskResult     = 0
            NextRunTime        = $nextRun
            NumberOfMissedRuns = 0
        }
    }
}
