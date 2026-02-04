## Grafana Configuration Structure Documentation

The `grafana/config` folder contains all necessary provisioning and dashboard configuration files for Grafana. This directory is automatically mounted to the Grafana container and enables automated setup without manual configuration in the UI.

### Directory Layout

```bash
config/
├── dashboards/           # Guidelines for adding new dashboards
└── provisioning/
    ├── dashboards/
    │   └── default.yaml  # Dynamic Dashboard Provider configuration
    └── datasources/
        └── default.yaml  # Default Data Source connection (Prometheus)
```

- **dashboards/**: Contains JSON dashboard definition files
  - Store pre-built dashboard configurations here as `.json` files
  - Dashboards are automatically loaded by the provisioning system
  - **All dashboards must use the datasource UID: `prometheus_ds`** (see Data Sources section)
  - See [dashboards/README.md](dashboards/README.md) for naming conventions and guidelines

- **provisioning/**: Automated Grafana setup configuration
  - **dashboards/default.yaml**: Defines dashboard loading paths and settings
    - Uses file-based provisioning to auto-load JSON files from the `dashboards/` directory
    - Supports folder structure organization
  - **datasources/default.yaml**: Defines metric data sources
    - Currently configured with Prometheus on `http://prometheus:9090`
    - Available as `prometheus_ds` in the Grafana UI

### Setup Instructions

1. **Add Dashboards**
   - Create new `.json` files in the `dashboards/` directory
   - Follow naming convention: lowercase with hyphens (e.g., `system-metrics.json`)
   - **Ensure all panels reference the datasource UID: `prometheus_ds`**
   - See [dashboards/README.md](dashboards/README.md) for export instructions

2. **Configure Data Sources**
   - Edit `provisioning/datasources/default.yaml` to add/modify connections
   - Changes take effect automatically on Grafana restart

3. **Configure Dashboards**
   - Edit `provisioning/dashboards/default.yaml` to change loading behavior
   - The current setup auto-discovers JSON files in `dashboards/`

4. **Environment Variables**
   - Grafana uses secrets for sensitive data (admin credentials, OAuth tokens)
   - See [compose.yaml](../compose.yaml) for environment variable configuration
   - File-based secrets are supported via `__FILE` suffix (e.g., `GF_SECURITY_ADMIN_USER__FILE`)

### Data Sources

Currently configured data sources:

- **Prometheus** (`prometheus_ds`)
  - URL: `http://prometheus:9090`
  - UID: `prometheus_ds` (used in dashboard JSON files)
  - Used for all metrics visualizations
  - Set as default data source

### Authentication

Grafana is configured with OAuth support via Authentik:

- OAuth configuration via environment variables in [compose.yaml](../compose.yaml)
- Secrets managed through Docker secrets
- Auto-login can be enabled via `GF_AUTH_OAUTH_AUTO_LOGIN` environment variable

### File Provisioning Notes

- Grafana automatically reloads provisioning configurations on restart
- Dashboard files are read-only by default (`disableDeletion: true`)
- Changes made via Grafana UI are not persisted to JSON files
- Export dashboards from the UI and update JSON files to persist changes
- **Dashboard datasource references must match the UID in `provisioning/datasources/default.yaml`**

### Tips

- All dashboard JSON files must reference `prometheus_ds` as the datasource UID for instant functionality
- Test dashboards in your local environment first
- Keep dashboard descriptions and titles updated in the JSON
- Use Grafana's built-in dashboard export feature to maintain consistency
- When exporting dashboards, verify the datasource UID is set to `prometheus_ds` before committing
