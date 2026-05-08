#
# Module manifest for module 'ScheduledTasks.Linux'
#

@{
    RootModule        = 'ScheduledTasks.Linux.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd4e5f6a7-b8c9-1023-defa-234567890123'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with the Windows ScheduledTasks module. Implements Get-ScheduledTask, Get-ScheduledTaskInfo, New-ScheduledTask, New-ScheduledTaskAction, New-ScheduledTaskTrigger, New-ScheduledTaskPrincipal, New-ScheduledTaskSettingsSet, Register-ScheduledTask, Unregister-ScheduledTask, Enable-ScheduledTask, Disable-ScheduledTask, Start-ScheduledTask, Stop-ScheduledTask using systemd timer units.'
    PowerShellVersion = '7.2'
    RequiredModules   = @()

    FunctionsToExport = @(
        # Fully implemented
        'New-ScheduledTaskAction',
        'New-ScheduledTaskTrigger',
        'New-ScheduledTaskPrincipal',
        'New-ScheduledTaskSettingsSet',
        'New-ScheduledTask',
        'Register-ScheduledTask',
        'Get-ScheduledTask',
        'Get-ScheduledTaskInfo',
        'Start-ScheduledTask',
        'Stop-ScheduledTask',
        'Enable-ScheduledTask',
        'Disable-ScheduledTask',
        'Unregister-ScheduledTask',
        # Stubs
        'Set-ScheduledTask',
        'Export-ScheduledTask'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Linux', 'ScheduledTask', 'systemd', 'timer', 'cron', 'CrossPlatform', 'Automation')
            LicenseUri   = 'https://github.com/peppekerstens/ScheduledTasks.Linux/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/peppekerstens/ScheduledTasks.Linux'
            ReleaseNotes = @'
0.1.0 - Initial release. New-ScheduledTask*, Register-ScheduledTask, Get-ScheduledTask, Get-ScheduledTaskInfo, Start/Stop/Enable/Disable/Unregister-ScheduledTask implemented via systemd timer units. Set-ScheduledTask and Export-ScheduledTask are stubs.
'@
        }
    }
}
