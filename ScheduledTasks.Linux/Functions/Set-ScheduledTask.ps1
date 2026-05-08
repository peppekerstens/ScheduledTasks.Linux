function Set-ScheduledTask {
    <#
    .Synopsis
        Not yet implemented on Linux. Delegates to ScheduledTasks\Set-ScheduledTask on Windows.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/ScheduledTasks.Linux
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/set-scheduledtask
    #>
    [CmdletBinding()]
    param()

    if ($IsLinux) {
        Write-Warning "Set-ScheduledTask is not yet implemented in ScheduledTasks.Linux. Use Unregister-ScheduledTask and Register-ScheduledTask to replace a task. Contributions welcome: https://github.com/peppekerstens/ScheduledTasks.Linux"
        return
    }

    ScheduledTasks\Set-ScheduledTask @PSBoundParameters
}
