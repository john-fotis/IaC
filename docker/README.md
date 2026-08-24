# 🐳 Docker Workloads & Services Integration

This directory is the core execution environment for all containerized applications in the homelab. It uses a modular, heavily segmented Docker Compose architecture designed for **GitOps automation**, **strict environmental isolation**, and **secure secret injection**.

## 📂 Directory Layout

```text
docker/
├── docker-compose-dmz.yaml       # Master Compose definition for the public edge
├── docker-compose-prod.yaml      # Master Compose definition for internal core services
├── secrets/                      # SOPS-encrypted configuration values and credentials
│   ├── dmz/                      # Secrets scoped strictly to the DMZ VLAN
│   └── prod/                     # Secrets scoped strictly to the Prod VLAN
├── services/                     # Isolated directories for individual applications
│   ├── authentik/                # Service Compose and custom configurations
│   ├── traefik/                  # Dynamic proxy routing rules per environment
│   └── ...                       # Nextcloud, Immich, monitoring stack, etc.
└── sync.sh                       # Utility script for local synchronization tasks
```

## 🏗️ Service Deployment Strategy

Instead of maintaining a massive monolithic `docker-compose.yaml`, this repository uses **Docker Compose `include` statements** (Compose v2.20+) to build environment-specific master stacks.

Each Docker service is defined in its own directory under `docker/services/` and contains at least one `compose.yaml` file. Services may also include application-specific configuration files, such as:

- Traefik File Provider configurations
- Grafana dashboards
- Application configuration files
- Additional environment-specific resources

The environments are aggregated at the root of the `docker/` directory:

| Master Compose File        | Environment | Purpose                |
| -------------------------- | ----------- | ---------------------- |
| `docker-compose-prod.yaml` | Prod        | Internal/core services |
| `docker-compose-dmz.yaml`  | DMZ         | Public-facing services |

## 🔄 Manual Synchronization

The `sync.sh` script provides a legacy/manual method for synchronizing Docker workloads to the target **Prod** or **DMZ** hosts.

It is still fully functional and can be used when a direct manual synchronization is required:

```bash
./sync.sh prod
./sync.sh dmz
```

A dry run can be performed with:

```bash
./sync.sh prod --dry-run
```

Verbose output can be enabled with:

```bash
./sync.sh prod --verbose
```

The script:

- Synchronizes the appropriate master Compose file and environment configuration.
- Synchronizes environment-specific SOPS secrets.
- Synchronizes the corresponding Traefik configuration.
- Synchronizes the appropriate Docker Socket Proxy configuration.
- Detects services matching the requested `prod` or `dmz` Compose profile.
- Synchronizes only the services belonging to the selected environment.
- Removes `.sops` files from the target host after synchronization.

> **ℹ️ Deployment Note:** `sync.sh` was the original manual synchronization mechanism for deploying the Docker environment to the target hosts. The repository has since moved to **Ansible-based GitOps deployment**, which is now the preferred and automated deployment method. `sync.sh` remains available as a manual fallback and for troubleshooting or emergency synchronization when required.

### Master Compose Files

The master Compose files perform three critical functions:

1. **Service Aggregation**
   Pull the required service Compose definitions from `services/` based on the deployment environment.

2. **Network Definition**
   Establish the underlying Docker networks, such as `traefik_proxy`, `database_net`, and `socket_proxy`, providing strict network isolation between containers.

3. **Environment Mapping**
   Map decrypted secrets and global `.env` configuration to the services that require them.

> **Note:** Docker Compose profiles can be used within individual service definitions to control execution. However, the physical separation of the master Compose files provides stronger isolation between the Prod and DMZ environments, particularly for networks and secrets.

## 🔐 Secrets Management with SOPS

Sensitive configuration is managed using **Mozilla SOPS** and **Age encryption**.

Encrypted secret files are stored in the repository, while plaintext files are kept locally for applications that require them. The SOPS automation handles:

- Discovering files that require encryption
- Maintaining `.sops/config.txt`
- Updating the automatically generated `.gitignore` entries
- Encrypting and re-encrypting secret files
- Decrypting encrypted files when required

The normal workflow is integrated with the repository's **pre-commit task**, so secrets do not need to be manually encrypted before every commit.

For the complete SOPS workflow, file conventions, encryption/decryption commands, Age key handling, and Git hook setup, see:

👉 **[SOPS Secrets Management Documentation](../.sops/README.md)**

> **Important:** Plaintext secrets must never be committed to Git. Only the encrypted `.sops` versions should be tracked.

## 🚦 Traefik & Dynamic Routing

The `services/traefik/` directory contains the configuration for the dual-proxy architecture used across the **DMZ** and **Prod** environments.

Rather than relying exclusively on Docker labels, complex routing is managed through the Traefik **File Provider** structure:

```text
services/
└── traefik/
    └── config/
        ├── common/
        ├── dmz/
        └── prod/
```

### `common/`

Contains configuration shared by both Traefik instances, including:

- Compression middleware
- Security headers
- Authentication middleware
- TLS configuration
- Other common middleware definitions

### `dmz/`

Contains routing configuration for externally accessible services, such as:

- Nextcloud
- Immich
- Authentik Proxy External OIDC endpoint
- Other public-facing applications

### `prod/`

Contains internal-only routing for core infrastructure services, such as:

- TrueNAS
- Proxmox APIs
- Pi-hole
- Other internal homelab services

Both `prod` and `dmz` also contain their own **Traefik**, **Docker Socket Proxy**, and **CrowdSec** Web Application Firewall stacks.

More information about this topic is available in [Traefik Proxy Directory Documentation](./services/traefik/README.md).

## 🛠️ Adding a New Service

Follow the workflow below when integrating a new application into the architecture.

### 1. Create the Service Directory

Create a dedicated directory under:

```text
services/<app_name>/
```

For example:

```text
services/my_app/
```

### 2. Define the Compose File

Create:

```text
services/<app_name>/compose.yaml
```

The service should reference the external Docker networks defined by the appropriate master Compose file, such as the socket proxy or database networks.

### 3. Configure Secrets

If the application requires passwords, API tokens, or other sensitive values, create the required plaintext secret under the appropriate environment:

```text
secrets/<env>/<secret_name>
```

The repository's SOPS automation will discover and encrypt the file.

See the **[SOPS Secrets Management Documentation](../.sops/README.md)** for the complete workflow.

### 4. Update the Master Compose File

Add the service to the appropriate master Compose file.

For example, in `docker-compose-prod.yaml`:

```yaml
include:
  - services/new_app/compose.yaml
```

Configure its secrets as required:

```yaml
secrets:
  new_app_secret:
    file: ./secrets/new_app_secret
```

Use `docker-compose-dmz.yaml` instead when the service belongs to the DMZ environment.

### 5. Commit and Push

When setting up the repository for the first time, install the Git pre-commit hook in the local clone.

Edit:

```text
.git/hooks/pre-commit
```

and add:

```bash
#!/usr/bin/env bash

# Execute the pre-commit task to update .gitignore and ensure new secrets are encrypted
task pre-commit
```

Make sure the hook is executable:

```bash
chmod +x .git/hooks/pre-commit
```

The hook automatically runs the `pre-commit` task before each commit. This handles the SOPS workflow and ensures encrypted secret files are prepared for the commit.

> **Important:** Git hooks stored under `.git/hooks/` are local to each Git clone and are **not tracked by Git**. Therefore, every new clone must configure the hook once.

After the initial setup, no further manual action is required.

Finally:

```bash
git add .
git commit -m "Add new service"
git push
```

The GitOps pipeline will then:

1. Pull the updated repository.
2. Decrypt the required secrets.
3. Deploy the updated Compose stack.
4. Remove temporary plaintext secret files after deployment.

This keeps service deployment reproducible while maintaining clear separation between the **Prod** and **DMZ** environments.
