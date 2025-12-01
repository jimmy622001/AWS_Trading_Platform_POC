# AWS Trading Platform - High Availability & Disaster Recovery

## 🚀 Next-Generation Trading Infrastructure

A production-ready, cloud-native trading platform built on AWS with enterprise-grade disaster recovery capabilities. This solution combines ultra-low latency architecture with automated cross-region failover to ensure maximum uptime and data protection for mission-critical trading operations.

## 🌟 Key Features

### 🔄 Multi-Region High Availability
- **Active-Passive Architecture** with automated failover between regions
- **Pilot Light DR** - Minimal footprint in standby with instant scale-up capability
- **Cross-Region Data Replication** for RDS, DynamoDB, and S3

### ⚡ Ultra-Low Latency Trading
- Sub-millisecond order processing with enhanced networking (SR-IOV, ENA)
- Optimized EKS cluster with managed node groups for consistent performance
- Direct VPC connectivity with Transit Gateway and IPSec VPN

### 🛡️ Enterprise Security
- End-to-end encryption with AWS KMS
- VPC isolation and network segmentation
- IAM roles and policies with least privilege access
- Automated security patching and compliance monitoring

### 📊 Real-time Monitoring & Analytics
- Comprehensive observability with Prometheus and Grafana
- CloudWatch metrics and alarms for all critical components
- Centralized logging with CloudWatch Logs

## 🚨 Disaster Recovery Strategy

### 🔄 Automated Failover Process
1. **Detection**: Route 53 health checks monitor primary region health
2. **Notification**: SNS alerts trigger Lambda functions
3. **Scale-Up**: DR environment automatically scales to match primary region capacity
4. **Traffic Shift**: DNS failover to DR region endpoints
5. **Verification**: Automated validation of DR environment readiness

### ⏱️ Recovery Time Objective (RTO) & Recovery Point Objective (RPO)
- **RTO**: < 15 minutes (automated failover)
- **RPO**: < 5 minutes (data replication lag)

### 🔄 Failback Process
1. **Stabilization**: Primary region recovery and validation
2. **Data Sync**: Reverse replication from DR to primary
3. **Traffic Shift**: Gradual traffic migration back to primary
4. **Scale-Down**: Automatic reduction of DR environment to pilot light

## 🏗️ Architecture Overview

```mermaid
graph TD
    subgraph Primary Region [Primary Region - us-east-1]
        A[API Gateway] --> B[EKS Cluster]
        B --> C[RDS Multi-AZ]
        B --> D[DynamoDB]
        B --> E[S3]
    end
    
    subgraph DR Region [Disaster Recovery - us-west-2]
        F[EKS Pilot Light] --> G[RDS Read Replica]
        F --> H[DynamoDB Global Table]
        F --> I[S3 Cross-Region Replication]
    end
    
    J[Route 53] -->|Primary| A
    J -->|Failover| F
    
    C -.->|Async Replication. G
    D <-->|Global Table| H
    E -.->|Replication. I
```

## 🛠️ Getting Started

For detailed deployment and usage instructions, please refer to the [USAGE.md](USAGE.md) documentation. The project follows specific deployment best practices outlined in the "Deployment Strategy" section below.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
- **Automatic Scale Down**: Returns to pilot light mode when failing back to primary
- **Cross-Region Replication**: Automated data replication between primary and DR regions
- **Automated Failover**: Route 53 health checks and Lambda functions for automated failover
- **Recovery Objectives**: 
  - RTO: 5-15 minutes (automated scaling)
  - RPO: ~15 minutes (data replication lag)
- **Data Replication**: RDS read replicas, S3 CRR, DynamoDB global tables
- **Automated Testing**: Regular DR drills using automated testing scripts

### How Automatic Scaling Works

1. **Failover Detection**:
   - Route 53 health checks detect primary region failure
   - EventBridge triggers the scaling Lambda function
   - Lambda scales up the DR environment to match primary's configuration

2. **Scaling Process**:
   - Retrieves primary EKS node group configuration
   - Updates DR node group to match:
     - Instance types
     - Desired/min/max node counts
     - Other scaling parameters

3. **Failback Process**:
   - When primary region recovers
   - EventBridge detects health restoration
   - Lambda scales down DR to pilot light mode (1 t3.small node)

4. **Monitoring & Alerts**:
   - CloudWatch metrics track scaling events
   - SNS notifications for all state changes
   - Logs all scaling operations for audit

### Manual Testing

```bash
# Test failover (scale up)
aws lambda invoke \
  --function-name ${var.project_name}-sync-cluster-sizes \
  --payload '{"action": "failover"}' \
  response.json

# Test failback (scale down)
aws lambda invoke \
  --function-name ${var.project_name}-sync-cluster-sizes \
  --payload '{"action": "failback"}' \
  response.json
```

See the [Multi-Region DR Strategy](docs/disaster-recovery/multi-region-dr-strategy.md) document for detailed implementation.

## EKS Auto-Scaling Configuration

The EKS cluster is configured with automatic scaling capabilities:

### Cluster Autoscaler
- Automatically scales worker nodes based on pod resource requirements
- Scales from 1 to 10 nodes based on demand
- Uses OIDC provider for secure service account authentication

### Node Group Configuration
- **Instance Type**: t3.medium
- **Capacity Type**: On-Demand
- **Min Size**: 1 node
- **Max Size**: 10 nodes
- **Desired Size**: 2 nodes

### EKS Addons
- **VPC CNI**: Advanced networking for pods
- **CoreDNS**: DNS resolution within the cluster
- **Kube-proxy**: Network proxy for Kubernetes services

```bash
# Deploy Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Annotate the deployment
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

# Edit deployment to add cluster name
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```

## Cleanup

```bash
terraform destroy
```

## Security Scanning Tools

This project includes multiple security scanning tools to ensure infrastructure code quality and security:

### Implemented Tools

- **Checkov**: Scans for cloud misconfigurations and security issues
- **TFLint**: Validates Terraform code quality and AWS best practices
- **KICS**: Finds security vulnerabilities and compliance issues
- **Terrascan**: Policy-as-code security scanner
- **CloudFormation Guard**: Policy-as-code validation with custom rules

### Using the Security Tools

```bash
# Run security scans locally
./scripts/security-scan.sh

# Run CloudFormation Guard validation
.\guard-validate.ps1

# Set up pre-commit hooks
   pre-commit install

### CloudFormation Guard Integration

CloudFormation Guard provides additional policy validation with custom organizational rules:

- **Custom Rules**: Organization-specific security policies in `.cfn-guard/rules.guard`
- **Policy as Code**: Version-controlled security policies
- **Compliance Validation**: Structured validation output for audit trails
- **Pre-deployment Checks**: Catch policy violations before infrastructure deployment

```powershell
# Validate infrastructure against custom policies
.\guard-validate.ps1
```

**Guard Rules Include:**
- S3 bucket public access blocking
- KMS key rotation enforcement
- ECS container security (non-root users)
- ALB security headers validation
- CloudWatch logs encryption requirements

All security scans run automatically in CI/CD pipelines.

## Deployment Strategy

### Environment Structure

The project is structured with these environments:

1. **Development (`environments/dev/`)**: For development and testing
2. **Production with DR (`environments/prod-with-dr/`)**: Combined production and disaster recovery deployment

### Recommended Deployment Approach

#### For New Deployments

We recommend using the `prod-with-dr` combined environment for all new deployments. This ensures that:

- Production and DR are always deployed together
- Configuration stays synchronized between environments
- DR is always available and properly configured for failover
- No risk of configuration drift between prod and DR

```bash
cd environments/prod-with-dr
terraform init
terraform apply
```

### Variable Management

All variables are defined in each environment's `terraform.tfvars` file:

- `environments/dev/terraform.tfvars` - Development variables
- `environments/prod-with-dr/terraform.tfvars` - Production and DR variables

This approach ensures:
- **No Prompts**: All variables have values defined in terraform.tfvars
- **Automatic Loading**: terraform.tfvars is automatically loaded without flags
- **Environment Isolation**: Each environment has its own complete set of values

## Documentation

Comprehensive documentation is available in the `docs/` folder with detailed guides for each component:

### Architecture
- [Detailed Architecture Components](docs/architecture/detailed-components.md) - Complete infrastructure breakdown
- [Multi-Region DR Strategy](docs/disaster-recovery/multi-region-dr-strategy.md) - Cross-region disaster recovery implementation

### Operations
- [Trading System Exercises](docs/operations/trading-exercises.md) - Learning exercises and advanced implementation paths
- [Troubleshooting Guide](docs/operations/troubleshooting.md) - Common issues and solutions
- [Security Best Practices](docs/operations/security-best-practices.md) - Comprehensive security implementation details

### Deployment
- [Rancher Kubernetes Management](docs/deployment/rancher-management.md) - Complete Kubernetes management guide

### Security
- [Terraform Security Tools Overview](docs/security/terraform-security-tools.md) - Security scanning tools documentation
- [Security Tools Installation Guide](docs/security/installation-guide.md) - Setup instructions for security tools

## Architecture Diagrams

### Infrastructure Overview
![AWS Kinesis Infrastructure Diagram](docs/infrastructure_diagram/aws_kinesis_infrastructure.png)

### System Layout
![Trading Architecture Layout.png](docs/images/Trading%20Architecture%20Layout.png)
![AWS Kinesis Layout](docs/images/aws_kinesis_layout.png)

For interactive diagrams, see the [infrastructure diagram documentation](docs/infrastructure_diagram/README.md) or open the [draw.io XML file](docs/infrastructure_diagram/aws_kinesis_infrastructure.drawio.xml) in [draw.io](https://app.diagrams.net).
