#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'ScheduledTasks.Linux' 'ScheduledTasks.Linux.psd1'
    $examplesDir = $PSScriptRoot

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
