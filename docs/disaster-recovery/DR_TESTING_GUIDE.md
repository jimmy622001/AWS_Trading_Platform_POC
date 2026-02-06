# DR Testing Guide for AWS Trading Platform

## Overview
This guide explains the disaster recovery (DR) testing process for the AWS Trading Platform. The DR solution includes automatic failover using Route53, spot to on-demand instance conversion during failover, and scheduled monthly tests.

## DR Architecture

Our disaster recovery architecture has the following components:

1. **Route53 Failover**: Uses health checks to automatically route traffic from the primary region to the DR region when the primary becomes unhealthy.

2. **Spot to On-Demand Conversion**: During a failover, EC2 instances in the DR region are automatically converted from cost-effective spot instances to reliable on-demand instances.

3. **Automatic Recovery**: When the primary region becomes healthy again, the system automatically detects this and reverts the DR region instances back to spot instances.

4. **Monthly Testing**: Scheduled testing runs on the first weekend of each month to verify the DR capabilities.

## Manual Testing

To manually test the DR functionality, use the comprehensive DR test script:

```bash
# Navigate to the project root directory
cd /path/to/project

# Run the comprehensive test script
scripts/comprehensive_dr_test.sh
```

This script will:
1. Check the pre-test environment status
2. Simulate a failover to the DR region
3. Verify spot to on-demand instance conversion
4. Test application availability in the DR region
5. Simulate primary region recovery
6. Verify reversion to spot instances
7. Provide a detailed summary of the test results

## Scheduled Monthly Tests

The system is configured to run automatic DR tests on the first weekend of each month. This is defined in the `environments/dr/main.tf` file with the cron expression:

```
cron(0 0 ? * 7-1#1 *)
```

This schedule runs the test at midnight on the first Saturday or Sunday of each month.

The monthly test results are sent to the configured SNS topic, which delivers them to the email addresses specified in the configuration.

## DR Failover Process

During an actual DR event, the following occurs:

1. Route53 health checks detect that the primary region is unhealthy
2. Traffic is automatically routed to the DR region using Route53 failover routing policy
3. A CloudWatch alarm triggers the spot-to-ondemand Lambda function
4. EC2 instances in the DR region are converted from spot to on-demand instances
5. The system begins monitoring for primary region recovery

## Recovery Process

When the primary region recovers:

1. The primary-recovery-check Lambda function detects that the primary region is healthy
2. The revert-to-spot Lambda function is triggered
3. EC2 instances in the DR region are converted back to spot instances
4. Route53 automatically routes traffic back to the primary region

## Monitoring DR Status

You can monitor the DR status using the following methods:

1. **CloudWatch Metrics**: Monitor the Route53 health check status and failover events
2. **SNS Notifications**: Receive email alerts for failover events and test results
3. **CloudWatch Logs**: Review logs from the Lambda functions involved in the DR process

## Cost Considerations

The DR solution is designed to be cost-effective:
- DR region uses spot instances during normal operation
- Only converts to on-demand instances during actual failover events
- Automatically reverts to spot instances when the primary region is healthy
- Minimal resources are provisioned in the DR region during normal operation

## Troubleshooting

If you encounter issues during DR testing or actual failover:

1. Check the CloudWatch Logs for the relevant Lambda functions
2. Verify the Route53 health check status
3. Ensure the Auto Scaling Groups in the DR region are properly configured
4. Check SNS notifications for detailed error messages
5. Review the comprehensive_dr_test.sh script output for detailed diagnostics