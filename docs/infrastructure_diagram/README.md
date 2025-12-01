# AWS Trading Platform Architecture Diagrams

This directory contains the infrastructure diagrams for our AWS Trading Platform architecture.

## Available Architecture Diagrams

This repository contains the following architecture diagrams:

1. **Trading Platform Architecture** - Main architecture diagram showing the components and data flow of the trading platform
2. **Disaster Recovery Architecture** - Diagram illustrating the DR strategy and components

## Viewing the Diagrams

### Option 1: Using draw.io (Recommended for editing)

1. Go to [draw.io](https://app.diagrams.net/)
2. Click "Open Existing Diagram"
3. Select "Open from Device"
4. Choose one of the `.drawio.xml` files:
   - `trading_platform_architecture.drawio.xml`
   - `disaster_recovery_architecture.drawio.xml`
5. Edit as needed and save changes back to the file

### Option 2: Using GitHub (For viewing only)

- If you're viewing this in GitHub, you can see the static image versions directly in the repository:
  - `trading_platform_architecture.png`
  - `disaster_recovery_architecture.png`

### Option 3: VS Code Extension

1. Install the "Draw.io Integration" extension for VS Code
2. Open the `.drawio.xml` file directly in VS Code

## Infrastructure Components

### Trading Platform Architecture

The diagram shows our complete AWS Trading Platform infrastructure with these key components:

1. **Frontend Layer**
   - CloudFront distribution
   - S3 hosted web application
   - Cognito user authentication

2. **API Layer**
   - API Gateway
   - Lambda functions
   - WAF protection

3. **Data Processing Layer**
   - SQS Queues
   - Lambda processors
   - EventBridge for event routing

4. **Storage Layer**
   - DynamoDB tables
   - S3 data lakes
   - ElastiCache for caching

5. **Security & Networking**
   - VPC with private subnets
   - IAM roles with least-privilege permissions
   - Security groups for traffic control

### Disaster Recovery Architecture

The DR architecture illustrates our multi-region failover strategy:

1. **Primary Region**
   - Active trading platform components
   - CloudWatch monitoring
   - Full data persistence

2. **Secondary Region**
   - Standby infrastructure
   - Cross-region replication
   - Automated failover mechanisms

3. **Global Components**
   - Route 53 for DNS failover
   - CloudFront for content distribution
   - IAM for cross-region authentication

## Adding to Git
These diagrams are maintained in multiple formats for optimal Git compatibility:
- XML source files (editable in draw.io)
- PNG images (visible directly in Git repos)

To update:
1. Edit the XML file in draw.io
2. Export as PNG
3. Commit all files together

For detailed guidance on managing diagrams in Git, see our [Git Visualization Guide](git_visualization_guide.md).
