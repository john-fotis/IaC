## 🔐 Secrets Management with SOPS

All sensitive configuration, including database passwords, API tokens, webhook IDs, credentials, and other private configuration values, is managed using **Mozilla SOPS** with **Age encryption**.

The repository keeps **plaintext files locally** for applications to consume, while the corresponding encrypted `.sops` files are committed to Git.

### 🔑 SOPS File Convention

A plaintext file is encrypted by inserting `.sops` before its extension.

For example:

```text
docker/secrets/prod/authentik.env
docker/secrets/prod/authentik.sops.env
```

For files without an extension:

```text
some_secret
some_secret.sops
```

Only the encrypted `.sops` variants should be committed to Git.

Plaintext secret files are automatically added to `.gitignore` by the SOPS workflow.

### 📋 Secret File Configuration

The file:

```text
.sops/config.txt
```

contains the list of files that should be treated as secrets.

The repository's SOPS automation automatically discovers and manages several types of sensitive files, including:

- Docker secrets
- `.env` files
- Traefik configuration files
- Ansible inventory files
- `ansible.cfg`
- `.conf` files

Files matching templates, `.sops` files, and `.sops.*` files are excluded from automatic discovery.

The resulting `.sops/config.txt` acts as the central list of plaintext files that must be encrypted and ignored by Git.

### 🔒 Encryption Workflow

Encryption is normally handled automatically through the repository's `pre-commit` task.

Run:

```bash
task pre-commit
```

The workflow performs the following operations:

1. Scans the repository for files that should be encrypted.
2. Updates `.sops/config.txt`.
3. Updates the automatically generated SOPS section of `.gitignore`.
4. Removes plaintext secret files from Git tracking if they were previously tracked.
5. Encrypts each configured plaintext file using the repository's Age public key.
6. Creates the corresponding `.sops` encrypted file.
7. Re-encrypts an existing `.sops` file only when its plaintext source has changed.
8. Stages the generated `.gitignore` changes.

For example, adding:

```text
docker/secrets/prod/new_app.env
```

and running:

```bash
task pre-commit
```

will result in:

```text
docker/secrets/prod/new_app.env
docker/secrets/prod/new_app.sops.env
```

The plaintext file remains available locally for the application, while the encrypted `.sops` file is the version intended for Git.

### 🔓 Decryption Workflow

Encrypted files can be decrypted using:

```bash
.sops/decrypt.sh
```

or, if the repository provides the corresponding Task command:

```bash
task decrypt
```

The decryption script searches the repository for:

```text
*.sops
*.sops.*
```

and recreates the corresponding plaintext files.

For example:

```text
docker/secrets/prod/authentik.sops.env
```

is decrypted to:

```text
docker/secrets/prod/authentik.env
```

If the plaintext file already exists, the decrypted content is compared against it first. The file is only replaced when its contents differ.

Both normal text files and binary files are supported.

### 🔐 Age Keys

The encryption process uses an **Age public key** stored in the repository's SOPS configuration:

```text
.sops/age.key
```

Despite the filename, this file is used by the encryption script as the **public encryption key**.

The corresponding **Age private key must never be committed to Git**.

The private key is required by the deployment/decryption environment to decrypt the `.sops` files.

> **⚠️ Security:** Anyone with access to the Age public key can encrypt data for the repository, but cannot decrypt existing secrets. The Age private key must therefore be protected separately and must never be stored in the repository.

### 🚀 Git Pre-Commit Integration

The repository integrates the SOPS workflow with Git through a local pre-commit hook.

Each clone must configure:

```text
.git/hooks/pre-commit
```

with:

```bash
#!/usr/bin/env bash

task pre-commit
```

and make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

After this initial setup, the SOPS workflow runs automatically whenever a commit is created.

> **Important:** `.git/hooks/` is local to each Git clone and is **not tracked by Git**. Therefore, configuring the hook once in one clone does not configure it for other users or future clones.

The hook ensures that newly added secret files are discovered, encrypted, ignored by Git, and that the encrypted versions are available to be committed without requiring manual SOPS commands.

### 📝 Adding a New Secret

When adding a new secret, create the **plaintext** file normally.

For example:

```text
docker/secrets/prod/new_app.env
```

Do **not** manually create the `.sops` file.

Then run:

```bash
task pre-commit
```

The automation will:

```text
new_app.env
      │
      ▼
discover file
      │
      ├── update .sops/config.txt
      ├── update .gitignore
      └── encrypt with Age
              │
              ▼
       new_app.sops.env
```

Afterwards, verify the Git status:

```bash
git status
```

The plaintext file should be ignored, while the encrypted `.sops` file should be available for commit.

Finally:

```bash
git add .
git commit -m "Add new service"
git push
```

### 🤖 GitOps Deployment

During deployment, the Ansible GitOps pipeline uses the encrypted `.sops` files from Git and the deployment environment's protected Age private key.

The general flow is:

```text
Git Repository
      │
      │ encrypted .sops files
      ▼
Ansible GitOps
      │
      │ Age private key
      ▼
SOPS decryption
      │
      ▼
Plaintext configuration
      │
      ▼
Docker Compose
      │
      ▼
Containerized services
```

Plaintext files are generated on the deployment host only when required by the deployment process and are removed afterwards according to the deployment workflow.

This keeps sensitive configuration encrypted in Git while still allowing Docker Compose and the deployed applications to consume the required plaintext configuration.
