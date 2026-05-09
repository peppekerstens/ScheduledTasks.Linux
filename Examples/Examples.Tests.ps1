#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeAll {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ScheduledTasks.Linux\ScheduledTasks.Linux.psd1'

    if ($IsLinux) {
        Import-Module $modulePath -Force
    }
}

AfterAll {
    if ($IsLinux) {
        Remove-Module ScheduledTasks.Linux -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Get-TaskSummary.ps1' {
    It 'runs without error on Linux' -Skip:(-not $IsLinux) {
        { & "$examplesDir\Get-TaskSummary.ps1" } | Should -Not -Throw
    }

    It 'runs without error on Windows' -Skip:$IsLinux {
        { & "$examplesDir\Get-TaskSummary.ps1" } | Should -Not -Throw
    }
}

Describe 'Get-DisabledTasks.ps1' {
    It 'runs without error on Linux' -Skip:(-not $IsLinux) {
        { & "$examplesDir\Get-DisabledTasks.ps1" } | Should -Not -Throw
    }

    It 'runs without error on Windows' -Skip:$IsLinux {
        { & "$examplesDir\Get-DisabledTasks.ps1" } | Should -Not -Throw
    }
}

Describe 'Register-DemoTask.ps1' -Skip:(-not $IsLinux) {
    It 'registers and then removes a demo task without error' {
        { & "$examplesDir\Register-DemoTask.ps1" -TaskName 'PSLinuxExTest1' } | Should -Not -Throw
    }

    It 'leaves no task behind after running' {
        & "$examplesDir\Register-DemoTask.ps1" -TaskName 'PSLinuxExTest2'
        $leftover = Get-ScheduledTask -TaskName 'PSLinuxExTest2' -ErrorAction SilentlyContinue
        $leftover | Should -BeNullOrEmpty
    }
}

Describe 'Register-PipelineTask.ps1' -Skip:(-not $IsLinux) {
    It 'registers and then removes a pipeline task without error' {
        { & "$examplesDir\Register-PipelineTask.ps1" -TaskName 'PSLinuxExTest3' } | Should -Not -Throw
    }

    It 'leaves no task behind after running' {
        & "$examplesDir\Register-PipelineTask.ps1" -TaskName 'PSLinuxExTest4'
        $leftover = Get-ScheduledTask -TaskName 'PSLinuxExTest4' -ErrorAction SilentlyContinue
        $leftover | Should -BeNullOrEmpty
    }
}

Describe 'New-ScheduledTaskAction returns expected shape' -Skip:(-not $IsLinux) {
    It 'Execute property is set correctly' {
        $a = New-ScheduledTaskAction -Execute '/usr/bin/echo' -Argument 'test'
        $a.Execute   | Should -Be '/usr/bin/echo'
        $a.Arguments | Should -Be 'test'
    }
}

Describe 'New-ScheduledTaskTrigger returns expected shape' -Skip:(-not $IsLinux) {
    It 'Daily trigger has correct OnCalendar format' {
        $t = New-ScheduledTaskTrigger -Daily -At '08:30'
        $t.TriggerType | Should -Be 'Daily'
        $t.OnCalendar  | Should -Match '08:30:00'
    }

    It 'AtStartup trigger maps to boot' {
        $t = New-ScheduledTaskTrigger -AtStartup
        $t.OnCalendar | Should -Be 'boot'
    }
}

Describe 'Scenario: Scheduled task create/export/disable/remove lifecycle' -Skip:(-not $IsLinux) {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'ScheduledTasks.Linux' 'ScheduledTasks.Linux.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
        $script:taskName = 'pester-test-task'
    }
    AfterAll {
        Unregister-ScheduledTask -TaskName $script:taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Module 'ScheduledTasks.Linux' -Force -ErrorAction SilentlyContinue
    }

    It 'Register-ScheduledTask creates a systemd timer unit' {
        $action  = New-ScheduledTaskAction -Execute 'echo' -Argument 'pester'
        $trigger = New-ScheduledTaskTrigger -Daily -At '03:00'
        { Register-ScheduledTask -TaskName $script:taskName -Action $action -Trigger $trigger } |
            Should -Not -Throw
    }
    It 'Get-ScheduledTask finds the registered task' {
        $task = Get-ScheduledTask -TaskName $script:taskName
        $task | Should -Not -BeNullOrEmpty
    }
    It 'Export-ScheduledTask returns unit file content' {
        $export = Export-ScheduledTask -TaskName $script:taskName
        $export | Should -Not -BeNullOrEmpty
        $export | Should -Match '\[Unit\]'
    }
    It 'Disable-ScheduledTask disables the task' {
        { Disable-ScheduledTask -TaskName $script:taskName } | Should -Not -Throw
    }
    It 'Enable-ScheduledTask re-enables the task' {
        { Enable-ScheduledTask -TaskName $script:taskName } | Should -Not -Throw
    }
    It 'Unregister-ScheduledTask removes the task' {
        { Unregister-ScheduledTask -TaskName $script:taskName -Confirm:$false } | Should -Not -Throw
        { Get-ScheduledTask -TaskName $script:taskName -ErrorAction Stop } | Should -Throw
    }
}
