function New-ScheduledTaskTrigger {
    <#
    .Synopsis
        Creates a scheduled task trigger object.
    .Description
        Creates an in-memory trigger object describing when a scheduled task runs.
        On Linux, used with Register-ScheduledTask to set the systemd timer OnCalendar or OnBootSec value.
        On Windows, delegates to the built-in ScheduledTasks\New-ScheduledTaskTrigger cmdlet.
    .Parameter Once
        Creates a one-time trigger. Requires -At.
    .Parameter Daily
        Creates a daily trigger. Requires -At.
    .Parameter Weekly
        Creates a weekly trigger. Requires -At and -DaysOfWeek.
    .Parameter AtStartup
        Creates a trigger that fires at system startup.
    .Parameter AtLogOn
        Creates a trigger that fires at user logon.
    .Parameter At
        The time at which the trigger fires (for Once/Daily/Weekly).
    .Parameter DaysOfWeek
        Days on which the trigger fires (for Weekly).
    .Parameter RandomDelay
        Random delay added to the trigger time.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtasktrigger
    #>
    [CmdletBinding(DefaultParameterSetName = 'Once')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'Once', Mandatory)]
        [switch]$Once,

        [Parameter(ParameterSetName = 'Daily', Mandatory)]
        [switch]$Daily,

        [Parameter(ParameterSetName = 'Weekly', Mandatory)]
        [switch]$Weekly,

        [Parameter(ParameterSetName = 'AtStartup', Mandatory)]
        [switch]$AtStartup,

        [Parameter(ParameterSetName = 'AtLogOn', Mandatory)]
        [switch]$AtLogOn,

        [Parameter(ParameterSetName = 'Once', Mandatory)]
        [Parameter(ParameterSetName = 'Daily', Mandatory)]
        [Parameter(ParameterSetName = 'Weekly', Mandatory)]
        [datetime]$At,

        [Parameter(ParameterSetName = 'Weekly', Mandatory)]
        [DayOfWeek[]]$DaysOfWeek,

        [Parameter()]
        [timespan]$RandomDelay
    )

    if (-not $IsLinux) {
        ScheduledTasks\New-ScheduledTaskTrigger @PSBoundParameters
        return
    }

    $triggerType = $PSCmdlet.ParameterSetName

    # Build a systemd OnCalendar expression from the trigger parameters
    $onCalendar = switch ($triggerType) {
        'Once'      {
            $at.ToString('yyyy-MM-dd HH:mm:ss')
        }
        'Daily'     {
            '*-*-* {0}:{1}:00' -f $at.Hour.ToString('D2'), $at.Minute.ToString('D2')
        }
        'Weekly'    {
            $dayNames = $DaysOfWeek | ForEach-Object { $_.ToString().Substring(0,3) }
            '{0} {1}:{2}:00' -f ($dayNames -join ','), $at.Hour.ToString('D2'), $at.Minute.ToString('D2')
        }
        'AtStartup' { 'boot' }
        'AtLogOn'   { 'boot' }   # closest systemd equivalent
    }

    [PSCustomObject]@{
        PSTypeName   = 'ScheduledTasks.Linux.Trigger'
        TriggerType  = $triggerType
        At           = if ($PSBoundParameters.ContainsKey('At')) { $At } else { $null }
        DaysOfWeek   = if ($PSBoundParameters.ContainsKey('DaysOfWeek')) { $DaysOfWeek } else { @() }
        RandomDelay  = if ($PSBoundParameters.ContainsKey('RandomDelay')) { $RandomDelay } else { [timespan]::Zero }
        OnCalendar   = $onCalendar
    }
}
