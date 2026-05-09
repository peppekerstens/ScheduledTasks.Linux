function Get-ScheduledTask {
    <#
    .Synopsis
        Gets scheduled tasks on Linux (systemd timers).
    .Description
        Returns scheduled task objects from systemd timer units.
        Covers both system timers (/etc/systemd/system/, /usr/lib/systemd/system/)
        and user timers (~/.config/systemd/user/).
        On Windows, delegates to the built-in ScheduledTasks\Get-ScheduledTask cmdlet.

        Uses `systemctl list-timers --output=json` for efficient enumeration,
        with a single bulk `systemctl show` call for state and description.
    .Parameter TaskName
        The name of the task to retrieve. Wildcards supported.
    .Parameter TaskPath
        The path (folder) of the task. '\' for system tasks, '\User\' for user tasks.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.1.0
        Date: 2026-05-09
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

    # --- Enumerate timers via JSON ---
    $timerJson = systemctl list-timers --all --output=json --no-pager 2>$null
    if (-not $timerJson) { return }

    $timers = $timerJson | ConvertFrom-Json
    if (-not $timers -or $timers.Count -eq 0) { return }

    # --- Enumerate unit file states via JSON (enabled/disabled) ---
    $unitFileJson = systemctl list-unit-files --type=timer --output=json --no-pager 2>$null
    $unitFileHash = @{}
    if ($unitFileJson) {
        ($unitFileJson | ConvertFrom-Json) | ForEach-Object {
            $unitFileHash[$_.unit_file] = $_.state
        }
    }

    # --- Single bulk systemctl show for all timers ---
    $unitNames  = $timers | ForEach-Object { $_.unit }
    $showOutput = systemctl show @unitNames --property=ActiveState,FragmentPath,Description --no-pager 2>$null

    # Parse bulk show output; units are separated by blank lines
    $showHash = @{}
    $current  = @{}
    $idx      = 0
    foreach ($line in $showOutput) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($idx -lt $unitNames.Count) {
                $showHash[$unitNames[$idx]] = $current
                $idx++
                $current = @{}
            }
            continue
        }
        $eq = $line.IndexOf('=')
        if ($eq -gt 0) {
            $current[$line.Substring(0, $eq)] = $line.Substring($eq + 1)
        }
    }
    # Capture last unit (no trailing blank line)
    if ($current.Count -gt 0 -and $idx -lt $unitNames.Count) {
        $showHash[$unitNames[$idx]] = $current
    }

    # --- Build task objects ---
    $tasks = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($timer in $timers) {
        $unitName = $timer.unit
        $props    = if ($showHash.ContainsKey($unitName)) { $showHash[$unitName] } else { @{} }

        $activeState = $props['ActiveState']
        $fragmentPath = $props['FragmentPath']
        $description  = $props['Description']

        # Determine enabled state from unit-file list
        $unitFileState = $unitFileHash[$unitName]

        $state = switch ($activeState) {
            'active'   { 'Ready' }
            'inactive' {
                if ($unitFileState -in @('enabled','enabled-runtime')) { 'Ready' } else { 'Disabled' }
            }
            'failed'   { 'Disabled' }
            default    { 'Unknown' }
        }

        $path = if ($fragmentPath -like '/etc/*' -or $fragmentPath -like '/usr/lib/*' -or $fragmentPath -like '/lib/*') {
            '\'
        } elseif ($fragmentPath -like '/run/*') {
            '\'
        } else {
            '\User\'
        }

        $cleanName = $unitName -replace '\.timer$', ''
        $tasks.Add([PSCustomObject]@{
            PSTypeName  = 'ScheduledTasks.Linux.RegisteredTask'
            TaskName    = $cleanName
            TaskPath    = $path
            State       = $state
            Description = $description
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
