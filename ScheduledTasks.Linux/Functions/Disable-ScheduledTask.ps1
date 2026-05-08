function Disable-ScheduledTask {
    <#
    .Synopsis
        Disables a scheduled task on Linux.
    .Description
        Disables the systemd timer unit for the task so it no longer starts automatically.
        On Windows, delegates to the built-in ScheduledTasks\Disable-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to disable. Wildcards supported.
    .Parameter TaskPath
        The path (folder) of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/disable-scheduledtask
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\'
    )

    if (-not $IsLinux) {
        ScheduledTasks\Disable-ScheduledTask @PSBoundParameters
        return
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Disable-ScheduledTask')) { return }

    $unitName = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'
    $currentUid = & id -u 2>$null
    $isSystem = ($currentUid -eq '0') -and ($TaskPath -eq '\')

    if ($isSystem) {
        & systemctl stop    "$unitName.timer" 2>$null
        & systemctl disable "$unitName.timer" 2>$null
    } else {
        & systemctl --user stop    "$unitName.timer" 2>$null
        & systemctl --user disable "$unitName.timer" 2>$null
    }

    Get-ScheduledTask -TaskName $TaskName
}
