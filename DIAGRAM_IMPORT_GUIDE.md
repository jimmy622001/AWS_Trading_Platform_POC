# How to Update diagram.drawio with New Components

## Quick Start

You have two options:

### Option 1: Use the Updated Diagram File (RECOMMENDED)
**File:** `diagram_complete.drawio`
- This is a copy of your current diagram
- Open it in draw.io and manually add the new components (see instructions below)
- Save it back to replace `diagram.drawio`

### Option 2: Manual Addition to Existing Diagram
Open `diagram.drawio` in draw.io and add components as described below.

---

## Components to Add

### 1. Network Load Balancer (NLB) - NEW
**Location:** Public Subnets, next to ALB
**Position:** x=300, y=120 (left of ALB)
**Steps:**
1. In draw.io, search for "Network Load Balancer" in AWS shapes
2. Drag it to the public subnet area
3. Label: "Network Load Balancer (TCP:8080)"
4. Add connection from IGW to NLB
5. Add connection from NLB to Trading Engines

**Properties:**
- Color: Blue (#147EBA)
- Port: 8080
- Purpose: Ultra-low latency trading

---

### 2. ElastiCache Redis - NEW
**Location:** Private Data Subnets
**Position:** x=300, y=475 (between DynamoDB and Kinesis Firehose)
**Steps:**
1. Search for "ElastiCache" or "Redis" in AWS shapes
2. Drag to Private Data Subnet area
3. Label: "ElastiCache Redis (Order Book Cache)"
4. Add connections from:
   - EKS Cluster
   - Trading Engines
5. Add connection to CloudWatch (monitoring)

**Properties:**
- Multi-AZ: Enabled
- Encryption: At rest & in transit
- Nodes: 2 (cache.r6g.large)

---

### 3. EC2 Placement Group (Trading Engines) - NEW
**Location:** Private App Subnets
**Position:** x=100-200, y=280 (replace/enhance existing Trading Engine boxes)
**Steps:**
1. Add a container/group box labeled "EC2 Placement Group"
2. Inside, place the existing Trading Engine A and B
3. Add label: "Clustered Placement (Ultra-Low Latency)"
4. Add connection to NLB (port 8080)
5. Add connection to ElastiCache

**Properties:**
- Strategy: Clustered
- Instance Type: c5n.large
- Enhanced Networking: SR-IOV, ENA enabled
- Latency: < 1ms

---

### 4. GuardDuty - NEW
**Location:** Right side, Security layer
**Position:** x=850, y=880 (below X-Ray)
**Steps:**
1. Search for "GuardDuty" in AWS shapes
2. Drag to right side panel
3. Label: "GuardDuty (Threat Detection)"
4. Add connection to CloudWatch Events
5. Add connection to SNS

**Properties:**
- S3 logs: Enabled
- Kubernetes audit logs: Enabled
- Findings: High & Critical

---

### 5. Security Hub - NEW
**Location:** Right side, Security layer
**Position:** x=850, y=950 (below GuardDuty)
**Steps:**
1. Search for "Security Hub" in AWS shapes
2. Drag to right side panel
3. Label: "Security Hub (Compliance)"
4. Add connection to CloudWatch Events
5. Add connection to SNS

**Properties:**
- Standards: CIS AWS Foundations, PCI DSS
- Compliance monitoring

---

### 6. Lambda DR Testing - NEW
**Location:** Private App Subnets or separate area
**Position:** x=550, y=340 (next to EventBridge)
**Steps:**
1. Search for "Lambda" in AWS shapes
2. Drag to area near EventBridge
3. Label: "Lambda (DR Testing)"
4. Add connection from EventBridge
5. Add connections to:
   - Primary ALB (health check)
   - DR ALB (health check)
   - RDS (replication lag check)
   - DynamoDB (consistency check)
   - Route 53 (failover test)

**Properties:**
- Trigger: EventBridge (monthly)
- Runtime: Python 3.11
- Timeout: 5 minutes
- Purpose: Automated DR validation

---

### 7. Prometheus/Grafana - ALREADY PRESENT
**Status:** Already in diagram as "Prometheus/Grafana Monitoring"
**Location:** x=720, y=342
**Verify:** Should show monitoring stack for EKS

---

### 8. Enhanced Networking Indicators - NEW
**Location:** Near Trading Engines
**Steps:**
1. Add text annotation: "SR-IOV + ENA Enabled"
2. Add text annotation: "Sub-millisecond Latency"
3. Add visual indicator (e.g., lightning bolt or star)

---

## Data Flow Connections to Add

### Trading Flow (Standard)
```
Internet → IGW → ALB → EKS → Trading Microservices
                              ├→ ElastiCache
                              ├→ DynamoDB
                              └→ RDS Aurora
```

### Ultra-Low Latency Flow (NEW)
```
Internet → IGW → NLB (TCP:8080) → EC2 Placement Group
                                   ├→ ElastiCache
                                   └→ Kinesis
```

### Security Flow (NEW)
```
AWS Resources → GuardDuty → CloudWatch Events → SNS
             → Security Hub → CloudWatch Events → SNS
```

### DR Testing Flow (NEW)
```
EventBridge (Monthly) → Lambda DR Test
                        ├→ Check Primary ALB
                        ├→ Check DR ALB
                        ├→ Check RDS Replication
                        ├→ Check DynamoDB
                        └→ Measure RTO/RPO
                        → SNS Notification
```

---

## Color Scheme for New Components

| Component | Color | Hex Code |
|-----------|-------|----------|
| Load Balancing (NLB) | Blue | #147EBA |
| Caching (ElastiCache) | Purple | #945DF2 |
| Compute (EC2 Placement) | Orange | #FF9900 |
| Security (GuardDuty/Hub) | Red | #BC1356 |
| Automation (Lambda DR) | Purple | #5A30B5 |
| Monitoring (Prometheus) | Green | #60A337 |

---

## Step-by-Step Instructions for draw.io

### To Add a Component:
1. **Open draw.io**
2. **File → Open** → Select `diagram.drawio` or `diagram_complete.drawio`
3. **Left Panel:** Search for AWS component (e.g., "Network Load Balancer")
4. **Drag** component to desired location on canvas
5. **Double-click** to edit label
6. **Right-click** → Format to change colors/styles
7. **Draw connections** using connector tool (arrow icon)
8. **File → Save** to save changes

### To Add Text Annotations:
1. **Insert → Text** (or press T)
2. Click on canvas where you want text
3. Type your annotation
4. Format as needed

### To Add Containers/Groups:
1. **Insert → Container** (or search for "Group")
2. Drag to create container
3. Drag components inside
4. Label the container

---

## Recommended Order of Addition

1. **NLB** (Network Load Balancer) - Most visible change
2. **ElastiCache** - Important data layer component
3. **EC2 Placement Group** - Enhance existing trading engines
4. **Lambda DR Testing** - Automation layer
5. **GuardDuty & Security Hub** - Security layer
6. **Enhanced Networking Labels** - Annotations
7. **Data Flow Connections** - Connect all components

---

## Alternative: Import from XML

If you want to programmatically update the diagram, you can:

1. **Export current diagram as XML** (File → Export as → XML)
2. **Use the XML snippets** provided below to add components
3. **Re-import** the updated XML

### XML Snippet for NLB:
```xml
<mxCell id="nlb-1" parent="cYRuOMdHzHzfs6oKb3E3-2" 
  style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=#147EBA;gradientDirection=north;fillColor=#147EBA;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.network_load_balancer;" 
  value="Network Load Balancer" vertex="1">
  <mxGeometry height="50" width="50" x="300" y="120" as="geometry" />
</mxCell>
```

---

## Verification Checklist

After adding all components, verify:

- [ ] NLB is positioned in public subnets
- [ ] ElastiCache is in private data subnets
- [ ] EC2 Placement Group is labeled on trading engines
- [ ] Lambda DR Testing is connected to EventBridge
- [ ] GuardDuty and Security Hub are in security layer
- [ ] All connections are drawn correctly
- [ ] Color scheme is consistent
- [ ] Labels are clear and readable
- [ ] Diagram is saved as `diagram.drawio`

---

## Need Help?

If you need the exact XML for any component, let me know and I can provide it. You can also:

1. **Copy existing components** in draw.io and modify them
2. **Use draw.io's search** to find AWS shapes
3. **Reference AWS architecture icons** from draw.io's built-in library

---

## Files Available

- **diagram.drawio** - Current diagram (original)
- **diagram_complete.drawio** - Copy ready for updates
- **ARCHITECTURE_UPDATED.md** - Complete architecture documentation
- **DIAGRAM_UPDATES.md** - Component mapping guide
