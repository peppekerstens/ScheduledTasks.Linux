function Get-ScheduledTask {
    <#
    .Synopsis
        Gets scheduled tasks on Linux (systemd timers).
    .Description
        Returns scheduled task objects from systemd timer units.
        Covers both system timers (/etc/systemd/system/) and user timers (~/.config/systemd/user/).
        On Windows, delegates to the built-in ScheduledTasks\Get-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to retrieve. Wildcards supported.
    .Parameter TaskPath
        The path (folder) of the task. '\' for system tasks.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/get-scheduledtask
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
        ScheduledTasks\Get-ScheduledTask @PSBoundParameters
        return
    }

    # Gather all timer units from systemd
    $rawLines = systemctl list-timers --all --no-pager --no-legend --plain 2>$null
    $tasks    = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($line in $rawLines) {
        # Format: NEXT LEFT LAST PASSED UNIT ACTIVATES
        $parts = $line -split '\s+', 7
        if ($parts.Count -lt 5) { continue }

        # Find the UNIT column — it ends in .timer
        $unitIndex = $parts | ForEach-Object { $_ } | Where-Object { $_ -like '*.timer' } | Select-Object -First 1
        if (-not $unitIndex) { continue }
        $unitName = $unitIndex -replace '\.timer$', ''

        # Get detailed info via systemctl show
        $showOutput = systemctl show "$unitName.timer" --no-pager 2>$null
        $props = @{}
        foreach ($kv in $showOutput) {
            $eq = $kv.IndexOf('=')
            if ($eq -gt 0) {
                $props[$kv.Substring(0, $eq)] = $kv.Substring($eq + 1)
            }
        }

        $state = switch ($props['ActiveState']) {
            'active'   { 'Ready' }
            'inactive' { 'Disabled' }
            'failed'   { 'Disabled' }
            default    { 'Unknown' }
        }

        $path = if ($props['FragmentPath'] -like '/etc/*') { '\' } else { '\User\' }

        $tasks.Add([PSCustomObject]@{
            PSTypeName  = 'ScheduledTasks.Linux.RegisteredTask'
            TaskName    = $unitName
            TaskPath    = $path
            State       = $state
            Description = $props['Description']
            Actions     = @()
            Triggers    = @()
            Principal   = $null
            Settings    = $null
        })
    }

    $results = $tasks

    # Filter by TaskName
    if ($PSBoundParameters.ContainsKey('TaskName') -and $TaskName) {
        $results = $results | Where-Object {
            $n = $_.TaskName
            $TaskName | Where-Object { $n -like $_ }
        }
    }

    # Filter by TaskPath
    if ($PSBoundParameters.ContainsKey('TaskPath') -and $TaskPath) {
        $results = $results | Where-Object { $_.TaskPath -like $TaskPath }
    }

    $results
}
