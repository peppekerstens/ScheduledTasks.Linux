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

## How we built this

### Why this module exists

The Windows `ScheduledTasks` module is everywhere in automation: backups, maintenance scripts, health checks, anything that needs to run on a schedule. On Linux, the traditional answer is "just use cron". But cron has no PowerShell API, no `Get-ScheduledTask`, no structured output, and the syntax is a pain to generate programmatically. `ScheduledTasks.Linux` maps the Windows module's API to systemd timer units — the modern Linux equivalent — so you can write one scheduling script and run it on either platform.

### Why systemd timers, not cron

Cron was the obvious first choice, but systemd timers win for several reasons:
- They integrate with `systemctl` for status, start, stop, enable, disable — all the lifecycle verbs the Windows module has
- They log through `journald` — structured, queryable logs vs. cron's email-or-nothing approach
- `systemctl list-timers` gives structured output (next trigger time, last trigger time, unit name) — no parsing crontab files
- `OnCalendar=` expressions map cleanly from the Windows trigger types (`Daily`, `Weekly`, `Once`, `AtStartup`)

The main downside: systemd is not available everywhere (containers, minimal distros). The module requires systemd and throws a clear error if `systemctl` is not in PATH.

### Timer + service unit pair

Each registered task creates two files:
- A `.timer` unit with the `OnCalendar=` or `OnBootSec=` schedule
- A `.service` unit with the `ExecStart=` command

They share the same base name (e.g. `DailyBackup.timer` + `DailyBackup.service`). `systemctl` activates the timer, which triggers the service. `Register-ScheduledTask` writes both files, then calls `systemctl daemon-reload` and `systemctl enable` on the timer.

### User vs system scope

System tasks go to `/etc/systemd/system/` and require `sudo`. User tasks go to `~/.config/systemd/user/`. The scope is determined by the `TaskPath` parameter: `\` (backslash, matching the Windows root task folder) or a `RunLevel` of `Highest` maps to system scope; anything else (or no `TaskPath`) maps to user scope. The module checks `id -u` — if running as root, system scope is used by default.

### Trigger mapping

| Windows trigger | systemd `OnCalendar=` |
|---|---|
| `-Daily -At '02:00'` | `*-*-* 02:00:00` |
| `-Weekly -DaysOfWeek Monday -At '03:00'` | `Mon *-*-* 03:00:00` |
| `-Once -At '2026-06-01 08:00'` | `2026-06-01 08:00:00` |
| `-AtStartup` | `OnBootSec=1min` |
| `-AtLogOn` | `OnBootSec=1min` (user scope) |

`AtStartup` and `AtLogOn` both map to `OnBootSec=1min` — close enough for most automation purposes.

### Key gotchas

**Multiple actions are not supported.** Windows `ScheduledTasks` allows a task to have multiple `Action` objects. systemd service units have one `ExecStart`. If multiple actions are passed to `Register-ScheduledTask`, only the first is used, and a `Write-Warning` is emitted. This is documented behavior, not a silent failure.

**`Get-ScheduledTask` only sees tasks created by this module.** It queries `systemctl list-timers` and filters for units that have a corresponding `.service` file in the expected location. It does not enumerate all systemd timers — that would return noisy system-level timers that aren't "scheduled tasks" in the Windows sense.

**`Get-ScheduledTaskInfo` uses `systemctl show`.** The `LastRunTime` and `NextRunTime` properties come from the `LastTriggerUSec` and `NextElapseUSecRealtime` fields in `systemctl show`. These are microsecond timestamps that need converting to `[datetime]`.

### Test approach

Tests use Pester 5.2+ with `BeforeDiscovery` for platform detection. On Windows, structural tests run and Linux tests skip. On WSL2, 30 tests run covering: task creation (timer + service file generation), `Get-ScheduledTask` output, `Get-ScheduledTaskInfo`, start/stop/enable/disable, and `Unregister-ScheduledTask` cleanup. 9 example tests run via `Examples\Examples.Tests.ps1`. All tests clean up created timer units after themselves.

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
