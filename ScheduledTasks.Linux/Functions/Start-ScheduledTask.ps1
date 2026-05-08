function Start-ScheduledTask {
    <#
    .Synopsis
        Immediately runs a scheduled task on Linux.
    .Description
        Starts the underlying systemd service unit for the task immediately (outside of schedule).
        On Windows, delegates to the built-in ScheduledTasks\Start-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to run.
    .Parameter TaskPath
        The path (folder) of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/start-scheduledtask
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\'
    )

    if (-not $IsLinux) {
        ScheduledTasks\Start-ScheduledTask @PSBoundParameters
        return
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Start-ScheduledTask')) { return }

    $unitName = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'
    $currentUid = & id -u 2>$null
    $isSystem = ($currentUid -eq '0') -and ($TaskPath -eq '\')

    if ($isSystem) {
        & systemctl start "$unitName.service" 2>$null
    } else {
        & systemctl --user start "$unitName.service" 2>$null
    }
}
