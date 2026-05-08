<#
.Synopsis
    Register a new scheduled task that runs a script on a daily schedule.
.Description
    Demonstrates the full workflow for creating a scheduled task:
    New-ScheduledTaskAction + New-ScheduledTaskTrigger + Register-ScheduledTask.
    The task runs /usr/bin/echo every day at 06:00 as the current user.
.Notes
    Requires ScheduledTasks.Linux on Linux, or the built-in ScheduledTasks module on Windows.
    Expected output: a ScheduledTask object for 'PSLinuxDemoTask'.
#>
param(
    [string]$TaskName = 'PSLinuxDemoTask'
)

if (-not $IsLinux) {
    Import-Module ScheduledTasks -ErrorAction Stop
}

# Remove existing task if present
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing task '$TaskName'..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Build the task components
$action  = New-ScheduledTaskAction -Execute '/usr/bin/echo' -Argument "Hello from $TaskName"
$trigger = New-ScheduledTaskTrigger -Daily -At '06:00'
$settings = New-ScheduledTaskSettingsSet

Write-Host "Registering task '$TaskName'..."
$task = Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Description 'Demo task registered by ScheduledTasks.Linux'

$task | Format-List TaskName, State, Description

# Clean up
Write-Host "Removing demo task..."
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Done."
