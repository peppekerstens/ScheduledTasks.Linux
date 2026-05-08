function New-ScheduledTaskPrincipal {
    <#
    .Synopsis
        Creates a scheduled task principal object.
    .Description
        Creates an in-memory principal object describing under which user a scheduled task runs.
        On Linux, used with Register-ScheduledTask to set the systemd unit User= directive.
        On Windows, delegates to the built-in ScheduledTasks\New-ScheduledTaskPrincipal cmdlet.
    .Parameter UserId
        The user account under which the task runs.
    .Parameter RunLevel
        The required privilege level (Limited or Highest). Highest maps to root on Linux.
    .Parameter Id
        An identifier for the principal (informational).
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtaskprincipal
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$UserId = $env:USER,

        [Parameter(Position = 1)]
        [ValidateSet('Limited', 'Highest')]
        [string]$RunLevel = 'Limited',

        [Parameter()]
        [string]$Id = 'Author'
    )

    if (-not $IsLinux) {
        ScheduledTasks\New-ScheduledTaskPrincipal @PSBoundParameters
        return
    }

    [PSCustomObject]@{
        PSTypeName = 'ScheduledTasks.Linux.Principal'
        Id         = $Id
        UserId     = $UserId
        RunLevel   = $RunLevel
    }
}
