#Requires -Version 7.2

# ScheduledTasks.Linux.psm1
# Root module for ScheduledTasks.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

# Linux-only guard — this module wraps Linux systemd timer units and must not be loaded on Windows.
# On Windows, use the built-in module:
#   Import-Module ScheduledTasks
if (-not $IsLinux) {
    throw (
        "ScheduledTasks.Linux cannot be loaded on Windows. " +
        "On Windows, use the built-in 'ScheduledTasks' module.`n" +
        "ScheduledTasks.Linux is a Linux-only peer module that wraps systemd timer units."
    )
}

$functionPath = Join-Path $PSScriptRoot 'Functions'
$functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }
foreach ($file in $functionFiles) {
    . $file.FullName
}
