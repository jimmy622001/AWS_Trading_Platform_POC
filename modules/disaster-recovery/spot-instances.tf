# Lambda functions for managing spot instances

# First function: Convert spot instances to on-demand instances
resource "aws_lambda_function" "spot_to_ondemand" {
  function_name = "${var.project_name}-spot-to-ondemand"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 300

  filename         = "${path.module}/spot_to_ondemand.zip"
  source_code_hash = data.archive_file.spot_to_ondemand.output_base64sha256

  environment {
    variables = {
      DR_REGION          = var.dr_region
      CLUSTER_NAME       = "${var.project_name}-dr-eks"
      DR_NODE_GROUP_NAME = "${var.project_name}-dr-nodes"
    }
  }
}

data "archive_file" "spot_to_ondemand" {
  type        = "zip"
  output_path = "${path.module}/spot_to_ondemand.zip"

  source {
    content  = <<-EOT
    const AWS = require('aws-sdk');
    
    exports.handler = async (event, context) => {
      console.log('Event:', JSON.stringify(event, null, 2));
      
      const drRegion = process.env.DR_REGION;
      const clusterName = process.env.CLUSTER_NAME;
      const drNodeGroupName = process.env.DR_NODE_GROUP_NAME;
      
      try {
        // Initialize EKS client for DR region
        const drEks = new AWS.EKS({ region: drRegion });
        
        // Get current configuration
        const nodeGroupDesc = await drEks.describeNodegroup({
          clusterName,
          nodegroupName: drNodeGroupName
        }).promise();
        
        console.log('Current node group config:', JSON.stringify(nodeGroupDesc, null, 2));
        
        // Change capacity type to ON_DEMAND
        await drEks.updateNodegroupConfig({
          clusterName,
          nodegroupName: drNodeGroupName,
          capacityType: 'ON_DEMAND',
          scalingConfig: {
            desiredSize: nodeGroupDesc.nodegroup.scalingConfig.desiredSize * 2, // Double capacity
            minSize: nodeGroupDesc.nodegroup.scalingConfig.minSize * 2,
            maxSize: nodeGroupDesc.nodegroup.scalingConfig.maxSize * 2
          }
        }).promise();
        
        console.log('Successfully converted spot instances to on-demand instances and increased capacity');
        
        return {
          statusCode: 200,
          body: 'Successfully converted to on-demand instances'
        };
      } catch (error) {
        console.error('Error converting to on-demand instances:', error);
        throw error;
      }
    };
    EOT
    filename = "index.js"
  }
}

# Second function: Revert to spot instances
resource "aws_lambda_function" "revert_to_spot" {
  function_name = "${var.project_name}-revert-to-spot"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 300

  filename         = "${path.module}/revert_to_spot.zip"
  source_code_hash = data.archive_file.revert_to_spot.output_base64sha256

  environment {
    variables = {
      DR_REGION          = var.dr_region
      CLUSTER_NAME       = "${var.project_name}-dr-eks"
      DR_NODE_GROUP_NAME = "${var.project_name}-dr-nodes"
    }
  }
}

data "archive_file" "revert_to_spot" {
  type        = "zip"
  output_path = "${path.module}/revert_to_spot.zip"

  source {
    content  = <<-EOT
    const AWS = require('aws-sdk');
    
    exports.handler = async (event, context) => {
      console.log('Event:', JSON.stringify(event, null, 2));
      
      const drRegion = process.env.DR_REGION;
      const clusterName = process.env.CLUSTER_NAME;
      const drNodeGroupName = process.env.DR_NODE_GROUP_NAME;
      
      try {
        // Initialize EKS client for DR region
        const drEks = new AWS.EKS({ region: drRegion });
        
        // Get current configuration
        const nodeGroupDesc = await drEks.describeNodegroup({
          clusterName,
          nodegroupName: drNodeGroupName
        }).promise();
        
        console.log('Current node group config:', JSON.stringify(nodeGroupDesc, null, 2));
        
        // Change capacity type back to SPOT and reduce capacity
        await drEks.updateNodegroupConfig({
          clusterName,
          nodegroupName: drNodeGroupName,
          capacityType: 'SPOT',
          scalingConfig: {
            desiredSize: Math.max(1, Math.floor(nodeGroupDesc.nodegroup.scalingConfig.desiredSize / 2)), // Halve capacity
            minSize: Math.max(1, Math.floor(nodeGroupDesc.nodegroup.scalingConfig.minSize / 2)),
            maxSize: Math.max(2, Math.floor(nodeGroupDesc.nodegroup.scalingConfig.maxSize / 2))
          }
        }).promise();
        
        console.log('Successfully reverted to spot instances and reduced capacity');
        
        return {
          statusCode: 200,
          body: 'Successfully reverted to spot instances'
        };
      } catch (error) {
        console.error('Error reverting to spot instances:', error);
        throw error;
      }
    };
    EOT
    filename = "index.js"
  }
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "spot_to_ondemand" {
  name              = "/aws/lambda/${aws_lambda_function.spot_to_ondemand.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "revert_to_spot" {
  name              = "/aws/lambda/${aws_lambda_function.revert_to_spot.function_name}"
  retention_in_days = 30
}

# EventBridge Rules for triggering these functions
resource "aws_cloudwatch_event_rule" "dr_alert_high_severity" {
  name        = "${var.project_name}-dr-high-severity-alert"
  description = "Triggered when a high severity alert is received"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"],
    "detail-type" = ["CloudWatch Alarm State Change"],
    detail = {
      state = {
        value = ["ALARM"]
      },
      alarmName = [{
        prefix = "${var.project_name}-primary"
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_spot_to_ondemand" {
  rule      = aws_cloudwatch_event_rule.dr_alert_high_severity.name
  target_id = "TriggerSpotToOndemand"
  arn       = aws_lambda_function.spot_to_ondemand.arn
}

resource "aws_cloudwatch_event_rule" "dr_alert_resolved" {
  name        = "${var.project_name}-dr-alert-resolved"
  description = "Triggered when a high severity alert is resolved"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"],
    "detail-type" = ["CloudWatch Alarm State Change"],
    detail = {
      state = {
        value = ["OK"]
      },
      alarmName = [{
        prefix = "${var.project_name}-primary"
      }],
      previousState = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_revert_to_spot" {
  rule      = aws_cloudwatch_event_rule.dr_alert_resolved.name
  target_id = "TriggerRevertToSpot"
  arn       = aws_lambda_function.revert_to_spot.arn
}

# Permissions for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_spot_to_ondemand" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spot_to_ondemand.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_alert_high_severity.arn
}

resource "aws_lambda_permission" "allow_eventbridge_revert_to_spot" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.revert_to_spot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_alert_resolved.arn
}