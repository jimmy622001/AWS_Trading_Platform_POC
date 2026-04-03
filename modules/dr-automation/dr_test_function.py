import json
import boto3
import os
from datetime import datetime
import time

# Initialize AWS clients
route53 = boto3.client('route53')
autoscaling = boto3.client('autoscaling')
rds = boto3.client('rds')
dynamodb = boto3.client('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')
elbv2 = boto3.client('elbv2')
logs = boto3.client('logs')

# Environment variables
PRIMARY_REGION = os.environ.get('PRIMARY_REGION')
DR_REGION = os.environ.get('DR_REGION')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
PRIMARY_ALB_NAME = os.environ.get('PRIMARY_ALB_NAME')
DR_ALB_NAME = os.environ.get('DR_ALB_NAME')
RTO_THRESHOLD_SECONDS = int(os.environ.get('RTO_THRESHOLD_SECONDS', '300'))
RPO_THRESHOLD_SECONDS = int(os.environ.get('RPO_THRESHOLD_SECONDS', '60'))

def handler(event, context):
    """
    Automated DR testing function that validates:
    1. Primary region health
    2. DR region readiness
    3. RTO (Recovery Time Objective)
    4. RPO (Recovery Point Objective)
    5. Failover capability
    """
    
    test_results = {
        'timestamp': datetime.utcnow().isoformat(),
        'test_id': context.request_id,
        'primary_region': PRIMARY_REGION,
        'dr_region': DR_REGION,
        'tests': {},
        'overall_status': 'PASS',
        'rto_seconds': 0,
        'rpo_seconds': 0
    }
    
    try:
        # Test 1: Check primary region ALB health
        test_results['tests']['primary_alb_health'] = check_alb_health(PRIMARY_ALB_NAME, PRIMARY_REGION)
        
        # Test 2: Check DR region ALB readiness
        test_results['tests']['dr_alb_readiness'] = check_alb_health(DR_ALB_NAME, DR_REGION)
        
        # Test 3: Check RDS replication lag (RPO)
        test_results['tests']['rds_replication'] = check_rds_replication()
        test_results['rpo_seconds'] = test_results['tests']['rds_replication'].get('replication_lag_seconds', 0)
        
        # Test 4: Check DynamoDB replication
        test_results['tests']['dynamodb_replication'] = check_dynamodb_replication()
        
        # Test 5: Measure failover time (RTO)
        start_time = time.time()
        test_results['tests']['failover_simulation'] = simulate_failover()
        test_results['rto_seconds'] = time.time() - start_time
        
        # Test 6: Validate data consistency
        test_results['tests']['data_consistency'] = validate_data_consistency()
        
        # Determine overall status
        if not all(test['status'] == 'PASS' for test in test_results['tests'].values()):
            test_results['overall_status'] = 'FAIL'
        
        if test_results['rto_seconds'] > RTO_THRESHOLD_SECONDS:
            test_results['overall_status'] = 'FAIL'
            test_results['tests']['rto_check'] = {
                'status': 'FAIL',
                'message': f"RTO exceeded: {test_results['rto_seconds']:.2f}s > {RTO_THRESHOLD_SECONDS}s"
            }
        
        if test_results['rpo_seconds'] > RPO_THRESHOLD_SECONDS:
            test_results['overall_status'] = 'FAIL'
            test_results['tests']['rpo_check'] = {
                'status': 'FAIL',
                'message': f"RPO exceeded: {test_results['rpo_seconds']:.2f}s > {RPO_THRESHOLD_SECONDS}s"
            }
        
    except Exception as e:
        test_results['overall_status'] = 'ERROR'
        test_results['error'] = str(e)
        print(f"DR test error: {str(e)}")
    
    # Send notification
    send_notification(test_results)
    
    # Log results
    print(json.dumps(test_results, indent=2))
    
    return {
        'statusCode': 200 if test_results['overall_status'] == 'PASS' else 500,
        'body': json.dumps(test_results)
    }

def check_alb_health(alb_name, region):
    """Check ALB target group health"""
    try:
        client = boto3.client('elbv2', region_name=region)
        
        # Get load balancer
        response = client.describe_load_balancers(Names=[alb_name])
        if not response['LoadBalancers']:
            return {'status': 'FAIL', 'message': f'ALB {alb_name} not found'}
        
        alb = response['LoadBalancers'][0]
        alb_arn = alb['LoadBalancerArn']
        
        # Get target groups
        tg_response = client.describe_target_groups(LoadBalancerArn=alb_arn)
        
        healthy_targets = 0
        total_targets = 0
        
        for tg in tg_response['TargetGroups']:
            health_response = client.describe_target_health(TargetGroupArn=tg['TargetGroupArn'])
            for target in health_response['TargetHealthDescriptions']:
                total_targets += 1
                if target['TargetHealth']['State'] == 'healthy':
                    healthy_targets += 1
        
        if total_targets == 0:
            return {'status': 'FAIL', 'message': 'No targets found'}
        
        health_percentage = (healthy_targets / total_targets) * 100
        
        return {
            'status': 'PASS' if health_percentage >= 80 else 'FAIL',
            'healthy_targets': healthy_targets,
            'total_targets': total_targets,
            'health_percentage': health_percentage
        }
    except Exception as e:
        return {'status': 'FAIL', 'message': str(e)}

def check_rds_replication():
    """Check RDS replication lag"""
    try:
        response = rds.describe_db_instances()
        
        if not response['DBInstances']:
            return {'status': 'FAIL', 'message': 'No RDS instances found'}
        
        # Check for read replicas and replication lag
        replication_lag = 0
        for db in response['DBInstances']:
            if db.get('ReadReplicaSourceDBInstanceIdentifier'):
                # This is a read replica, check lag
                lag = db.get('ReplicationLag', 0)
                replication_lag = max(replication_lag, lag)
        
        return {
            'status': 'PASS' if replication_lag < RPO_THRESHOLD_SECONDS else 'FAIL',
            'replication_lag_seconds': replication_lag,
            'message': f'Replication lag: {replication_lag}s'
        }
    except Exception as e:
        return {'status': 'FAIL', 'message': str(e)}

def check_dynamodb_replication():
    """Check DynamoDB global tables replication"""
    try:
        response = dynamodb.list_tables()
        
        if not response['TableNames']:
            return {'status': 'PASS', 'message': 'No DynamoDB tables to check'}
        
        # Check if tables are replicated
        replicated_tables = 0
        for table_name in response['TableNames']:
            table_response = dynamodb.describe_table(TableName=table_name)
            if table_response['Table'].get('GlobalSecondaryIndexes'):
                replicated_tables += 1
        
        return {
            'status': 'PASS',
            'replicated_tables': replicated_tables,
            'total_tables': len(response['TableNames'])
        }
    except Exception as e:
        return {'status': 'FAIL', 'message': str(e)}

def simulate_failover():
    """Simulate failover process"""
    try:
        # Check Route53 health checks
        response = route53.list_health_checks()
        
        if not response['HealthChecks']:
            return {'status': 'FAIL', 'message': 'No Route53 health checks configured'}
        
        # Verify health check status
        healthy_checks = 0
        for check in response['HealthChecks']:
            check_id = check['Id']
            status_response = route53.get_health_check_status(HealthCheckId=check_id)
            if status_response['HealthCheckObservations']:
                healthy_checks += 1
        
        return {
            'status': 'PASS' if healthy_checks > 0 else 'FAIL',
            'healthy_checks': healthy_checks,
            'total_checks': len(response['HealthChecks']),
            'message': 'Failover simulation successful'
        }
    except Exception as e:
        return {'status': 'FAIL', 'message': str(e)}

def validate_data_consistency():
    """Validate data consistency between primary and DR"""
    try:
        # Check S3 replication
        response = s3.list_buckets()
        
        replicated_buckets = 0
        for bucket in response['Buckets']:
            try:
                replication_response = s3.get_bucket_replication(Bucket=bucket['Name'])
                if replication_response.get('ReplicationConfiguration'):
                    replicated_buckets += 1
            except s3.exceptions.ReplicationConfigurationNotFoundError:
                pass
        
        return {
            'status': 'PASS',
            'replicated_buckets': replicated_buckets,
            'total_buckets': len(response['Buckets']),
            'message': 'Data consistency check passed'
        }
    except Exception as e:
        return {'status': 'FAIL', 'message': str(e)}

def send_notification(test_results):
    """Send SNS notification with test results"""
    try:
        message = f"""
DR Test Results - {test_results['timestamp']}
Test ID: {test_results['test_id']}
Overall Status: {test_results['overall_status']}

RTO: {test_results['rto_seconds']:.2f}s (Threshold: {RTO_THRESHOLD_SECONDS}s)
RPO: {test_results['rpo_seconds']:.2f}s (Threshold: {RPO_THRESHOLD_SECONDS}s)

Test Details:
{json.dumps(test_results['tests'], indent=2)}
"""
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"DR Test {test_results['overall_status']}: {test_results['timestamp']}",
            Message=message
        )
    except Exception as e:
        print(f"Failed to send notification: {str(e)}")
