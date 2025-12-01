# AWS Trading Platform - Environment Structure

## Environment-Based Terraform Structure

This project uses an environment-based Terraform structure to manage multiple deployments for different purposes (production, development, disaster recovery). This approach provides better isolation and prevents unintended changes across environments.

## Project Structure

```
AWS_Trading_Platform_POC/
├── environments/            # Environment-specific configurations
│   ├── base/               # Base module with shared infrastructure
│   ├── prod/               # Production environment
│   ├── dev/                # Development environment
│   └── dr/                 # Disaster Recovery environment
├── modules/                # Shared modules
│   ├── cicd/
│   ├── containers/
│   ├── disaster-recovery/
│   ├── event-systems/
│   ├── monitoring/
│   ├── networking/
│   ├── observability/
│   ├── secrets/
│   ├── security/
│   └── serverless/
├── docs/                   # Documentation
└── scripts/                # Utility scripts
```

## Key Components

1. **Base Module**: Contains common infrastructure code that all environments inherit
   - Located at `environments/base/`
   - Includes provider configuration, data sources, and module calls

2. **Environment-Specific Configurations**:
   - **Production**: `environments/prod/`
   - **Development**: `environments/dev/`
   - **Disaster Recovery**: `environments/dr/`

3. **Shared Modules**: Reusable infrastructure components in the `modules/` directory

## Variable Management

Each environment has its own variable files:
- `environments/prod/variables.tf` and `environments/prod/prod.tfvars`
- `environments/dev/variables.tf` and `environments/dev/dev.tfvars`
- `environments/dr/variables.tf` and `environments/dr/dr.tfvars`

The root-level variable files (`variables.tf`, `terraform.tfvars`) are now kept empty for backward compatibility.

## State Management

Each environment manages its own state:
- Production: `terraform.prod.tfstate`
- Development: `terraform.dev.tfstate`
- Disaster Recovery: `terraform.dr.tfstate`

In a real-world scenario, you would configure remote backends (like S3 with DynamoDB locking) for each environment.

## Deployment Instructions

To deploy an environment, navigate to its directory and run Terraform commands:

```bash
# Production environment
cd environments/prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

# Development environment
cd environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Disaster Recovery environment
cd environments/dr
terraform init
terraform plan -var-file=dr.tfvars
terraform apply -var-file=dr.tfvars
```

## Adding New Environments

To add a new environment:

1. Create a new directory under `environments/`
2. Copy the structure from an existing environment
3. Update variables and configurations for your new environment
4. Initialize and apply the Terraform configuration

## Benefits of this Structure

1. **Isolation**: Changes to one environment don't affect others
2. **Customization**: Each environment can have different configurations
3. **State Separation**: Each environment has its own state file
4. **Safety**: Prevents accidental changes to production
5. **Clarity**: Clear separation of environment-specific code