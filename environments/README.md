# Multi-Environment Architecture

This directory contains the Terraform configuration for multiple environments:

- **dev**: Development environment with scaled-down resources
- **prod**: Production environment with full-scale resources
- **dr**: Disaster Recovery environment running in a different region

## Environment Structure

Each environment directory contains:

- `main.tf`: The main Terraform configuration file that references the base module
- `variables.tf`: Environment-specific variable declarations
- `outputs.tf`: Environment-specific outputs
- `*.tfvars`: Environment-specific variable values

## Base Module

The `base` directory contains shared code used by all environments, following the DRY (Don't Repeat Yourself) principle.

## DR Environment

The DR environment has additional modules:

- `dr_specific`: Contains configuration for spot instances and the Lambda function that switches to on-demand instances during failover
- `dr_testing`: Contains the Lambda function for monthly DR testing
- `route53_failover`: Contains the Route53 failover configuration

## Usage

To deploy an environment, navigate to its directory and run:

```bash
# Initialize Terraform
terraform init

# Apply configuration using environment-specific variables
terraform apply -var-file=<environment>.tfvars
```

For example, to deploy the dev environment:

```bash
cd environments/dev
terraform init
terraform apply -var-file=dev.tfvars
```

## DR Testing and Failover

The DR environment is configured to:

1. Run on spot instances for cost savings during normal operation
2. Automatically switch to on-demand instances when Route53 triggers failover
3. Run monthly tests to verify failover functionality
4. Send email notifications for test results and actual failover events

## Security Note

The `.tfvars` files in this repository contain placeholder passwords. In a production environment:

1. Never commit sensitive values to version control
2. Use AWS Secrets Manager or HashiCorp Vault to securely store and retrieve secrets
3. Use terraform.tfvars (which should be in .gitignore) for sensitive values