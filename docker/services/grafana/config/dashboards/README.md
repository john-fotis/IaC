# Grafana Dashboards

This directory contains Grafana dashboard configuration files.

## Adding a New Dashboard

1. **Create the dashboard in Grafana UI**
   - Navigate to your Grafana instance
   - Design your dashboard with desired panels and visualizations
   - Click "Save" when complete

2. **Export the dashboard**
   - Go to Dashboard settings (gear icon)
   - Select "JSON Model"
   - Copy the entire JSON content

3. **Add to this directory**
   - Create a new `.json` file in this directory
   - Name it descriptively (e.g., `my-dashboard.json`)
   - Paste the exported JSON content

4. **Provision the dashboard**
   - Grafana will automatically load JSON files from this directory
   - Restart Grafana or reload the provisioning configuration

## File Naming Convention

Use lowercase with hyphens:

- ✅ `system-metrics.json`
- ✅ `app-performance.json`
- ❌ `SystemMetrics.json`
- ❌ `appPerformance.json`

## Example Dashboard Structure

```json
{
  "title": "Basic Home Dashboard",
  "panels": [
    {
      "type": "text",
      "title": "Welcome",
      "options": {
        "content": "Hello world!"
      }
    }
  ],
  "schemaVersion": 39
}
```

## Tips

- Remove auto-generated IDs before committing
- Test dashboards in your local environment first
- Keep descriptions updated in the dashboard JSON
