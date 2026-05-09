function Export-ScheduledTask {
    <#
    .SYNOPSIS
        Exports a scheduled task (systemd timer) as its unit file content. On Linux, uses 'systemctl cat'.
    .DESCRIPTION
        Returns the unit file content for a systemd timer or service as a string.
        The output is the raw INI-format systemd unit file, analogous to the XML
        that Windows Export-ScheduledTask produces.

        On Windows, delegates to ScheduledTasks\Export-ScheduledTask.
    .PARAMETER TaskName
        The name of the timer unit (without the .timer suffix).
    .PARAMETER TaskPath
        Ignored on Linux (systemd has no folder hierarchy). Emits a warning if specified.
    .LINK
        https://learn.microsoft.com/powershell/module/scheduledtasks/export-scheduledtask
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath
    )
    process {
        if ($IsLinux) {
            if ($TaskPath) {
                Write-Warning 'Export-ScheduledTask: -TaskPath is not supported on Linux (systemd has no folder hierarchy).'
            }

            # Try .timer first, fall back to .service
            $unitName = if ($TaskName -match '\.(timer|service)$') { $TaskName } else { "$TaskName.timer" }
            $output = & systemctl cat $unitName 2>&1
            if ($LASTEXITCODE -ne 0) {
                # Try as .service
                $unitName = "$TaskName.service"
                $output = & systemctl cat $unitName 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Export-ScheduledTask: unit '$TaskName' not found."
                    return
                }
            }
            $output -join "`n"
        } else {
            ScheduledTasks\Export-ScheduledTask @PSBoundParameters
        }
    }
}
