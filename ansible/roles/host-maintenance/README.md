# Ansible Role: Host Maintenance

An Ansible role designed to automate the weekly maintenance lifecycle of Ubuntu LXC containers and VMs.

This role manages full system updates (`apt dist-upgrade`), dependency cleanups, and reboot status checks. It also self-bootstraps an automated weekly cron job on the bastion host, complete with 30-day log rotation and aggregated Discord webhook notifications.

## Features

- **Pre-flight Reachability:** Gracefully skips offline or unreachable nodes without failing the playbook.
- **Automated Updates & Cleanup:** Executes `apt update`, `dist-upgrade`, `autoremove`, and `autoclean`.
- **Reboot Detection:** Checks `/var/run/reboot-required` and flags hosts that need manual intervention.
- **Self-Managing Automation:** Deploys a bash wrapper script to the bastion host and schedules a weekly cron job.
- **Log Rotation:** The deployed wrapper script automatically compresses previous logs and deletes archives older than 30 days.
- **Discord Integration:** Sends a rich embed summary report listing successful updates, offline nodes, and hosts requiring a reboot.

## Requirements

- **Passwordless Sudo:** The target nodes must have passwordless sudo configured for the `ansible` user, as this role uses the native `ansible.builtin.apt` module with `become: true`.
- **Bastion Host Environment:** The role assumes the control node is running as the `ansible` user with access to `/home/ansible/scripts` and `/home/ansible/logs`.

## Role Variables


| Variable               | Default    | Description                                                                          |
| ---------------------- | ---------- | ------------------------------------------------------------------------------------ |
| `enable_notifications` | `true`     | Toggles the Discord webhook notification step.                                       |
| `discord_admin_ping`   | `"@admin"` | The role/user string to ping in Discord if a node goes offline or requires a reboot. |
| `discord_webhook_url`  | `""`       | **Required.** The webhook URL for sending the Discord summary embed.                 |
| `maintenance_cron_minute` | `"0"` | Cron minute for the scheduled job. |
| `maintenance_cron_hour` | `"2"` | Cron hour for the scheduled job. |
| `maintenance_cron_weekday` | `"6"` | Cron weekday for the scheduled job (6 = Saturday). |

## Tags

This role utilizes tags to separate the infrastructure configuration from the actual update routines:

- `setup`: Executes tasks in `bastion-setup.yml`. Creates directories, deploys the bash wrapper script, and configures the cron job on the control node.
- `maintenance`: Executes the core update, cleanup, reboot check, and notification tasks on the target nodes.

## Example Playbook

To handle unreachable hosts cleanly, the top-level playbook should perform a pre-flight ping check, group the online nodes, and pass them to this role.

```yaml
# ubuntu-maintenance.yml
---
- name: Pre-flight reachability check
  hosts: lxcs
  gather_facts: false
  tasks:
    - name: Ping hosts to check reachability
      ansible.builtin.ping:
      ignore_unreachable: true
      register: ping_result

    - name: Add responding hosts to 'online_nodes' group
      ansible.builtin.group_by:
        key: online_nodes
      when: ping_result is succeeded and not ping_result.get('unreachable', false)

    - name: Show online nodes
      delegate_to: localhost
      run_once: true
      ansible.builtin.debug:
        msg: "Online nodes: {{ groups['online_nodes'] | default([]) | join(', ') }}"
      when: verbose | default(false) | bool

- name: Weekly System Maintenance
  hosts: online_nodes
  gather_facts: false
  roles:
    - host-maintenance
```

## Usage & Execution Flow

This role is designed for a "bootstrap once, run automatically" workflow.

1. Manual Bootstrap (Run Manually)
  When deploying this role for the first time, or when changes are made to the wrapper script (run-maintenance.sh.j2) or cron schedule, run the playbook manually.

```bash
ansible-playbook ubuntu-maintenance.yml
```

This executes the whole playbook. It updates the nodes immediately and installs the automated script and cron job onto the bastion host.

2. Automated Weekly Execution
  Once bootstrapped, the bastion host's cron job will execute every week, according to the schedule set by the according varibales (defaults to Saturday at 02:00 AM).

The deployed wrapper script is explicitly configured to run with --skip-tags "setup". This ensures the automated robot user only performs the actual maintenance tasks (updates, cleanups, notifications) without needlessly attempting to re-deploy its own bash scripts and cron schedules every week.
