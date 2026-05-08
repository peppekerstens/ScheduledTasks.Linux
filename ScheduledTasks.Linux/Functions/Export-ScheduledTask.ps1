function Export-ScheduledTask {
    <#
    .Synopsis
        Not yet implemented on Linux. Delegates to ScheduledTasks\Export-ScheduledTask on Windows.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/ScheduledTasks.Linux
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/export-scheduledtask
    #>
    [CmdletBinding()]
    param()

    if ($IsLinux) {
        Write-Warning "Export-ScheduledTask is not yet implemented in ScheduledTasks.Linux. Contributions welcome: https://github.com/peppekerstens/ScheduledTasks.Linux"
        return
    }

    ScheduledTasks\Export-ScheduledTask @PSBoundParameters
}
