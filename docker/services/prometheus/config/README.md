# Prometheus Configuration Folder Structure

This folder contains the Prometheus configuration and supporting files for monitoring services.

## Directory Layout

```
prometheus/config/
├── prometheus.yml         # Main Prometheus configuration file
├── alerts/                # Alert rules directory
│   ├── alerts.yml
│   └── *.yml|*.yaml       # Additional alert rule files
└── jobs/                  # Dynamic service discovery (file_sd)
    └── *.yml|*.yaml       # Job configuration files for external services
```

## File Descriptions

### `prometheus.yml`

Main configuration file containing:

- **Global settings**: 15s scrape and evaluation intervals
- **Alerting**: AlertManager integration on port 9093
- **Scrape configs**:
  - Prometheus self-monitoring (localhost:9090)
  - Node Exporter (node-exporter:9100)
  - cAdvisor (cadvisor:8080)
  - Dynamic file-based service discovery

### `alerts/` Directory

Store all alert rule files here (`.yml` or `.yaml`). Rules are evaluated every 15 seconds per the global configuration.

**Example**: `alerts/alerts.yml`

### `jobs/` Directory

Store additional job configurations for dynamic service discovery via file_sd. Prometheus automatically reloads these files without restart.

**Example**: `jobs/custom-service.yml`

## Notes

- All file paths in `prometheus.yml` are absolute (`/etc/prometheus/`)
- Mount this folder to `/etc/prometheus/config/` in your container
- Changes to `jobs/` and `alerts/` directories are detected automatically
