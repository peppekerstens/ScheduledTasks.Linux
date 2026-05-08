function Register-ScheduledTask {
    <#
    .Synopsis
        Registers a scheduled task on Linux using systemd timer units.
    .Description
        Creates a systemd .service and .timer unit file pair from a scheduled task definition.
        System-wide tasks (TaskPath = '\' or root user) go to /etc/systemd/system/.
        User tasks go to ~/.config/systemd/user/.
        On Windows, delegates to the built-in ScheduledTasks\Register-ScheduledTask cmdlet.
    .Parameter TaskName
        The name of the scheduled task. Used as the systemd unit name.
    .Parameter TaskPath
        The path (folder) for the task. '\' means system-wide. Default: '\'.
    .Parameter InputObject
        A task definition created with New-ScheduledTask.
    .Parameter Action
        One or more task actions created with New-ScheduledTaskAction.
    .Parameter Trigger
        One or more triggers created with New-ScheduledTaskTrigger.
    .Parameter Principal
        A principal created with New-ScheduledTaskPrincipal.
    .Parameter Settings
        Settings created with New-ScheduledTaskSettingsSet.
    .Parameter Description
        A description for the task.
    .Parameter Force
        Overwrite an existing task with the same name.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/register-scheduledtask
    #>
    [CmdletBinding(DefaultParameterSetName = 'Components', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$TaskName,

        [Parameter()]
        [string]$TaskPath = '\',

        [Parameter(ParameterSetName = 'InputObject', ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Components')]
        [PSCustomObject[]]$Action,

        [Parameter(ParameterSetName = 'Components')]
        [PSCustomObject[]]$Trigger,

        [Parameter(ParameterSetName = 'Components')]
        [PSCustomObject]$Principal,

        [Parameter(ParameterSetName = 'Components')]
        [PSCustomObject]$Settings,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [switch]$Force
    )

    process {
    if (-not $IsLinux) {
        ScheduledTasks\Register-ScheduledTask @PSBoundParameters
        return
    }

    # Resolve the task definition
    if ($PSCmdlet.ParameterSetName -eq 'InputObject' -and $InputObject) {
        $taskAction    = $InputObject.Actions
        $taskTrigger   = $InputObject.Triggers
        $taskPrincipal = $InputObject.Principal
        $taskSettings  = $InputObject.Settings
        $taskDesc      = if ($Description) { $Description } else { $InputObject.Description }
    } else {
        $taskAction    = $Action
        $taskTrigger   = $Trigger
        $taskPrincipal = $Principal
        $taskSettings  = $Settings
        $taskDesc      = $Description
    }

    if (-not $taskAction -or $taskAction.Count -eq 0) {
        throw "Register-ScheduledTask: At least one Action is required."
    }

    # Determine unit directory (system vs user)
    # Run as root → system (/etc/systemd/system/).
    # Run as non-root or principal is not root → user (~/.config/systemd/user/).
    $currentUid = & id -u 2>$null
    $isRoot = ($currentUid -eq '0')
    $isSystem = $isRoot -and (
        ($TaskPath -eq '\') -or
        ($taskPrincipal -and $taskPrincipal.RunLevel -eq 'Highest') -or
        ($taskPrincipal -and $taskPrincipal.UserId -eq 'root')
    )
    if ($isSystem) {
        $unitDir = '/etc/systemd/system'
    } else {
        $unitDir = "$env:HOME/.config/systemd/user"
    }

    $unitName    = $TaskName -replace '[^a-zA-Z0-9_\-]', '-'
    $servicePath = "$unitDir/$unitName.service"
    $timerPath   = "$unitDir/$unitName.timer"

    if (-not $Force -and ((Test-Path $servicePath) -or (Test-Path $timerPath))) {
        throw "Register-ScheduledTask: A task named '$TaskName' already exists. Use -Force to overwrite."
    }

    if (-not $PSCmdlet.ShouldProcess($TaskName, 'Register-ScheduledTask')) { return }

    # Create unit dir if needed
    if (-not (Test-Path $unitDir)) {
        New-Item -ItemType Directory -Path $unitDir -Force | Out-Null
    }

    # Build ExecStart from first action (multiple actions not supported in single service unit)
    $firstAction = $taskAction[0]
    $execStart = $firstAction.Execute
    if ($firstAction.Arguments) { $execStart += " $($firstAction.Arguments)" }
    $workingDir = if ($firstAction.WorkingDirectory) { "WorkingDirectory=$($firstAction.WorkingDirectory)" } else { '' }

    # Build User directive
    $userLine = ''
    if ($taskPrincipal -and $taskPrincipal.UserId -and $taskPrincipal.UserId -ne 'root') {
        $userLine = "User=$($taskPrincipal.UserId)"
    }

    # Build Restart directives from settings
    $restartLines = ''
    if ($taskSettings -and $taskSettings.RestartCount -gt 0) {
        $restartLines = "Restart=on-failure`nRestartSec=$([int]$taskSettings.RestartInterval.TotalSeconds)"
    }

    # Build .service unit content
    $serviceContent = @"
[Unit]
Description=$taskDesc
$(if ($isSystem) { 'After=network.target' } else { '' })

[Service]
Type=oneshot
ExecStart=$execStart
$workingDir
$userLine
$restartLines

[Install]
WantedBy=multi-user.target
"@

    # Build OnCalendar expression from first trigger
    $onCalendar = 'daily'
    $onBootSec  = ''
    if ($taskTrigger -and $taskTrigger.Count -gt 0) {
        $t = $taskTrigger[0]
        if ($t.PSObject.Properties['OnCalendar'] -and $t.OnCalendar) {
            if ($t.OnCalendar -eq 'boot') {
                $onBootSec  = 'OnBootSec=1min'
                $onCalendar = ''
            } else {
                $onCalendar = $t.OnCalendar
            }
        }
    }

    # Build .timer unit content
    $timerContent = @"
[Unit]
Description=Timer for $taskDesc

[Timer]
$(if ($onCalendar) { "OnCalendar=$onCalendar" } else { $onBootSec })
Persistent=true

[Install]
WantedBy=timers.target
"@

    [System.IO.File]::WriteAllText($servicePath, $serviceContent)
    [System.IO.File]::WriteAllText($timerPath, $timerContent)

    # Reload systemd and enable/start timer
    if ($isSystem) {
        & systemctl daemon-reload 2>$null
        if (-not $taskSettings -or $taskSettings.Enabled -ne $false) {
            & systemctl enable "$unitName.timer" 2>$null
        }
    } else {
        & systemctl --user daemon-reload 2>$null
        if (-not $taskSettings -or $taskSettings.Enabled -ne $false) {
            & systemctl --user enable "$unitName.timer" 2>$null
        }
    }

    # Return a task object
    Get-ScheduledTask -TaskName $TaskName
    } # end process
}
