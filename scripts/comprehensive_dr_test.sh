#!/bin/bash
# Comprehensive DR Testing Script

# Set variables
PROJECT_NAME=$(terraform output -raw project_name)
PRIMARY_REGION=$(terraform output -raw aws_region)
DR_REGION=$(terraform output -raw disaster_recovery_dr_region)
APP_DOMAIN=$(terraform output -raw application_domain)
LAMBDA_FAILOVER_FUNCTION="${PROJECT_NAME}-dr-failover"
LAMBDA_SPOT_TO_ONDEMAND="${PROJECT_NAME}-dr-spot-to-ondemand"
LAMBDA_REVERT_TO_SPOT="${PROJECT_NAME}-dr-revert-to-spot"

# Print header
echo "=================================================================="
echo "| COMPREHENSIVE DISASTER RECOVERY TEST                           |"
echo "=================================================================="
echo "Project: $PROJECT_NAME"
echo "Primary region: $PRIMARY_REGION"
echo "DR region: $DR_REGION"
echo "Application domain: $APP_DOMAIN"
echo "------------------------------------------------------------------"

# Function to print section headers
print_section() {
  echo ""
  echo "=================================================================="
  echo "| $1"
  echo "=================================================================="
}

# Function to print step headers
print_step() {
  echo ""
  echo "------------------------------------------------------------------"
  echo "STEP: $1"
  echo "------------------------------------------------------------------"
}

# Function to check if a command was successful
check_status() {
  if [ $? -eq 0 ]; then
    echo "✅ $1"
  else
    echo "❌ $1"
    echo "Error occurred. Check logs for details."
    if [ "$2" == "fatal" ]; then
      echo "Exiting test due to fatal error."
      exit 1
    fi
  fi
}

# Function to wait with progress indicator
wait_with_progress() {
  local seconds=$1
  local message=$2
  echo -n "$message "
  for (( i=0; i<$seconds; i++ )); do
    echo -n "."
    sleep 1
  done
  echo " done!"
}

print_section "PRE-TEST ENVIRONMENT CHECK"

print_step "Checking primary region infrastructure"
PRIMARY_ALB_STATUS=$(aws --region $PRIMARY_REGION elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, '${APP_DOMAIN}')].State.Code" --output text)
echo "Primary ALB status: $PRIMARY_ALB_STATUS"

print_step "Checking DR region infrastructure"
DR_ALB_STATUS=$(aws --region $DR_REGION elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, '${PROJECT_NAME}')].State.Code" --output text)
echo "DR ALB status: $DR_ALB_STATUS"

print_step "Checking Route53 health checks"
PRIMARY_HEALTH_CHECK=$(aws route53 list-health-checks --query "HealthChecks[?contains(HealthCheckConfig.FullyQualifiedDomainName, '${PRIMARY_REGION}')].Id" --output text)
echo "Primary health check ID: $PRIMARY_HEALTH_CHECK"
PRIMARY_HEALTH_STATUS=$(aws route53 get-health-check-status --health-check-id $PRIMARY_HEALTH_CHECK --query "HealthCheckObservations[0].StatusReport.Status" --output text)
echo "Primary health status: $PRIMARY_HEALTH_STATUS"

print_step "Checking DNS configuration"
DNS_BEFORE=$(dig +short $APP_DOMAIN)
echo "Current DNS points to: $DNS_BEFORE"

print_step "Checking EC2 instances in DR region"
echo "Spot instances in DR region before test:"
aws --region $DR_REGION ec2 describe-instances --filters "Name=tag:Environment,Values=dr" "Name=instance-lifecycle,Values=spot" --query "Reservations[].Instances[].{InstanceId:InstanceId,Type:InstanceType,State:State.Name,SpotType:InstanceLifecycle}" --output table

print_section "SIMULATING FAILOVER"

print_step "Invoking failover Lambda function"
aws lambda invoke \
  --region $PRIMARY_REGION \
  --function-name $LAMBDA_FAILOVER_FUNCTION \
  --payload '{"TestFailover": true, "ForceFailover": true}' \
  /tmp/lambda_output.json
check_status "Failover Lambda invocation" "fatal"

print_step "Invoking spot to on-demand Lambda function"
aws lambda invoke \
  --region $DR_REGION \
  --function-name $LAMBDA_SPOT_TO_ONDEMAND \
  --payload '{"TestFailover": true}' \
  /tmp/lambda_output.json
check_status "Spot to on-demand Lambda invocation" "fatal"

wait_with_progress 30 "Waiting for instance changes to begin"

print_step "Monitoring instance replacement"
echo "Checking for instance refresh in Auto Scaling Group:"
ASG_NAME="${PROJECT_NAME}-dr-spot-asg"
ASG_REFRESH=$(aws --region $DR_REGION autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME --query "InstanceRefreshes[0].{Status:Status,PercentComplete:PercentComplete}" --output json)
echo "$ASG_REFRESH"

wait_with_progress 120 "Waiting for DNS propagation and instance refresh"

print_step "Checking EC2 instances in DR region after failover"
echo "Instances in DR region after failover:"
aws --region $DR_REGION ec2 describe-instances --filters "Name=tag:Environment,Values=dr" --query "Reservations[].Instances[].{InstanceId:InstanceId,Type:InstanceType,State:State.Name,SpotType:InstanceLifecycle}" --output table

print_step "Checking DNS after failover"
DNS_AFTER=$(dig +short $APP_DOMAIN)
echo "DNS now points to: $DNS_AFTER"

print_step "Testing application health in DR region"
DR_APP_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" https://$APP_DOMAIN/health)
echo "Application health check status: $DR_APP_HEALTH"

print_section "SIMULATING PRIMARY REGION RECOVERY"

print_step "Invoking revert to spot Lambda function"
aws lambda invoke \
  --region $DR_REGION \
  --function-name $LAMBDA_REVERT_TO_SPOT \
  --payload '{"TestRecovery": true}' \
  /tmp/lambda_output.json
check_status "Revert to spot Lambda invocation"

wait_with_progress 120 "Waiting for instance changes during recovery"

print_step "Checking EC2 instances in DR region after recovery"
echo "Instances in DR region after recovery:"
aws --region $DR_REGION ec2 describe-instances --filters "Name=tag:Environment,Values=dr" --query "Reservations[].Instances[].{InstanceId:InstanceId,Type:InstanceType,State:State.Name,SpotType:InstanceLifecycle}" --output table

print_section "TEST RESULTS SUMMARY"

echo "Pre-failover DNS: $DNS_BEFORE"
echo "Post-failover DNS: $DNS_AFTER"
echo "Application health: $DR_APP_HEALTH"

# Check if ASG instance types changed from spot to on-demand
SPOT_COUNT_AFTER=$(aws --region $DR_REGION ec2 describe-instances --filters "Name=tag:Environment,Values=dr" "Name=instance-lifecycle,Values=spot" --query "Reservations[].Instances[].InstanceId" --output text | wc -w)
ONDEMAND_COUNT_AFTER=$(aws --region $DR_REGION ec2 describe-instances --filters "Name=tag:Environment,Values=dr" --query "Reservations[].Instances[?!contains(InstanceLifecycle, 'spot')].InstanceId" --output text | wc -w)

echo "Spot instances after test: $SPOT_COUNT_AFTER"
echo "On-demand instances after test: $ONDEMAND_COUNT_AFTER"

if [ "$DNS_BEFORE" != "$DNS_AFTER" ] && [ "$DR_APP_HEALTH" == "200" ] && [ $ONDEMAND_COUNT_AFTER -gt 0 ]; then
  echo "✅ DR FAILOVER TEST SUCCESSFUL"
  echo "The test successfully demonstrated:"
  echo "1. DNS failover to DR region"
  echo "2. Spot to on-demand instance conversion"
  echo "3. Application availability in DR region"
  echo "4. Recovery process initiation"
else
  echo "❌ DR FAILOVER TEST FAILED"
  echo "See logs above for details on what went wrong"
fi

echo "=================================================================="