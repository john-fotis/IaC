## Grafana Configuration Structure Documentation

The `grafana/config` folder contains all necessary provisioning and dashboard configuration files for Grafana. This directory should be organized as follows:

### Directory Layout

- **dashboards/**: Contains JSON dashboard definition files
  - Store pre-built dashboard configurations here
  - Example: `home.json` - your default home dashboard

- **provisioning/**: Main provisioning directory for automated Grafana setup
  - **alerting/**: Alert notification channels and alert rules configuration
  - **dashboards/**: Dashboard provisioning configuration files
    - `default.yaml` - defines which dashboards to load and where to find them
  - **datasources/**: Data source connection configurations
    - `default.yaml` - defines database/metrics source connections (Prometheus, InfluxDB, etc.)
  - **notifiers/**: Notification channel definitions for alerts
  - **plugins/**: Plugin configuration and installation settings

### Setup Instructions

1. Place JSON dashboard files in the `dashboards/` directory
2. Create YAML configuration files in respective `provisioning/` subdirectories
3. Use `provisioning/dashboards/default.yaml` to reference dashboard locations
4. Configure data sources in `provisioning/datasources/default.yaml`
5. Mount this entire `config/` folder to Grafana container as a volume
6. Restart Grafana to apply all configurations automatically

## Sample Folder Structure:

```bash
config
├── dashboards
│   └── home.json
└── provisioning
    ├── alerting
    ├── dashboards
    │   └── default.yaml
    ├── datasources
    │   └── default.yaml
    ├── notifiers
    └── plugins
```
