#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeDiscovery {
    $script:implementedCmdlets = @(
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
        'Unregister-ScheduledTask'
    )
    $script:stubCmdlets = @(
        'Set-ScheduledTask',
        'Export-ScheduledTask'
    )
    $script:allCmdlets = $script:implementedCmdlets + $script:stubCmdlets
}

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot 'ScheduledTasks.Linux.psd1'
    if ($IsLinux) {
        Import-Module $modulePath -Force
    }
}

AfterAll {
    if ($IsLinux) {
        Remove-Module ScheduledTasks.Linux -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Module surface' -Skip:(-not $IsLinux) {
    It 'exports exactly <_> functions' -ForEach @(15) {
        (Get-Command -Module ScheduledTasks.Linux | Where-Object CommandType -eq Function | Measure-Object).Count | Should -Be $_
    }

    It 'exports function <_>' -ForEach $script:allCmdlets {
        Get-Command -Module ScheduledTasks.Linux -Name $_ | Should -Not -BeNullOrEmpty
    }
}

Describe 'New-ScheduledTaskAction' -Skip:(-not $IsLinux) {
    It 'returns an object with Execute property' {
        $action = New-ScheduledTaskAction -Execute '/usr/bin/echo' -Argument 'hello'
        $action.Execute   | Should -Be '/usr/bin/echo'
        $action.Arguments | Should -Be 'hello'
    }

    It 'returns an object with PSTypeName set' {
        $action = New-ScheduledTaskAction -Execute '/bin/true'
        $action.PSObject.TypeNames | Should -Contain 'ScheduledTasks.Linux.Action'
    }
}

Describe 'New-ScheduledTaskTrigger' -Skip:(-not $IsLinux) {
    It 'creates a Daily trigger with OnCalendar set' {
        $at = [datetime]'2026-01-01 08:00:00'
        $trigger = New-ScheduledTaskTrigger -Daily -At $at
        $trigger.TriggerType | Should -Be 'Daily'
        $trigger.OnCalendar  | Should -Match '\d{2}:\d{2}:00'
    }

    It 'creates an AtStartup trigger with OnCalendar = boot' {
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $trigger.TriggerType | Should -Be 'AtStartup'
        $trigger.OnCalendar  | Should -Be 'boot'
    }

    It 'creates a Once trigger with correct date in OnCalendar' {
        $at = [datetime]'2026-06-15 14:30:00'
        $trigger = New-ScheduledTaskTrigger -Once -At $at
        $trigger.OnCalendar | Should -Match '2026-06-15'
    }
}

Describe 'New-ScheduledTaskPrincipal' -Skip:(-not $IsLinux) {
    It 'returns an object with UserId' {
        $principal = New-ScheduledTaskPrincipal -UserId 'testuser'
        $principal.UserId   | Should -Be 'testuser'
        $principal.RunLevel | Should -Be 'Limited'
    }
}

Describe 'New-ScheduledTaskSettingsSet' -Skip:(-not $IsLinux) {
    It 'returns an object with Enabled = true by default' {
        $settings = New-ScheduledTaskSettingsSet
        $settings.Enabled | Should -Be $true
    }

    It 'returns Enabled = false when -Disable is set' {
        $settings = New-ScheduledTaskSettingsSet -Disable
        $settings.Enabled | Should -Be $false
    }
}

Describe 'New-ScheduledTask' -Skip:(-not $IsLinux) {
    It 'combines action and trigger into a task object' {
        $action  = New-ScheduledTaskAction -Execute '/bin/true'
        $trigger = New-ScheduledTaskTrigger -Daily -At '08:00'
        $task    = New-ScheduledTask -Action $action -Trigger $trigger -Description 'Test task'
        $task.Actions[0].Execute | Should -Be '/bin/true'
        $task.Description        | Should -Be 'Test task'
    }
}

Describe 'Get-ScheduledTask' -Skip:(-not $IsLinux) {
    It 'returns objects without throwing' {
        { Get-ScheduledTask } | Should -Not -Throw
    }

    It 'returns objects with TaskName and State properties' {
        $tasks = Get-ScheduledTask
        if ($tasks) {
            $tasks[0].TaskName | Should -Not -BeNullOrEmpty
            $tasks[0].State    | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Get-ScheduledTaskInfo' -Skip:(-not $IsLinux) {
    It 'returns objects without throwing' {
        { Get-ScheduledTaskInfo } | Should -Not -Throw
    }
}

Describe 'Stub functions' -Skip:(-not $IsLinux) {
    It '<_> exports and emits a warning on Linux' -ForEach $script:stubCmdlets {
        $cmd = Get-Command -Name $_ -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $warnings = $null
        & $_ -WarningVariable warnings -WarningAction SilentlyContinue 2>$null
        $warnings | Should -Not -BeNullOrEmpty
    }
}

Describe 'Windows passthrough' -Skip:$IsLinux {
    It '<_> is callable on Windows without error' -ForEach $script:allCmdlets {
        { Get-Command -Name $_ } | Should -Not -Throw
    }
}
