function New-ScheduledTaskAction {
    <#
    .Synopsis
        Creates a scheduled task action object.
    .Description
        Creates an in-memory action object describing what a scheduled task executes.
        On Linux, used with Register-ScheduledTask to create systemd service units.
        On Windows, delegates to the built-in ScheduledTasks\New-ScheduledTaskAction cmdlet.
    .Parameter Execute
        The path to the executable or script to run.
    .Parameter Argument
        Arguments to pass to the executable.
    .Parameter WorkingDirectory
        The working directory for the executable.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtaskaction
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Execute,

        [Parameter(Position = 1)]
        [Alias('Arguments')]
        [string]$Argument,

        [Parameter()]
        [string]$WorkingDirectory
    )

    if (-not $IsLinux) {
        ScheduledTasks\New-ScheduledTaskAction @PSBoundParameters
        return
    }

    [PSCustomObject]@{
        PSTypeName       = 'ScheduledTasks.Linux.Action'
        Execute          = $Execute
        Arguments        = $Argument
        WorkingDirectory = $WorkingDirectory
    }
}
