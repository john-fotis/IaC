# ⚙️ Ansible Configuration & GitOps Automation

This directory contains the playbooks, roles, and inventories used to transform raw, freshly provisioned VMs and LXCs into production-ready infrastructure nodes.

Ansible serves two distinct purposes in this architecture:

1. **Initial Bootstrapping:** Hardening the OS, creating users, and installing runtimes.
2. **GitOps Engine:** Acting as the deployment mechanism that continuously syncs Docker workloads with the current state of the repository.

## 🔄 The GitOps Workflow

While dedicated container management tools like **Komodo** and **Portainer** are deployed for granular, UI-based container control and troubleshooting, the actual source of truth for deployments remains in code.

Updates are managed via an automated, agentless GitOps pipeline:

1.  **Renovate Bot:** Scans the repository for outdated Docker images or package versions and automatically opens Pull Requests.
2.  **GitHub Actions:** Upon a merge to `master`, a GitHub Actions runner is triggered.
3.  **Bastion Execution:** The GitHub runner agent shares the same environment/machine as the `ansible` system user.
4.  **Deployment:** The runner executes the `docker-deploy.yml` playbook. Ansible connects to the target hosts, pulls the latest repository changes, decrypts secrets on the fly via SOPS, and executes `docker compose up -d` against the updated stacks.

## 📁 Directory Structure & Inventories

- **`ansible.cfg` decrypted from `ansible.sops.cfg` on the fly:** Core configurations, heavily tuned for SSH pipelining and SOPS decryption integration.
- **`inventories/`:** Contains static host definitions (eg. `hosts.ini` decrypted from `hosts.sops.ini`) mapping IPs to groups (e.g., `prod`, `dmz` or `lxc` / `vm`). Secrets and sensitive environment variables are mapped in the `group_vars/` directory using `.sops.yml` files, which are decrypted seamlessly at runtime.

## 📜 Core Playbooks

- **`lxc-setup.yml`:** Specifically tailored to bootstrap Proxmox LXC unpriviledged containers.
- **`prod-setup.yml` & `dmz-setup.yml`:** Targeted playbooks to initialize standard hosts in their respective VLANs.
- **`lxc-maintenance.yml`:** An automated routine task to keeps Ubuntu lxcs up to date, in a similar way as `unattended-upgrades` package does on VMs.
- **`docker-deploy.yml`:** The primary GitOps playbook. It pushes changes to the Docker hosts and deploys the docker stacks according to the profiles of the target hosts.

## 🛠️ Custom Roles Deep-Dive

The automation relies on highly modularized roles to maintain idempotency and clean code.

### `host-init-setup`

The foundational baseline applied to every machine in the homelab.

- **Users & Auth:** Creates the default user and the dedicated `ansible` management user. Distributes predefined SSH public keys.
- **Security:** Configures `sshd_config` to disable root login and enforce key-based authentication.
- **Shell Customization:** Injects standardized `.bash_aliases` and `.zsh_aliases` for a consistent terminal experience across all nodes.
- **System Prep:** Updates baseline packages, sets timezones, and configures basic networking.

### `docker-install`

Applied to any host intended to run containerized workloads.

- Installs dependencies, adds the official Docker GPG keys and APT repositories.
- Installs the Docker engine, CLI, and Compose plugins.
- Injects a custom `docker_daemon.json` to enforce specific logging constraints (e.g., log rotation limits) to prevent run-away containers from exhausting disk space.

### `mount-nfs`

Used by media and storage-heavy nodes (e.g., Nextcloud, Immich).

- Installs `nfs-common`.
- Configures `/etc/fstab` to persistently mount datasets originating from the TrueNAS storage backend in the Prod VLAN.

### `docker-gitops`

The core engine of the CI/CD pipeline.

- **`git-sync`:** Pulls the latest state of this repository down to the target node's local `/opt/` directory. (Note: When executed via the local GitHub runner, sync steps are intelligently bypassed to save execution time, as the runner checkout logic handles this).
- **`sops-decrypt`:** Utilizes the target node's locally deployed Age key to decrypt `*.sops` files within `docker/secrets/`, outputting plain-text files required for the `.env` injects.
- **`deploy-stack`:** Detects the node's assigned profile (Prod or DMZ) and executes `docker compose --profile <env> up -d --remove-orphans`, ensuring the running state perfectly matches the repository code.
- **`cleanup`:** Securely wipes the decrypted plain-text secrets from the disk immediately after the containers are successfully brought up, ensuring secrets only exist in memory or encrypted at rest.
