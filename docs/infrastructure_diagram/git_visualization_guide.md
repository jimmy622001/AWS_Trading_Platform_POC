# Git-Friendly Infrastructure Visualization Guide

This guide explains how to maintain and visualize trading platform architecture diagrams in a Git repository for optimal collaboration.

## Multiple Visualization Options

We've provided several formats of the infrastructure diagram to ensure it's accessible in different contexts:

1. **draw.io XML files** - Editable source files
2. **PNG images** - Visible directly in GitHub/GitLab UI

## Best Practices for Git-Friendly Diagrams

### For Diagram Creators/Editors

1. **Always update both formats when making changes:**
   ```bash
   # After editing the diagram in draw.io:
   # 1. Save as XML (preserves editability)
   # 2. Export as PNG (for visibility)
   git add trading_platform_architecture.drawio.xml
   git add trading_platform_architecture.png
   git add disaster_recovery_architecture.drawio.xml
   git add disaster_recovery_architecture.png
   git commit -m "Update architecture diagrams with new Lambda function"
   ```

2. **Keep the XML as the source of truth:**
   - All detailed edits should be made in draw.io using the XML file
   - Export to other formats after changes

3. **Use meaningful layering in draw.io:**
   - Group related components
   - Use consistent naming for layers
   - This helps when exporting to other formats

### For Repository Viewers

1. **GitHub/GitLab web interface:**
   - You'll see the PNG image rendered directly in the repository
   - Perfect for quick overview and reviews

2. **Local development:**
   - Open XML files in draw.io for detailed examination

3. **Pull Requests:**
   - Request both XML and PNG updates when reviewing changes

## Tools for Diagram Management

1. **draw.io / diagrams.net**
   - Primary tool for editing the XML source
   - Available as web, desktop, and VS Code extension

2. **VS Code Extension**
   - Install "Draw.io Integration" extension
   - Allows editing diagrams without leaving VS Code

3. **ASCII Diagram Tools**
   - For updating the ASCII version: [asciiflow.com](https://asciiflow.com)

## Diagram Update Workflow

1. Check out the repository branch
2. Open the XML file in draw.io
3. Make necessary changes
4. Save XML back to the repository
5. Export as PNG to the same directory
6. Commit all files together
7. Create a pull request with your changes

## Example: Adding a New Component

```bash
# 1. Edit XML in draw.io
# 2. Export as PNG
# 3. Update ASCII if needed

git add trading_platform_architecture.drawio.xml
git add trading_platform_architecture.png
git add disaster_recovery_architecture.drawio.xml
git add disaster_recovery_architecture.png
git commit -m "Add SQS dead letter queue to architecture diagrams"
git push origin feature/update-diagram
```

This approach ensures our infrastructure documentation remains accessible, editable, and visible across different contexts within our Git workflow.
