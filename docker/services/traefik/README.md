# Traefik Ingress Infrastructure

Traefik operates as the core reverse proxy and ingress layer for the entire Docker environment. Rather than acting as a standard application, it functions as shared infrastructure deployed across both the `prod` and `dmz` profiles to manage traffic, TLS termination, and service discovery.

## Architecture & Routing

- **Symmetric Deployment:** The exact same Docker Compose service definition is utilized across all environments, with behavior strictly dictated by environment-specific configurations injected at runtime. The only file that differentiates each enviroment is `<enviroment>/traefik.yaml` which is always commited encrypted (eg. `prod/traefik.sops.yaml`).
- **Network Isolation:** Traefik operates exclusively on the `traefik` frontend network for inbound traffic and communicates over the `socket_proxy` network for isolated backend functionalities.
- **Protocol Support:** Beyond standard HTTP/HTTPS proxying, it handles TCP/UDP routing for specialized services (e.g., Mailrise via SNI, Graphite Exporter, and Beszel Agent).

## Security Integration

- **Zero-Trust Docker API:** Traefik does not possess direct access to the host's `docker.sock`. It queries a read-only Docker Socket Proxy at `socket-proxy:2375`, effectively neutralizing container escape vulnerabilities.
- **Identity & Access:** Exposed HTTP services enforce authentication by applying shared middleware chains (e.g., `chain-authentik@file`), seamlessly routing unauthenticated requests to the central Identity Provider.
- **Active Defense:** The `traefik-logs` volume is mounted read-only by the local `CrowdSec` container, allowing the WAF engine to dynamically detect aggressive scanning and ban malicious actors at the edge.

## Operations & Deployment

- **Configuration Management:** Static and dynamic routing rules are structured within `services/traefik/config/common/` and environment-specific directories, keeping global proxy logic decoupled from individual application definitions.
- **Automated TLS:** Certificates are provisioned automatically via Cloudflare DNS-01 challenges, instantly securing `*.${FQDN}` without requiring individual, per-service certificate management.
- **Deployment Pipeline:** While the primary Ansible GitOps roles handle automated rollouts, the legacy `sync.sh <env>` script remains intact for manual configuration synchronization to target hosts during maintenance.
