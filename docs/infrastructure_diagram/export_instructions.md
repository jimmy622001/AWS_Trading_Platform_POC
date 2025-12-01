# Instructions for Exporting Architecture Diagrams

To complete the documentation update, please manually export the following diagram:

1. **Disaster Recovery Architecture PNG:**
   - Open `disaster_recovery_architecture.drawio.xml` in [draw.io](https://app.diagrams.net/)
   - Go to File > Export as > PNG...
   - Save as `disaster_recovery_architecture.png` in the same directory

## Steps to Export in Draw.io

1. Go to [draw.io](https://app.diagrams.net/)
2. Click "Open Existing Diagram"
3. Select "Open from Device"
4. Browse to `docs/infrastructure_diagram/disaster_recovery_architecture.drawio.xml`
5. Once opened, go to File > Export as > PNG...
6. Save the file as `disaster_recovery_architecture.png` in the same directory
7. After exporting the file, continue with the git commit as instructed below

## Git Commands to Complete Update

After generating the PNG file, run the following git commands:

```bash
git add docs/infrastructure_diagram/disaster_recovery_architecture.png
git add docs/infrastructure_diagram/README.md
git add docs/infrastructure_diagram/git_visualization_guide.md
git commit -m "Update architecture documentation and generate missing PNG file"
git push
```

This completes the documentation update as requested.