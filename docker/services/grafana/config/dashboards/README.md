## Grafana Dashboards

This directory contains JSON dashboard definitions that are automatically provisioned into Grafana on startup.

### Adding New Dashboards

#### Step 1: Create Dashboard in Grafana UI

1. Open Grafana and navigate to **Dashboards**
2. Click **+ New Dashboard** or **+ New** > **Dashboard**
3. Add panels and configure visualizations as needed
4. Test all queries and ensure they work correctly

#### Step 2: Configure Data Sources

When adding panels to your dashboard:

- Use the data source defined in `provisioning/datasources/default.yaml`
- The default data source UID is: `prometheus_ds`
- **This UID must be set in the dashboard JSON for instant functionality**
- If you use a different data source, you **must** update its UID in the JSON file before committing

**Important**: The datasource UID in your dashboard JSON must match the `uid` field in `provisioning/datasources/default.yaml`. Otherwise, panels will show "No data source" errors when the dashboard is imported, or require manual fixes via the UI.

#### Step 3: Export Dashboard

1. Once your dashboard is complete and tested, click the **Share** button (top right)
2. Select the **Export** tab
3. Check the **"Export for sharing externally"** checkbox to remove user-specific settings
4. Click **Save to file** to download the JSON file
5. Save the file with a descriptive name using lowercase with hyphens (e.g., `system-metrics.json`)

#### Step 4: Verify Datasource UID

Before committing the JSON file:

1. Open the exported JSON file in your editor
2. Search for `"datasourceUid"` fields
3. Ensure all occurrences are set to `"prometheus_ds"`
4. If they reference a different UID, replace them with `prometheus_ds`

**Example**:

```json
"datasources": {
  "prometheus_ds": {
    "uid": "prometheus_ds"
  }
}
```

#### Step 5: Place in Repository

1. Add the exported JSON file to this `dashboards/` directory
2. Commit to version control
3. Restart Grafana (or the Docker container) to load the new dashboard
   ```bash
   docker-compose restart grafana
   ```

### Dashboard Naming Convention

- Use lowercase letters and hyphens: `dashboard-name.json`
- Be descriptive: `cpu-memory-usage.json`, `application-logs.json`
- Avoid spaces and special characters

### Important Notes

- **Datasource References**: Ensure dashboard JSON files reference `prometheus_ds` as the datasource UID
  - All panels must use this UID for the dashboard to work out of the box
  - If exporting from a different Grafana instance, update datasource UIDs in the JSON before importing

- **Read-Only Mode**: Dashboards are provisioned as read-only by default
  - This prevents accidental UI changes from being lost on restart
  - To modify, export the updated version and replace the JSON file

- **Dashboard ID**: Keep the `id` field as-is from export
  - This ensures dashboard stability and proper references
  - Don't remove or set to null

- **Variable References**: If using dashboard variables, ensure they reference available datasources correctly

### Exporting Process Checklist

- [ ] Dashboard is tested and working correctly
- [ ] All panels use the `prometheus_ds` datasource
- [ ] Click **Share** → **Export** → Check "Export for sharing externally"
- [ ] Save JSON file with proper naming convention (lowercase, hyphens)
- [ ] Open JSON file and verify all `"datasourceUid"` fields are set to `"prometheus_ds"`
- [ ] Commit file to repository
- [ ] Restart Grafana container: `docker-compose restart grafana`
- [ ] Verify dashboard loads and displays data correctly

### Troubleshooting

**"No data source" error after import**

- Check that all `datasourceUid` fields in the JSON are set to `prometheus_ds`
- Edit the JSON file to correct the UIDs, then restart Grafana

**Dashboard not appearing**

- Verify the file is in this `dashboards/` directory
- Restart Grafana: `docker-compose restart grafana`
- Check Grafana logs for provisioning errors: `docker-compose logs grafana`

**Changes not persisting**

- Remember: UI changes to provisioned dashboards are not saved automatically
- Always export the updated JSON and replace the file in this directory
- Then restart Grafana to apply changes

**Wrong datasource showing in panels**

- Export the dashboard again
- Verify `datasourceUid` fields in the JSON match `prometheus_ds`
- Replace the file and restart Grafana
