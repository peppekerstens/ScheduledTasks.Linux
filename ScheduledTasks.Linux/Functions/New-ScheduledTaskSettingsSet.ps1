function New-ScheduledTaskSettingsSet {
    <#
    .Synopsis
        Creates a scheduled task settings object.
    .Description
        Creates an in-memory settings object for a scheduled task.
        On Linux, relevant settings are applied to the systemd unit file during Register-ScheduledTask.
        On Windows, delegates to the built-in ScheduledTasks\New-ScheduledTaskSettingsSet cmdlet.
    .Parameter Disable
        Creates the task in a disabled state.
    .Parameter Hidden
        Marks the task as hidden (informational on Linux).
    .Parameter RestartCount
        Number of retries on failure. Maps to systemd Restart= directive.
    .Parameter RestartInterval
        Interval between retries. Maps to systemd RestartSec= directive.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtasksettingsset
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$Disable,

        [Parameter()]
        [switch]$Hidden,

        [Parameter()]
        [int]$RestartCount = 0,

        [Parameter()]
        [timespan]$RestartInterval = [timespan]::Zero
    )

    if (-not $IsLinux) {
        ScheduledTasks\New-ScheduledTaskSettingsSet @PSBoundParameters
        return
    }

    [PSCustomObject]@{
        PSTypeName      = 'ScheduledTasks.Linux.Settings'
        Enabled         = -not $Disable.IsPresent
        Hidden          = $Hidden.IsPresent
        RestartCount    = $RestartCount
        RestartInterval = $RestartInterval
    }
}
