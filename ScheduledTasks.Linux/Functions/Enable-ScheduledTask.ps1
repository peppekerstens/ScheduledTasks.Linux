function Enable-ScheduledTask {
    <#
    .Synopsis
        Enables a scheduled task on Linux.
    .Description
        Enables the systemd timer unit for the task so it starts automatically.
        On Windows, delegates to the built-in ScheduledTasks\Enable-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to enable. Wildcards supported.
    .Parameter TaskPath
        The path (folder) of the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/enable-scheduledtask
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\'
    )

    process {
    if (-not $IsLinux) {
        ScheduledTasks\Enable-ScheduledTask @PSBoundParameters
        return
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Enable-ScheduledTask')) { return }

    $unitName = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'
    $currentUid = & id -u 2>$null
    $isSystem = ($currentUid -eq '0') -and ($TaskPath -eq '\')

    if ($isSystem) {
        & systemctl enable "$unitName.timer" 2>$null
        & systemctl start  "$unitName.timer" 2>$null
    } else {
        & systemctl --user enable "$unitName.timer" 2>$null
        & systemctl --user start  "$unitName.timer" 2>$null
    }

    Get-ScheduledTask -TaskName $TaskName
    } # end process
}
