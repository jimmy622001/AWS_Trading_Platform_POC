# Diagram Updates - New Components to Add

## New Components Added to Architecture

### 1. Load Balancing Layer (NEW)
- **Application Load Balancer (ALB)** - HTTP/HTTPS traffic routing
- **Network Load Balancer (NLB)** - Ultra-low latency TCP traffic (port 8080)
- Location: Public subnets, in front of EKS cluster

### 2. Caching Layer (NEW)
- **ElastiCache Redis Replication Group** - Order book caching
  - Multi-AZ with automatic failover
  - Encryption at rest and in transit
  - Location: Private data subnets
  - Connections: From EKS cluster and trading engines

### 3. Trading Optimizations (NEW)
- **EC2 Placement Group** - Clustered computing for ultra-low latency
- **Trading Engine Instances** - c5n.large compute-optimized instances
- **Auto Scaling Group** - Dynamic scaling (2-10 instances)
- **Enhanced Networking** - SR-IOV and ENA enabled
- Location: Private app subnets
- Purpose: Sub-millisecond latency for trading operations

### 4. Threat Detection & Security (NEW)
- **GuardDuty Detector** - Threat detection with S3 and Kubernetes audit logs
- **Security Hub** - Compliance monitoring (CIS AWS Foundations, PCI DSS)
- **CloudWatch Event Rules** - Automated finding routing
- **SNS Security Alerts Topic** - Alert distribution
- **CloudWatch Security Dashboard** - Metrics visualization

### 5. DR Automation (NEW)
- **Lambda Function** - Automated monthly DR testing
- **EventBridge Rule** - Scheduled execution (first Saturday of each month)
- **CloudWatch Log Group** - DR test logs
- **CloudWatch Alarms** - DR test failure alerts
- **CloudWatch DR Dashboard** - RTO/RPO metrics
- Validates: Primary/DR ALB health, RDS replication, DynamoDB consistency, failover capability

### 6. Prometheus/Grafana Monitoring (NEW)
- **Kubernetes Namespace** - Monitoring stack deployment
- **Prometheus** - Metrics collection from EKS
- **Grafana** - Visualization and dashboards
- **ServiceAccount & ClusterRole** - RBAC configuration
- **ConfigMap** - Prometheus scrape configuration

## Updated Architecture Layers

### Tier 1: Edge/Load Balancing
- Internet Gateway
- ALB (HTTP/HTTPS) - NEW
- NLB (TCP ultra-low latency) - NEW

### Tier 2: Compute
- EKS Cluster (existing)
- Trading Engine Instances (EC2 with placement group) - NEW
- Prometheus/Grafana Stack - NEW

### Tier 3: Caching & Data
- ElastiCache Redis - NEW
- DynamoDB (existing)
- RDS Aurora Multi-AZ (existing)
- Kinesis Data Streams (existing)

### Tier 4: Integration & Events
- EventBridge (existing)
- SNS Topics (existing + security alerts) - ENHANCED
- SQS (existing)
- Lambda (existing + DR testing) - ENHANCED

### Tier 5: Security & Monitoring
- GuardDuty - NEW
- Security Hub - NEW
- CloudWatch (existing + enhanced dashboards) - ENHANCED
- Prometheus/Grafana - NEW

### Tier 6: Disaster Recovery
- DR Automation Lambda - NEW
- Multi-region failover - NEW
- Route 53 health checks - NEW

## Data Flow Updates

### Trading Flow (NEW)
1. Client → ALB (HTTP/HTTPS)
2. ALB → EKS Cluster
3. EKS → Trading Engines (EC2 placement group)
4. Trading Engines → ElastiCache Redis (order book cache)
5. Trading Engines → DynamoDB (state)
6. Trading Engines → Kinesis (event stream)

### Ultra-Low Latency Flow (NEW)
1. Client → NLB (TCP port 8080)
2. NLB → Trading Engines (direct TCP)
3. Enhanced networking (SR-IOV, ENA) for sub-millisecond latency

### Monitoring Flow (NEW)
1. EKS → Prometheus (metrics scrape)
2. Prometheus → Grafana (visualization)
3. CloudWatch → Dashboards (ALB, NLB, ElastiCache, Trading Engines)
4. GuardDuty/Security Hub → CloudWatch Events → SNS (security alerts)

### DR Testing Flow (NEW)
1. EventBridge (monthly schedule)
2. → Lambda DR Test Function
3. → Validates primary/DR ALB health
4. → Checks RDS replication lag
5. → Validates DynamoDB consistency
6. → Measures RTO/RPO
7. → SNS notification with results

## Diagram Positioning Recommendations

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                     │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  Public Subnets                                 │   │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │  │
│  │  │  │   IGW    │  │   ALB    │  │   NLB    │      │   │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘      │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  Private App Subnets                            │   │  │
│  │  │  ┌──────────────────────────────────────────┐  │   │  │
│  │  │  │  EKS Cluster                             │  │   │  │
│  │  │  │  ├─ Trading Engines (EC2 Placement)     │  │   │  │
│  │  │  │  ├─ Prometheus/Grafana Stack            │  │   │  │
│  │  │  │  └─ Lambda (DR Testing)                 │  │   │  │
│  │  │  └──────────────────────────────────────────┘  │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  Private Data Subnets                           │   │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │  │
│  │  │  │ ElastiCache │ DynamoDB │ RDS Aurora │      │   │  │
│  │  │  │  (Redis)   │          │ Multi-AZ   │      │   │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘      │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  Security & Monitoring                          │   │  │
│  │  │  ├─ GuardDuty (Threat Detection)               │   │  │
│  │  │  ├─ Security Hub (Compliance)                  │   │  │
│  │  │  ├─ CloudWatch (Metrics & Logs)                │   │  │
│  │  │  └─ SNS (Security Alerts)                      │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  External Services                                       │  │
│  │  ├─ S3 (Data Storage)                                   │  │
│  │  ├─ Route 53 (DNS & Health Checks)                      │  │
│  │  ├─ EventBridge (Scheduling)                            │  │
│  │  └─ Kinesis (Event Streaming)                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Color Coding Recommendations

- **Load Balancing**: Blue (#147EBA)
- **Compute**: Orange (#FF9900)
- **Caching**: Purple (#945DF2)
- **Data**: Blue (#4D72F3)
- **Security**: Red (#BC1356)
- **Monitoring**: Green (#60A337)
- **DR/Automation**: Yellow (#FFB81C)
