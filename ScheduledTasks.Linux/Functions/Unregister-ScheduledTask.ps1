function Unregister-ScheduledTask {
    <#
    .Synopsis
        Deletes a scheduled task on Linux.
    .Description
        Disables and removes the systemd .service and .timer unit files for the task.
        On Windows, delegates to the built-in ScheduledTasks\Unregister-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the task to delete.
    .Parameter TaskPath
        The path (folder) of the task.
    .Parameter Confirm
        Prompts for confirmation before removing the task.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/unregister-scheduledtask
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\'
    )

    process {
    if (-not $IsLinux) {
        ScheduledTasks\Unregister-ScheduledTask @PSBoundParameters
        return
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Unregister-ScheduledTask')) { return }
    $unitName = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'

    # Determine unit directories to search
    $searchDirs = @('/etc/systemd/system', "$env:HOME/.config/systemd/user")

    foreach ($dir in $searchDirs) {
        $servicePath = "$dir/$unitName.service"
        $timerPath   = "$dir/$unitName.timer"
        $isSystem    = $dir -like '/etc/*'

        if (Test-Path $timerPath) {
            if ($isSystem) {
                & systemctl disable --now "$unitName.timer" 2>$null
                & systemctl daemon-reload 2>$null
            } else {
                & systemctl --user disable --now "$unitName.timer" 2>$null
                & systemctl --user daemon-reload 2>$null
            }
            Remove-Item -Path $timerPath -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $servicePath) {
            Remove-Item -Path $servicePath -Force -ErrorAction SilentlyContinue
        }
    }
    } # end process
}
