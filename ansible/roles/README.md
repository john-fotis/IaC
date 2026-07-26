Sample Run on Ansible Bastion Host

```bash
ansible@hephaestus:~/IaC/ansible$ ansible-playbook -i inventories/docker.ini playbooks/docker-deploy.yml

PLAY [GitOps Phase 1 - Bastion Preparation] ************************************************************************************************

TASK [Run bastion preparation tasks] *******************************************************************************************************
included: docker-gitops for localhost

TASK [docker-gitops : Include pre-deployment validation tasks] *****************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/pre-deployment.yml for localhost

TASK [docker-gitops : Validate git_repo_url is set] ****************************************************************************************
ok: [localhost] => {
    "changed": false,
    "msg": "git_repo_url validation passed"
}

TASK [docker-gitops : Check if Git is installed on bastion] ********************************************************************************
ok: [localhost]

TASK [docker-gitops : Fail if Git is not installed] ****************************************************************************************
skipping: [localhost]

TASK [docker-gitops : Check if SOPS is installed (when enabled)] ***************************************************************************
ok: [localhost]

TASK [docker-gitops : Warn if SOPS is not installed] ***************************************************************************************
skipping: [localhost]

TASK [docker-gitops : Check if SOPS Age key file exists] ***********************************************************************************
ok: [localhost]

TASK [docker-gitops : Warn if SOPS Age key not found] **************************************************************************************
ok: [localhost] => {
    "msg": "WARNING: SOPS Age key file not found at /home/ansible/.config/sops/age/keys.txt"
}

TASK [docker-gitops : Ensure target hosts are reachable] ***********************************************************************************
ok: [localhost]

TASK [docker-gitops : Display connectivity status] *****************************************************************************************
ok: [localhost] => {
    "msg": "Successfully connected to localhost"
}

TASK [docker-gitops : Include Git synchronization tasks] ***********************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/git-sync.yml for localhost

TASK [docker-gitops : Ensure Git local directory exists] ***********************************************************************************
ok: [localhost]

TASK [docker-gitops : Check if Git repository already exists] ******************************************************************************
ok: [localhost]

TASK [docker-gitops : Clone Git repository] ************************************************************************************************
skipping: [localhost]

TASK [docker-gitops : Get current Git commit before pull] **********************************************************************************
ok: [localhost]

TASK [docker-gitops : Ensure working directory is clean] ***********************************************************************************
ok: [localhost]

TASK [docker-gitops : Pull latest changes from Git repository] *****************************************************************************
changed: [localhost]

TASK [docker-gitops : Ensure on main branch before creating temporary branch] **************************************************************
ok: [localhost]

TASK [docker-gitops : Remove old temporary branch if it exists] ****************************************************************************
ok: [localhost]

TASK [docker-gitops : Create and switch to temporary branch from latest remote] ************************************************************
changed: [localhost]

TASK [docker-gitops : Get current Git commit after pull] ***********************************************************************************
ok: [localhost]

TASK [docker-gitops : Set fact for Git commit] *********************************************************************************************
ok: [localhost]

TASK [docker-gitops : Display Git sync status] *********************************************************************************************
skipping: [localhost]

TASK [docker-gitops : Debug force deploy] **************************************************************************************************
skipping: [localhost]

TASK [docker-gitops : Skip deployment if no changes and not forced] ************************************************************************
skipping: [localhost]

TASK [docker-gitops : Include dynamic target detection] ************************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/detect-target-hosts.yml for localhost

TASK [docker-gitops : Get list of changed files from Git] **********************************************************************************
ok: [localhost]

TASK [docker-gitops : Filter changed compose files] ****************************************************************************************
ok: [localhost]

TASK [docker-gitops : Extract unique profiles from changed compose files] ******************************************************************
skipping: [localhost]

TASK [docker-gitops : Map detected profiles to inventory hosts] ****************************************************************************
skipping: [localhost]

TASK [docker-gitops : Fallback to all docker hosts if no profiles detected] ****************************************************************
ok: [localhost]

TASK [docker-gitops : Create dynamic inventory group for deployment] ***********************************************************************
changed: [localhost] => (item=athena)
changed: [localhost] => (item=phobos)

TASK [docker-gitops : Display dynamically resolved targets] ********************************************************************************
ok: [localhost] => {
    "msg": [
        "Changed compose files: []",
        "Detected profiles: None",
        "Resolved target hosts: ['athena', 'phobos']"
    ]
}

TASK [docker-gitops : Validate deployment target] ******************************************************************************************
ok: [localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [docker-gitops : Run SOPS decryption script] ******************************************************************************************
changed: [localhost]

TASK [docker-gitops : Find .sops and .sops.* files in docker directory] ********************************************************************
ok: [localhost]

TASK [docker-gitops : Remove .sops and .sops.* files from docker directory] ****************************************************************
skipping: [localhost]

TASK [docker-gitops : Include Docker stack synchronization tasks (via sync.sh)] ************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/sync.yml for localhost => (item=prod)
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/sync.yml for localhost => (item=dmz)

TASK [docker-gitops : Create necessary directories on the target host] *********************************************************************
ok: [localhost] => (item=/home/ansible/docker)
ok: [localhost] => (item=/home/ansible/docker/services)
ok: [localhost] => (item=/home/ansible/docker/secrets)
ok: [localhost] => (item=/home/ansible/docker/services/traefik/config)
ok: [localhost] => (item=/home/ansible/docker/services/socket-proxy)

TASK [docker-gitops : Sync prod Services] **************************************************************************************************
changed: [localhost]

TASK [docker-gitops : Find all secret files] ***********************************************************************************************
ok: [localhost]

TASK [docker-gitops : Ensure correct ownership and permissions on secret files] ************************************************************
skipping: [localhost]

TASK [docker-gitops : Create necessary directories on the target host] *********************************************************************
ok: [localhost] => (item=/home/ansible/docker)
ok: [localhost] => (item=/home/ansible/docker/services)
ok: [localhost] => (item=/home/ansible/docker/secrets)
ok: [localhost] => (item=/home/ansible/docker/services/traefik/config)
ok: [localhost] => (item=/home/ansible/docker/services/socket-proxy)

TASK [docker-gitops : Sync dmz Services] ***************************************************************************************************
changed: [localhost]

TASK [docker-gitops : Find all secret files] ***********************************************************************************************
ok: [localhost]

TASK [docker-gitops : Ensure correct ownership and permissions on secret files] ************************************************************
skipping: [localhost]

TASK [docker-gitops : Find decrypted .env and secret files] ********************************************************************************
ok: [localhost]

TASK [docker-gitops : Remove decrypted files from local runner directory] ******************************************************************
changed: [localhost] => (item={'path': '/home/ansible/actions-runner/_work/IaC/docker/.env.sample', 'mode': '0664', 'isdir': False, 'ischr': False, 'isblk': False, 'isreg': True, 'isfifo': False, 'islnk': False, 'issock': False, 'uid': 1001, 'gid': 1001, 'size': 666, 'inode': 22458, 'dev': 64530, 'nlink': 1, 'atime': 1784484527.3035274, 'mtime': 1784484527.3035274, 'ctime': 1784484527.3035274, 'gr_name': 'ansible', 'pw_name': 'ansible', 'wusr': True, 'rusr': True, 'xusr': False, 'wgrp': True, 'rgrp': True, 'xgrp': False, 'woth': False, 'roth': True, 'xoth': False, 'isuid': False, 'isgid': False, 'blocks': 8, 'disk_usage_bytes': 4096})
changed: [localhost] => (item={'path': '/home/ansible/actions-runner/_work/IaC/docker/.env.dmz', 'mode': '0664', 'isdir': False, 'ischr': False, 'isblk': False, 'isreg': True, 'isfifo': False, 'islnk': False, 'issock': False, 'uid': 1001, 'gid': 1001, 'size': 2202, 'inode': 23785, 'dev': 64530, 'nlink': 1, 'atime': 1784484532.9375706, 'mtime': 1784484532.9595706, 'ctime': 1784484532.9595706, 'gr_name': 'ansible', 'pw_name': 'ansible', 'wusr': True, 'rusr': True, 'xusr': False, 'wgrp': True, 'rgrp': True, 'xgrp': False, 'woth': False, 'roth': True, 'xoth': False, 'isuid': False, 'isgid': False, 'blocks': 8, 'disk_usage_bytes': 4096})
changed: [localhost] => (item={'path': '/home/ansible/actions-runner/_work/IaC/docker/.env.prod', 'mode': '0664', 'isdir': False, 'ischr': False, 'isblk': False, 'isreg': True, 'isfifo': False, 'islnk': False, 'issock': False, 'uid': 1001, 'gid': 1001, 'size': 7490, 'inode': 21071, 'dev': 64530, 'nlink': 1, 'atime': 1784484532.742569, 'mtime': 1784484532.7655692, 'ctime': 1784484532.7655692, 'gr_name': 'ansible', 'pw_name': 'ansible', 'wusr': True, 'rusr': True, 'xusr': False, 'wgrp': True, 'rgrp': True, 'xgrp': False, 'woth': False, 'roth': True, 'xoth': False, 'isuid': False, 'isgid': False, 'blocks': 16, 'disk_usage_bytes': 8192})

TASK [docker-gitops : Ensure secrets are scrubbed regardless of deployment status] *********************************************************
ok: [localhost] => {
    "msg": "Secrets cleanup executed on bastion"
}

PLAY [GitOps Phase 2 - Target Host Deployment] *********************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************
ok: [phobos]
ok: [athena]

TASK [Run remote deployment tasks] *********************************************************************************************************
included: docker-gitops for athena, phobos

TASK [docker-gitops : Set compose_profile fact based on target host] ***********************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Display pre-flight info] *********************************************************************************************
ok: [athena] => {
    "msg": "=== Starting GitOps Phase 2 Pipeline === Target Host: athena Profile: prod Dry Run: False"
}
ok: [phobos] => {
    "msg": "=== Starting GitOps Phase 2 Pipeline === Target Host: phobos Profile: dmz Dry Run: False"
}

TASK [docker-gitops : Include Docker stack deployment tasks] *******************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/deploy-stack.yml for athena, phobos

TASK [docker-gitops : Pull latest Docker images for the stack] *****************************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Run Docker Compose to deploy the stack] ******************************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Display Docker Compose output] ***************************************************************************************
skipping: [athena]
skipping: [phobos]

TASK [docker-gitops : Include post-deployment controller (Verify, Cleanup, Notify)] ********************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/post-deployment.yml for athena, phobos

TASK [docker-gitops : Wait for services to be healthy] *************************************************************************************
FAILED - RETRYING: [phobos]: docker-gitops : Wait for services to be healthy (23 retries left).
FAILED - RETRYING: [athena]: docker-gitops : Wait for services to be healthy (23 retries left).
FAILED - RETRYING: [phobos]: docker-gitops : Wait for services to be healthy (22 retries left).
FAILED - RETRYING: [athena]: docker-gitops : Wait for services to be healthy (22 retries left).
FAILED - RETRYING: [phobos]: docker-gitops : Wait for services to be healthy (21 retries left).
FAILED - RETRYING: [athena]: docker-gitops : Wait for services to be healthy (21 retries left).
FAILED - RETRYING: [phobos]: docker-gitops : Wait for services to be healthy (20 retries left).
ok: [athena]
FAILED - RETRYING: [phobos]: docker-gitops : Wait for services to be healthy (19 retries left).
ok: [phobos]

TASK [docker-gitops : Parse compose JSON output] *******************************************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Determine failed and unhealthy containers] ***************************************************************************
ok: [phobos]
ok: [athena]

TASK [docker-gitops : Set deployment status] ***********************************************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Import Cleanup Tasks] ************************************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/cleanup.yml for athena, phobos

TASK [docker-gitops : Cleanup unused Docker resources] *************************************************************************************
changed: [phobos]
changed: [athena]

TASK [docker-gitops : Display cleanup results] *********************************************************************************************
skipping: [athena]
skipping: [phobos]

TASK [docker-gitops : Import Notification Tasks] *******************************************************************************************
included: /home/ansible/IaC/ansible/roles/docker-gitops/tasks/notify.yml for athena, phobos

TASK [docker-gitops : Set Discord embed color based on status] *****************************************************************************
ok: [athena]
ok: [phobos]

TASK [docker-gitops : Send Discord Notification] *******************************************************************************************
ok: [athena -> localhost]

TASK [docker-gitops : Fail Ansible run if deployment is unhealthy] *************************************************************************
skipping: [athena]
skipping: [phobos]

TASK [docker-gitops : Display deployment summary] ******************************************************************************************
ok: [athena] => {
    "msg": "=== Docker GitOps Deployment Summary === Target Host: athena Environment: prod Git Commit: 60c5b60 Repository: git@github.com:john-fotis/IaC.git Deployment Directory: /home/ansible/docker SOPS Enabled: True Dry Run: False Deployment completed successfully."
}
ok: [phobos] => {
    "msg": "=== Docker GitOps Deployment Summary === Target Host: phobos Environment: dmz Git Commit: 60c5b60 Repository: git@github.com:john-fotis/IaC.git Deployment Directory: /home/ansible/docker SOPS Enabled: True Dry Run: False Deployment completed successfully."
}

PLAY RECAP *********************************************************************************************************************************
athena                     : ok=18   changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
localhost                  : ok=40   changed=7    unreachable=0    failed=0    skipped=10   rescued=0    ignored=0
phobos                     : ok=17   changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0

ansible@hephaestus:~/IaC/ansible$
```
