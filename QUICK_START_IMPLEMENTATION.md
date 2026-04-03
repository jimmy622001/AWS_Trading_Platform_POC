# Quick Start: High-Impact Enhancements (Week 1-2)

## Overview
This guide prioritizes the 4 highest-impact enhancements that will immediately demonstrate AWS Solutions Architect expertise.

---

## 1. Deploy Application Load Balancer (ALB) - 2 Hours

### Why This Matters
- **Critical Gap**: No load balancing currently exists
- **Skill Demonstration**: Shows understanding of HA architecture
- **Business Impact**: Enables traffic distribution and health checks

### Implementation Steps

**A. Create ALB Module** (`modules/load-balancing/main.tf`)
```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for EKS
resource "aws_lb_target_group" "eks" {
  name        = "${var.project_name}-eks-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-eks-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks.arn
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}
```

**B. Update EKS Module** to register with ALB
- Add target group registration
- Configure health checks
- Add listener rules

**C. Test**
```bash
# Get ALB DNS name
aws elbv2 describe-load-balancers --names trading-alb

# Test health check
curl http://<ALB-DNS>/health
```

---

## 2. Complete CI/CD Pipeline - 3 Hours

### Why This Matters
- **Current Gap**: Pipeline stops at Build stage
- **Skill Demonstration**: Shows DevOps/automation expertise
- **Business Impact**: Enables automated testing and deployments

### Implementation Steps

**A. Add Testing Stage** (`modules/cicd/main.tf`)
```hcl
# CodeBuild Project for Testing
resource "aws_codebuild_project" "test" {
  name           = "${var.project_name}-test"
  service_role   = aws_iam_role.codebuild_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          runtime-versions:
            python: 3.11
          commands:
            - pip install -r requirements.txt
            - pip install pytest pytest-cov
        pre_build:
          commands:
            - echo "Running security scans..."
            - pip install checkov tflint
            - checkov -d . --framework terraform
            - tflint .
        build:
          commands:
            - echo "Running tests..."
            - pytest tests/ --cov=src --cov-report=xml
        post_build:
          commands:
            - echo "Tests completed"
      artifacts:
        files:
          - '**/*'
    EOT
  }
}

# CodeBuild Project for Security Scanning
resource "aws_codebuild_project" "security_scan" {
  name           = "${var.project_name}-security-scan"
  service_role   = aws_iam_role.codebuild_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          commands:
            - pip install checkov tflint kics terrascan
        build:
          commands:
            - echo "Running Checkov..."
            - checkov -d . --framework terraform --output cli
            - echo "Running TFLint..."
            - tflint .
            - echo "Running KICS..."
            - kics scan -p . -o json
            - echo "Running Terrascan..."
            - terrascan scan -d . -o json
      artifacts:
        files:
          - '**/*'
    EOT
  }
}
```

**B. Update CodePipeline** to include new stages
```hcl
resource "aws_codepipeline" "main" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName       = aws_codecommit_repository.main.repository_name
        BranchName          = "main"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "SecurityScan"
    action {
      name            = "SecurityScanAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.security_scan.name
      }
    }
  }

  stage {
    name = "Test"
    action {
      name            = "TestAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.test.name
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ApplicationName             = aws_codedeploy_app.main.name
        DeploymentGroupName         = aws_codedeploy_deployment_group.main.deployment_group_name
      }
    }
  }
}
```

---

## 3. Deploy Prometheus & Grafana - 2 Hours

### Why This Matters
- **Current Gap**: Documented but not deployed
- **Skill Demonstration**: Shows observability expertise
- **Business Impact**: Enables real-time monitoring and alerting

### Implementation Steps

**A. Create Helm Values** (`modules/monitoring/prometheus-values.yaml`)
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

grafana:
  adminPassword: ${grafana_admin_password}
  persistence:
    enabled: true
    size: 10Gi
  
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-operated:9090
        access: proxy
        isDefault: true

  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        updateIntervalSeconds: 10
        allowUiUpdates: true
        options:
          path: /var/lib/grafana/dashboards/default
```

**B. Deploy via Helm** (`modules/monitoring/main.tf`)
```hcl
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.0.0"

  values = [
    file("${path.module}/prometheus-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
```

**C. Create Trading Dashboard** (`modules/monitoring/trading-dashboard.json`)
```json
{
  "dashboard": {
    "title": "Trading Platform Metrics",
    "panels": [
      {
        "title": "Order Latency (P99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, rate(order_latency_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Kinesis Throughput",
        "targets": [
          {
            "expr": "rate(kinesis_records_total[5m])"
          }
        ]
      },
      {
        "title": "EKS Pod CPU Usage",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)"
          }
        ]
      }
    ]
  }
}
```

---

## 4. Enable GuardDuty & Security Hub - 1 Hour

### Why This Matters
- **Critical Gap**: No threat detection
- **Skill Demonstration**: Shows security expertise
- **Business Impact**: Enables automated threat response

### Implementation Steps

**A. Enable GuardDuty** (`modules/security/main.tf`)
```hcl
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = {
    Name = "${var.project_name}-guardduty"
  }
}

# CloudWatch Event Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 7.0, 7.1, 7.2, 7.3, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 9, 9.0, 9.1, 9.2, 9.3]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindings"
  arn       = aws_sns_topic.security_alerts.arn
}
```

**B. Enable Security Hub** (`modules/security/main.tf`)
```hcl
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on      = [aws_securityhub_account.main]
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "pci" {
  depends_on      = [aws_securityhub_account.main]
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

# CloudWatch Dashboard for Security Hub
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SecurityHub", "ComplianceScore"],
            [".", "CriticalFindingsCount"],
            [".", "HighFindingsCount"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Security Hub Metrics"
        }
      }
    ]
  })
}
```

---

## Implementation Checklist

### Week 1
- [ ] Deploy ALB with target groups and health checks
- [ ] Update EKS to register with ALB
- [ ] Test ALB routing and failover
- [ ] Document ALB configuration

### Week 2
- [ ] Add testing stage to CodePipeline
- [ ] Add security scanning stage
- [ ] Implement approval gates
- [ ] Test full pipeline end-to-end
- [ ] Deploy Prometheus/Grafana
- [ ] Create trading dashboards
- [ ] Enable GuardDuty
- [ ] Enable Security Hub
- [ ] Configure security alerts

### Validation
```bash
# Test ALB
curl http://<ALB-DNS>/health

# Test CI/CD
git push origin main  # Trigger pipeline

# Test Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Test Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Verify GuardDuty
aws guardduty list-detectors

# Verify Security Hub
aws securityhub describe-hub
```

---

## Success Criteria

✓ ALB distributing traffic to EKS  
✓ CI/CD pipeline running all stages  
✓ Security scanning blocking vulnerable code  
✓ Prometheus collecting metrics  
✓ Grafana dashboards displaying data  
✓ GuardDuty detecting threats  
✓ Security Hub showing compliance score  

---

## Next Steps (Week 3-4)

1. Implement ultra-low latency optimization (placement groups, c5n instances)
2. Add ElastiCache for caching layer
3. Implement automated DR testing
4. Add circuit breakers and resilience patterns

