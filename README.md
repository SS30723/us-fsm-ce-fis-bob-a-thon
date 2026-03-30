# SRE Deploy Lab

**AI-Assisted Regulated Deployment Pipeline for Financial Services**

A hands-on demonstration of how IBM Bob integrates into a production CI/CD pipeline for regulated environments. Watch Bob analyze pull requests, diagnose failures, generate deployment change requests, and validate compliance—all within a real Jenkins pipeline deploying to OpenShift.

---

## Tech Stack

- **Application**: Spring Boot 3.2, PostgreSQL 15, Maven
- **CI/CD**: Jenkins, ArgoCD (GitOps)
- **Platform**: OpenShift 4.18 (Kubernetes)
- **Security**: Trivy vulnerability scanner, custom PCI Checkstyle rules
- **AI**: IBM Bob CLI for analysis and automation

---

## What This Demonstrates

This lab teaches you to integrate IBM Bob into a Jenkins pipeline at three critical points. By the end, you'll have:

**Core Integration (Lab Exercises):**
1. **Bob PR Analysis** → Analyzes code changes before checks run, identifies risks
2. **Bob Test Diagnosis** → Explains test failures with root cause and fix suggestions
3. **Bob Security Triage** → Analyzes CVEs and explains PCI compliance impact

**Optional Extensions:**
4. **Bob DCR Generation** → Creates formal Deployment Change Request with risk assessment
5. **Bob Smoke Test Analysis** → Validates post-deployment health

### The Pipeline Flow

1. **Checkout** → Pull PR branch from GitHub
2. **Bob PR Analysis** → Bob reviews the diff (Lab Exercise 2)
3. **Lint** → Standard code quality checks
4. **PCI Compliance** → Custom rules for regulated environments
5. **Unit Tests** → Run tests, Bob diagnoses failures (Lab Exercise 3)
6. **Security Scan** → Trivy finds CVEs, Bob explains impact (Lab Exercise 4)
7. **Approval Gate** → Human reviews (optionally with Bob-generated DCR)
8. **Build Image** → Package application into container
9. **Deploy via ArgoCD** → GitOps sync to OpenShift
10. **Smoke Tests** → Validate deployment health (optionally with Bob analysis)

### Real-World Use Cases

- **Failure diagnosis**: Bob turns raw stack traces and CVE tables into actionable fixes
- **Compliance automation**: Bob explains PCI DSS violations in regulatory terms
- **Risk assessment**: Bob evaluates all validation results and recommends approve/reject
- **Environment configuration**: Bob generates environment-specific properties files

---

## Architecture

```mermaid
graph TB
    Dev[Developer] -->|Push branch| GH[GitHub]
    Dev -->|Trigger build| Jenkins[Jenkins Pipeline]
    
    Jenkins -->|1. Checkout| GH
    Jenkins -->|2. Ask Bob| Bob[Bob CLI Pod]
    Jenkins -->|3-6. Validate| Checks[Lint + PCI + Tests + Security]
    
    Bob -->|Analyze PR| Jenkins
    Bob -->|Diagnose failures| Jenkins
    Bob -->|Explain CVEs| Jenkins
    
    Jenkins -->|7. Request approval| Mgmt[Management]
    Mgmt -->|Approve/Reject| Jenkins
    
    Jenkins -->|8. Build image| Registry[OpenShift Registry]
    Jenkins -->|9. Trigger sync| ArgoCD[ArgoCD]
    ArgoCD -->|Watch repo| GH
    ArgoCD -->|Deploy| OCP[OpenShift Cluster]
    
    Jenkins -->|10. Smoke tests| OCP
    
    OCP -->|Running| App[Order Service + PostgreSQL]
    
    style Bob fill:#e1f5ff
    style Jenkins fill:#fff4e1
    style ArgoCD fill:#e8f5e9
    style OCP fill:#f3e5f5
```

---

## Pipeline Flow with Bob Integration

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant J as Jenkins
    participant B as Bob CLI
    participant T as Trivy
    participant A as ArgoCD
    participant OCP as OpenShift

    Dev->>GH: Push branch
    Dev->>J: Trigger build manually
    
    J->>GH: Checkout branch
    
    rect rgb(225, 245, 255)
        Note over J,B: Lab Exercise 2: PR Analysis
        J->>B: Analyze PR diff
        B->>J: Risk assessment + summary
    end
    
    J->>J: Run lint
    J->>J: Run PCI compliance checks
    J->>J: Run unit tests
    
    alt Tests fail
        rect rgb(225, 245, 255)
            Note over J,B: Lab Exercise 3: Test Diagnosis
            J->>B: Diagnose test failures
            B->>J: Root cause + fix suggestion
        end
    end
    
    J->>T: Security scan
    
    alt CVEs found
        rect rgb(225, 245, 255)
            Note over J,B: Lab Exercise 4: Security Triage
            J->>B: Analyze vulnerabilities
            B->>J: PCI impact + remediation
        end
    end
    
    rect rgb(245, 245, 245)
        Note over J,B: Optional: DCR Generation
        J->>B: Generate DCR
        B->>J: Formal change request
    end
    
    J->>Dev: Request approval
    Dev->>J: Approve/Reject
    
    alt Approved
        J->>J: Build container image
        J->>A: Trigger ArgoCD sync
        A->>GH: Pull manifests
        A->>OCP: Deploy
        
        J->>OCP: Run smoke tests
        
        rect rgb(245, 245, 245)
            Note over J,B: Optional: Smoke Test Analysis
            J->>B: Analyze health
            B->>J: Deployment status
        end
    end
```

---

## Key Features

### 🤖 AI-Assisted Failure Diagnosis
- **PR Analysis**: Bob reviews code changes and identifies risks before checks run
- **Test Diagnosis**: Bob explains test failures with root cause and specific fix suggestions
- **Security Triage**: Bob analyzes CVEs and explains PCI compliance impact with remediation steps

### 🔒 PCI Compliance Validation
- Custom Checkstyle rules for PCI DSS requirements
- Detects hardcoded credentials, insecure logging, weak cryptography
- Bob explains violations in regulatory terms

### 📋 Optional: Change Management Automation
- Bob can generate formal Deployment Change Requests (DCRs)
- Includes change description, risk level, affected services, rollback plan
- Provides recommendation with justification for approval gates

### ⚙️ Environment Configuration Support
- Bob analyzes application code to determine required properties
- Generates environment-specific configuration files (dev, staging, prod)
- Explains each setting and why it matters for production

---

## Project Structure

```
├── order-service/        # Spring Boot CRUD API (the application)
│   ├── src/             # Java source code
│   ├── Dockerfile       # Container image definition
│   └── pom.xml          # Maven build configuration
│
├── k8s/                 # Kubernetes manifests
│   ├── *-deployment.yaml
│   ├── *-service.yaml
│   └── openshift/       # Setup scripts for OpenShift
│
├── pipeline/            # CI/CD pipeline configurations
│   ├── pci-checkstyle.xml    # PCI compliance rules
│   └── smoke-test.sh         # Post-deployment validation
│
├── labs/                # Hands-on lab exercises
│   └── LAB_BOB_PIPELINE.md   # Add Bob to your pipeline
│
├── Jenkinsfile          # Complete 10-step pipeline
├── Makefile             # All commands as make targets
├── SETUP.md             # Detailed setup guide
└── README.md            # This file
```

---

## Learning Path

1. **[SETUP.md](SETUP.md)** — Deploy the lab environment to OpenShift (~20 minutes)
2. **[LAB_BOB_PIPELINE.md](labs/LAB_BOB_PIPELINE.md)** — Add Bob integration to the pipeline (~30 minutes)
3. **Run demo scenarios** — Test the three branches to see Bob in action
4. **Explore optional labs** — MCP integration, custom modes, skills (labs/optional/)

---