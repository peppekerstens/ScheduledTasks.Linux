# ScheduledTasks.Linux

A PowerShell module for Linux that provides cmdlet parity with the Windows `ScheduledTasks` module. Implements Get-ScheduledTask, Register-ScheduledTask, and related cmdlets by wrapping **systemd timer units**.

> **Linux only.** On Windows, use the built-in `ScheduledTasks` module.

---

## What it does

| Category | Cmdlets |
|---|---|
| Task objects | `New-ScheduledTask`, `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, `New-ScheduledTaskPrincipal`, `New-ScheduledTaskSettingsSet` |
| Query | `Get-ScheduledTask`, `Get-ScheduledTaskInfo` |
| Lifecycle | `Register-ScheduledTask`, `Unregister-ScheduledTask` |
| Control | `Start-ScheduledTask`, `Stop-ScheduledTask`, `Enable-ScheduledTask`, `Disable-ScheduledTask` |
| Stubs | `Set-ScheduledTask`, `Export-ScheduledTask` |

---

## Requirements

- PowerShell 7.2+
- Linux with systemd (Ubuntu 22.04+, Debian 11+, RHEL 8+, etc.)
- `systemctl` in PATH

---

## Installation

```powershell
# Clone the repo and import
Import-Module /path/to/ScheduledTasks.Linux/ScheduledTasks.Linux/ScheduledTasks.Linux.psd1
```

---

## Usage

```powershell
# Create a daily backup task
$action  = New-ScheduledTaskAction -Execute '/usr/bin/rsync' -Argument '-av /home /backup'
$trigger = New-ScheduledTaskTrigger -Daily -At '02:00'
Register-ScheduledTask -TaskName 'DailyBackup' -Action $action -Trigger $trigger -Description 'Daily home backup'

# List all scheduled tasks
Get-ScheduledTask

# Get timing info
Get-ScheduledTaskInfo -TaskName 'DailyBackup'

# Run immediately
Start-ScheduledTask -TaskName 'DailyBackup'

# Disable
Disable-ScheduledTask -TaskName 'DailyBackup'

# Remove
Unregister-ScheduledTask -TaskName 'DailyBackup'
```

---

## Cmdlet Status

| Cmdlet | Status | Linux tool |
|---|---|---|
| `New-ScheduledTaskAction` | ✅ Implemented | — |
| `New-ScheduledTaskTrigger` | ✅ Implemented | — |
| `New-ScheduledTaskPrincipal` | ✅ Implemented | — |
| `New-ScheduledTaskSettingsSet` | ✅ Implemented | — |
| `New-ScheduledTask` | ✅ Implemented | — |
| `Register-ScheduledTask` | ✅ Implemented | systemctl, unit files |
| `Get-ScheduledTask` | ✅ Implemented | systemctl list-timers |
| `Get-ScheduledTaskInfo` | ✅ Implemented | systemctl show |
| `Start-ScheduledTask` | ✅ Implemented | systemctl start |
| `Stop-ScheduledTask` | ✅ Implemented | systemctl stop |
| `Enable-ScheduledTask` | ✅ Implemented | systemctl enable |
| `Disable-ScheduledTask` | ✅ Implemented | systemctl disable |
| `Unregister-ScheduledTask` | ✅ Implemented | systemctl disable, rm |
| `Set-ScheduledTask` | 🔶 Stub | — |
| `Export-ScheduledTask` | 🔶 Stub | — |

---

## Implementation Notes

- Tasks are implemented as **systemd timer + service unit pairs**.
- System tasks (`TaskPath = '\'` or `RunLevel = 'Highest'`) go to `/etc/systemd/system/` and require `sudo`.
- User tasks go to `~/.config/systemd/user/`.
- Trigger types: `Daily`, `Weekly`, `Once`, `AtStartup`, `AtLogOn`.
  - `AtStartup` and `AtLogOn` map to `OnBootSec=1min` in the timer unit.
- Multiple actions in a single task are not supported (systemd service units have one `ExecStart`). Only the first action is used.
- The `Clustered*` cmdlets from the Windows module (`Get-ClusteredScheduledTask`, etc.) are not included — they are Windows-specific cluster features with no Linux equivalent.

---

## Version History

| Version | Date | Notes |
|---|---|---|
| 0.1.0 | 2026-05-08 | Initial release. 13 cmdlets implemented, 2 stubs. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
