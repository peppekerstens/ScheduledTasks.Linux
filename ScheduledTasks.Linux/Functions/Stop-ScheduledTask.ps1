function Stop-ScheduledTask {
    <#
    .Synopsis
        Stops a running scheduled task on Linux.
    .Description
        Stops the underlying systemd service unit for the task if it is currently running.
        On Windows, delegates to the built-in ScheduledTasks\Stop-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to stop.
    .Parameter TaskPath
        The path (folder) of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/stop-scheduledtask
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\'
    )

    if (-not $IsLinux) {
        ScheduledTasks\Stop-ScheduledTask @PSBoundParameters
        return
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Stop-ScheduledTask')) { return }

    $unitName = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'
    $currentUid = & id -u 2>$null
    $isSystem = ($currentUid -eq '0') -and ($TaskPath -eq '\')

    if ($isSystem) {
        & systemctl stop "$unitName.service" 2>$null
    } else {
        & systemctl --user stop "$unitName.service" 2>$null
    }
}
