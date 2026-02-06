# Development Environment

## Configuration Files

- `main.tf`: Main Terraform configuration that references the base module
- `variables.tf`: Variable declarations (no default values)
- `terraform.tfvars`: Variable values that will be automatically loaded by Terraform
- `outputs.tf`: Output values from this environment

## Running Terraform Commands

With the `terraform.tfvars` file in place, variables will be automatically loaded without needing to specify `-var-file`. Simply run:

```bash
terraform plan
terraform apply
```

## Common Issues

If you're being prompted for variable values:
1. Make sure you're running commands from the `environments/dev` directory
2. Verify that all variables are properly defined in `terraform.tfvars`