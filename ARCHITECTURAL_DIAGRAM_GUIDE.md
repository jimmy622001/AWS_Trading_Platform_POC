# AWS Trading Platform - Architectural Diagram Guide

## Overview

This guide provides detailed explanations of the architectural diagrams used in the trading platform presentation. These diagrams are designed to communicate complex architecture in a clear, compelling way.

## Available Diagrams

### 1. **Trading Architecture Layout** (Primary Presentation Diagram)
**File**: `docs/images/Trading Architecture Layout.png`

**What It Shows**:
- Complete end-to-end trading platform architecture
- Primary region (us-east-1) with active trading system
- DR region (us-west-2) with pilot light infrastructure
- Data flow between components
- Security boundaries and network isolation

**Key Components Highlighted**:
- **Ingestion Layer**: Market data feeds, order entry
- **Processing Layer**: Kinesis, EventBridge, Lambda
- **Storage Layer**: RDS, DynamoDB, S3
- **Orchestration**: EKS clusters with auto-scaling
- **Failover**: Route 53, cross-region replication

**Presentation Tips**:
- Start with this diagram to show the big picture
- Walk through data flow from market data ingestion to trade execution
- Highlight the pilot light DR region and automated failover
- Emphasize the multi-AZ design within primary region

---

### 2. **AWS Kinesis Infrastructure Diagram**
**File**: `docs/images/aws_kinesis_layout.png`

**What It Shows**:
- Detailed Kinesis data streaming architecture
- Market data ingestion pipeline
- Stream processing and transformation
- Integration with downstream systems

**Key Components Highlighted**:
- **Kinesis Data Streams**: 10 shards handling 10K+ msg/sec
- **Kinesis Firehose**: Streaming data to S3 for compliance
- **Lambda Processors**: Real-time data transformation
- **Destination Systems**: EventBridge, SQS, DynamoDB

**Presentation Tips**:
- Use this to explain event-driven architecture
- Show how market data flows through the system
- Highlight the scalability of Kinesis (10 shards = 10K msg/sec)
- Explain the compliance aspect (Firehose to S3)

---

### 3. **Trading Platform Architecture (Draw.io XML)**
**File**: `docs/infrastructure_diagram/trading_platform_architecture.drawio.xml`

**What It Shows**:
- Detailed technical architecture with all AWS services
- Network topology and security groups
- Data flow and integration points
- Monitoring and logging infrastructure

**How to Use**:
1. Open in draw.io (https://app.diagrams.net)
2. Import the XML file
3. Customize colors and labels for your presentation
4. Export as PNG or PDF for slides

**Customization Options**:
- Add your company branding
- Highlight specific components for focus areas
- Add annotations explaining design decisions
- Create simplified versions for different audiences

---

### 4. **Disaster Recovery Architecture (Draw.io XML)**
**File**: `docs/infrastructure_diagram/disaster_recovery_architecture.drawio.xml`

**What It Shows**:
- Primary and DR region setup
- Automated failover mechanisms
- Data replication strategies
- Recovery orchestration

**How to Use**:
1. Open in draw.io
2. Show the pilot light model (minimal DR infrastructure)
3. Explain automated scaling during failover
4. Highlight cost savings vs. active-active

---

## Creating Your Own Presentation Diagrams

### Recommended Approach

#### Slide 1: Business Challenge (Conceptual Diagram)
```
┌─────────────────────────────────────────┐
│     LEGACY TRADING INFRASTRUCTURE       │
├─────────────────────────────────────────┤
│                                         │
│  ❌ 50-100ms latency (too slow)         │
│  ❌ Single data center (no DR)          │
│  ❌ Manual scaling (can't handle spikes)│
│  ❌ Complex operations (slow deployment)│
│  ❌ Limited security controls           │
│  ❌ High infrastructure costs           │
│                                         │
└─────────────────────────────────────────┘
```

#### Slide 2: Solution Overview (High-Level)
```
┌──────────────────────────────────────────────────────┐
│         AWS TRADING PLATFORM SOLUTION                │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ✅ < 1ms latency (50-100x faster)                  │
│  ✅ Multi-region DR (automated failover)            │
│  ✅ Auto-scaling (handles 10x peak load)            │
│  ✅ Infrastructure as Code (deploy in hours)        │
│  ✅ Enterprise security (regulatory compliant)      │
│  ✅ 30% cost reduction (pilot light DR)             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### Slide 3: Architecture Components (Layered)
```
┌─────────────────────────────────────────────────────┐
│              PRESENTATION LAYER                     │
│  (API Gateway, Load Balancer, WAF)                 │
├─────────────────────────────────────────────────────┤
│              APPLICATION LAYER                      │
│  (EKS, Lambda, EventBridge, Kinesis)               │
├─────────────────────────────────────────────────────┤
│              DATA LAYER                             │
│  (RDS, DynamoDB, S3, EFS)                          │
├─────────────────────────────────────────────────────┤
│              INFRASTRUCTURE LAYER                   │
│  (VPC, Security Groups, KMS, Monitoring)           │
└─────────────────────────────────────────────────────┘
```

#### Slide 4: Disaster Recovery (Failover Flow)
```
NORMAL OPERATION:
Primary (us-east-1) ──[Active]──> Route 53 ──> Users
DR (us-west-2) ──[Pilot Light: 1 node]

FAILOVER TRIGGERED:
1. Route 53 detects primary failure (< 30 sec)
2. Lambda scales DR environment (< 5 min)
3. Route 53 switches traffic to DR
4. DR environment handles all trading (< 15 min RTO)

FAILBACK:
1. Primary region recovers
2. Data syncs from DR to primary
3. Traffic gradually shifts back
4. DR scales down to pilot light
```

---

## Presentation Flow Recommendations

### For a 30-Minute Presentation

**Slide 1-2 (5 min)**: Business Challenge
- Show legacy infrastructure problems
- Quantify business impact ($2-5M/day in missed opportunities)
- List key requirements

**Slide 3-4 (5 min)**: Solution Overview
- High-level architecture diagram
- Key components and their purpose
- How it addresses each challenge

**Slide 5-8 (10 min)**: Detailed Architecture
- Use Trading Architecture Layout diagram
- Walk through data flow
- Explain each layer (ingestion, processing, storage, orchestration)
- Show security and monitoring

**Slide 9-10 (5 min)**: Disaster Recovery & 6 Pillars
- Show DR architecture
- Explain pilot light model and cost savings
- Map to 6 pillars of good architecture

**Slide 11 (5 min)**: Business Value & ROI
- Show quantified benefits
- Highlight competitive advantages
- Discuss implementation timeline

---

## Key Talking Points for Each Diagram

### Trading Architecture Layout
- "This diagram shows our complete trading platform architecture"
- "Notice the primary region on the left with full production capacity"
- "The DR region on the right runs in pilot light mode—just 1 small node"
- "When primary fails, Route 53 automatically switches traffic"
- "Lambda functions automatically scale the DR environment to match primary"
- "This pilot light approach saves 30% vs. active-active while maintaining < 15 min RTO"

### Kinesis Infrastructure
- "Market data flows through Kinesis at 10,000+ messages per second"
- "Kinesis automatically scales to handle market volatility"
- "Data is processed in real-time by Lambda functions"
- "Compliance data is archived to S3 for regulatory requirements"
- "This event-driven approach enables independent scaling of components"

### 6 Pillars Alignment
- "Operational Excellence: Infrastructure as Code, automated deployments"
- "Security: End-to-end encryption, IAM least privilege, automated scanning"
- "Reliability: Multi-AZ, auto-failover, cross-region DR"
- "Performance: Sub-millisecond latency with SR-IOV and ENA"
- "Cost Optimization: Pilot light DR, auto-scaling, 30% cost reduction"
- "Sustainability: Efficient resource utilization, automated scaling"

---

## Tips for Impressive Presentation

1. **Use Consistent Colors**: Maintain color scheme across all diagrams
2. **Add Annotations**: Label key components and data flows
3. **Show Movement**: Use arrows to show data flow and failover
4. **Highlight Security**: Use different colors for security boundaries
5. **Include Metrics**: Add latency, throughput, and cost numbers
6. **Tell a Story**: Walk through a trade from entry to execution
7. **Emphasize Automation**: Show how failover happens without manual intervention
8. **Connect to Business**: Always tie technical decisions back to business value

---

## Diagram Export Instructions

### From Draw.io
1. Open the .drawio.xml file in draw.io
2. Click File > Export As > PNG (or PDF)
3. Adjust size and quality settings
4. Save with descriptive filename

### Recommended Export Settings
- **Format**: PNG (for presentations)
- **Resolution**: 300 DPI (for printing)
- **Size**: 1920x1080 (for widescreen)
- **Background**: White (for professional look)

---

## Additional Resources

- **Trading Architecture Layout**: `docs/images/Trading Architecture Layout.png`
- **Kinesis Infrastructure**: `docs/images/aws_kinesis_layout.png`
- **Editable Diagrams**: `docs/infrastructure_diagram/*.drawio.xml`
- **Architecture Documentation**: `ARCHITECTURE.md`
- **Detailed Components**: `docs/architecture/detailed-components.md`

