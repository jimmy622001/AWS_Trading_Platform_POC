# Production with DR Environment

This environment deploys both the production infrastructure and the disaster recovery (DR) infrastructure **simultaneously**. This approach ensures that:

1. The DR environment is always created alongside production
2. Both environments stay in sync with each other
3. The DR configuration is always ready for failover if needed

## Architecture

The deployment creates:

- **Production Region Infrastructure**: Full deployment of the trading platform in the primary region
- **DR Region Infrastructure**: Equivalent infrastructure in a separate AWS region
- **Failover Mechanism**: Route53 health checks and DNS records for automatic failover
- **DR-specific Resources**: Lambda functions for managing DR testing and failover processes

## Usage

### Deployment

```bash
# Initialize Terraform
terraform init

# Preview the deployment
terraform plan

# Deploy both production and DR environments
terraform apply
```

All required variables are defined in `terraform.tfvars`, so no prompts will appear during the terraform commands.

### Testing DR Capabilities

The DR environment includes automated testing capabilities that can be triggered via the AWS Console or CLI:

```bash
# Manually trigger a DR test
aws lambda invoke --function-name trading-platform-dr-test --region eu-west-1 output.json
```

### Failover Process

In case of a production outage:

1. **Automatic Failover**: Route53 will detect the outage via health checks and automatically route traffic to the DR environment
2. **Manual Failover**: You can also manually trigger failover using:

```bash
# Trigger manual failover to DR
aws lambda invoke --function-name trading-platform-dr-failover --region eu-west-1 output.json
```

## Important Notes

- Both environments use the same passwords and configuration values
- The DR environment uses spot instances by default for cost optimization
- During an actual failover event, Lambda functions will automatically convert spot instances to on-demand for better stability
- After the primary region is restored, traffic will automatically route back based on health checks

## Customization

Modify `terraform.tfvars` to customize:

- AWS regions for production and DR
- Infrastructure sizing (different between prod and DR)
- Network configuration
- Security parameters

## Monitoring

Both environments are fully monitored. To view DR readiness:

1. Check the Route53 health check status in the AWS Console
2. Review CloudWatch metrics for both regions
3. Examine the monthly DR test reports stored in S3