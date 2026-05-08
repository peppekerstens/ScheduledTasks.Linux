function New-ScheduledTask {
    <#
    .Synopsis
        Creates a scheduled task definition object (in memory).
    .Description
        Creates an in-memory scheduled task object combining action, trigger, principal and settings.
        Pass the result to Register-ScheduledTask to write it to disk as a systemd unit.
        On Windows, delegates to the built-in ScheduledTasks\New-ScheduledTask cmdlet.
    .Parameter Action
        One or more task actions created with New-ScheduledTaskAction.
    .Parameter Trigger
        One or more triggers created with New-ScheduledTaskTrigger.
    .Parameter Principal
        A principal created with New-ScheduledTaskPrincipal.
    .Parameter Settings
        Settings created with New-ScheduledTaskSettingsSet.
    .Parameter Description
        A human-readable description of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtask
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [PSCustomObject[]]$Action,

        [Parameter()]
        [PSCustomObject[]]$Trigger,

        [Parameter()]
        [PSCustomObject]$Principal,

        [Parameter()]
        [PSCustomObject]$Settings,

        [Parameter()]
        [string]$Description
    )

    if (-not $IsLinux) {
        ScheduledTasks\New-ScheduledTask @PSBoundParameters
        return
    }

    [PSCustomObject]@{
        PSTypeName  = 'ScheduledTasks.Linux.Task'
        Actions     = $Action
        Triggers    = $Trigger
        Principal   = $Principal
        Settings    = $Settings
        Description = $Description
    }
}
