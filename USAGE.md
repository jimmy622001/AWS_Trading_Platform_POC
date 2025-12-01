# AWS Trading Platform - Usage Guide

This document provides detailed usage instructions for the AWS Trading Platform infrastructure. For high-level architecture and features, refer to the [README.md](README.md) file.

## 📋 Prerequisites

- **AWS Account** with appropriate IAM permissions
- **AWS CLI** configured with credentials
- **Terraform** >= 1.0
- **kubectl** for Kubernetes cluster management
- **jq** for JSON processing (recommended)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd AWS_Trading_Platform_POC
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Configure Variables

```bash
# Choose environment directory
cd environments/prod-with-dr

# Review and edit terraform.tfvars with your environment settings
vim terraform.tfvars
```

Ensure all required variables are set in the terraform.tfvars file to avoid being prompted during deployment.

### 4. Deploy Infrastructure

```bash
# Review changes
terraform plan -out=tfplan

# Apply changes (takes 20-30 minutes)
terraform apply "tfplan"
```

### Deploying Different Environments

The project supports these deployment environments:

1. **Development Environment**
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Production with Disaster Recovery**
   ```bash
   cd environments/prod-with-dr
   terraform init
   terraform plan
   terraform apply
   ```

We recommend using the combined prod-with-dr environment to ensure proper configuration synchronization between production and DR regions.

## 🔍 Accessing the Cluster

### Configure kubectl

```bash
aws eks update-kubeconfig \
  --region $(terraform output -raw region) \
  --name $(terraform output -raw cluster_name)
```

## 🛠️ Disaster Recovery Operations

### Testing Failover

1. **Initiate Failover Test**
   ```bash
   # Manually failover RDS (if applicable)
   aws rds failover-db-cluster \
     --db-cluster-identifier $(terraform output -raw db_cluster_identifier)
   
   # Verify DR environment scaling
   aws eks describe-nodegroup \
     --cluster-name $(terraform output -raw dr_cluster_name) \
     --nodegroup-name $(terraform output -raw dr_nodegroup_name) \
     --region $(terraform output -raw dr_region)
   ```

2. **Verify DNS Failover**
   ```bash
   dig +short $(terraform output -raw app_domain) CNAME
   ```

### Failback Procedure

1. **Restore Primary Region**
   ```bash
   # Restore any affected services
   # Verify data consistency
   ```

2. **Initiate Failback**
   ```bash
   # Update Route 53 to point back to primary
   # Monitor traffic shift in CloudWatch
   ```

3. **Scale Down DR**
   ```automatically handled by Lambda function
   # Verify DR environment scales down
   ```

## 🔄 Maintenance

### Updating the Cluster

```bash
# Make changes to Terraform files
terraform plan -out=tfplan
terraform apply "tfplan"

# Update Kubernetes deployments
kubectl apply -f k8s/
```

### Monitoring

- **Kubernetes Dashboard**: `kubectl proxy`
- **Prometheus/Grafana**: Access via port-forward or Ingress
- **CloudWatch**: View logs and metrics in AWS Console

## 🧪 Testing DR Readiness

### Automated Testing

```bash
# Run DR test suite
./scripts/test-dr-failover.sh

# View test results
kubectl logs -n monitoring dr-test-pod
```

### Manual Verification

1. Check DR environment status:
   ```bash
   kubectl get nodes --context=dr-context
   kubectl get pods --all-namespaces --context=dr-context
   ```

2. Verify data replication:
   ```bash
   # Check RDS replication lag
   aws rds describe-db-instances \
     --db-instance-identifier $(terraform output -raw dr_db_identifier) \
     --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'
   ```

## 🧹 Cleanup

To destroy all resources (use with caution):

```bash
# First, delete Kubernetes resources
kubectl delete all --all --all-namespaces

# Then destroy Terraform resources
terraform destroy
```

> **Warning**: This will permanently delete all resources. Ensure you have backups before proceeding.

## 📚 Additional Resources

- [AWS Disaster Recovery Documentation](https://aws.amazon.com/disaster-recovery/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

## Disaster Recovery Operations

### Manual Failover Testing

1. **Test Failover (Scale Up DR)**
   ```bash
   aws lambda invoke \
     --function-name ${var.project_name}-sync-cluster-sizes \
     --payload '{"action": "failover"}' \
     response.json
   ```

2. **Test Failback (Scale Down DR)**
   ```bash
   aws lambda invoke \
     --function-name ${var.project_name}-sync-cluster-sizes \
     --payload '{"action": "failback"}' \
     response.json
   ```

### Monitoring DR Events

1. **View Lambda Logs**
   ```bash
   aws logs tail /aws/lambda/${var.project_name}-sync-cluster-sizes --follow
   ```

2. **Check EKS Node Status**
   ```bash
   aws eks describe-nodegroup \
     --cluster-name ${var.project_name}-eks \
     --nodegroup-name ${var.project_name}-dr-nodes \
     --region ${var.dr_region}
   ```

## Maintenance

### Upgrading the Cluster

1. **Update EKS Control Plane**
   ```bash
   terraform apply -target=aws_eks_cluster.dr -var='eks_version=1.28'
   ```

2. **Update Node Groups**
   ```bash
   terraform apply -target=aws_eks_node_group.dr
   ```

### Backup and Restore

1. **Create Manual RDS Snapshot**
   ```bash
   aws rds create-db-snapshot \
     --db-instance-identifier ${var.project_name}-database \
     --db-snapshot-identifier manual-$(date +%Y%m%d-%H%M%S)
   ```

2. **Restore from Snapshot**
   ```bash
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier ${var.project_name}-restored \
     --db-snapshot-identifier <snapshot-identifier>
   ```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Verify IAM roles and policies
   - Check service-linked roles
   - Ensure proper trust relationships

2. **Networking Issues**
   - Verify VPC peering
   - Check security group rules
   - Validate route tables

3. **EKS Node Issues**
   ```bash
   # Check node status
   kubectl get nodes -o wide

   # Check node events
   kubectl describe node <node-name>

   # Check node logs
   kubectl logs -n kube-system <pod-name>
   ```

4. **DR Environment Failing When Deployed Separately**
   - Error: `Unable to find remote state` or `couldn't find resource`
   - Solution: Always use the combined `prod-with-dr` environment
   - Alternative: Deploy production first, then DR

5. **Missing Variables During Plan/Apply**
   - Ensure all required variables are in your `terraform.tfvars` file
   - Run terraform from the correct environment directory
   - If needed, explicitly reference the tfvars file with `-var-file=terraform.tfvars`

## Cleanup

### Destroy Resources

```bash
# Destroy DR resources first
terraform destroy -target=module.disaster_recovery

# Destroy all resources
terraform destroy
```

> **Warning**: This will permanently delete all resources. Ensure you have backups of all important data.

## Support

For additional help, please contact:
- **Email**: support@example.com
- **Slack**: #aws-trading-platform
- **Documentation**: [Internal Wiki](https://wiki.example.com/aws-trading-platform)
