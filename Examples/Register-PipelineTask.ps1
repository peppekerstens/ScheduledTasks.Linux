<#
.Synopsis
    Build a scheduled task from parts using New-ScheduledTask and then register it.
.Description
    Demonstrates the pattern of assembling a task object in memory using New-ScheduledTask,
    then passing it to Register-ScheduledTask via pipeline. Useful when building tasks
    programmatically before registering.
.Notes
    Requires ScheduledTasks.Linux on Linux, or the built-in ScheduledTasks module on Windows.
    Expected output: a ScheduledTask object for 'PSLinuxPipelineTask'.
#>
param(
    [string]$TaskName = 'PSLinuxPipelineTask'
)

if (-not $IsLinux) {
    Import-Module ScheduledTasks -ErrorAction Stop
}

# Remove existing
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Assemble task in memory, then pipe to Register
$task = New-ScheduledTask `
    -Action      (New-ScheduledTaskAction  -Execute '/usr/bin/date') `
    -Trigger     (New-ScheduledTaskTrigger -Daily -At '03:00') `
    -Principal   (New-ScheduledTaskPrincipal -UserId $env:USER) `
    -Settings    (New-ScheduledTaskSettingsSet) `
    -Description 'Demo pipeline task'

Write-Host "Registering '$TaskName' via pipeline..."
$registered = Register-ScheduledTask -TaskName $TaskName -InputObject $task
$registered | Format-List TaskName, State, Description

# Clean up
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Cleaned up."
