# SRE Deploy Demo — Project Specification

## Overview

This is a complete spec for a new, simplified project that demonstrates the SRE team's 10-step production deployment flow with Bob AI assistance. A fresh Claude session should be able to read this file and the companion spec files to build the entire project from scratch.

## What This Project Demonstrates

A regulated production deployment pipeline where:
1. Developer creates a PR
2. Jenkins validates the PR (linting + PCI compliance checks)
3. Bob AI analyzes the code and creates a Change Management (DCR) ticket
4. Management reviews Bob's risk assessment and approves/rejects
5. ArgoCD deploys to the target cluster
6. Bob runs smoke tests and verifies deployment health
7. Bob updates the change control ticket with deployment results

Additionally:
- **Bob helps generate and validate environment-specific properties files** — for each environment (dev, staging, prod, on-prem, cloud), Bob analyzes the application code to determine what configuration is needed and generates the right `application.properties` or ConfigMaps. This is a separate demo capability that shows Bob assisting with environment setup, not just pipeline execution.

## Directory Structure

```
sre-deploy-lab/
├── order-service/                          # The application
│   ├── src/main/java/com/example/orders/
│   │   ├── OrderApplication.java
│   │   ├── model/Order.java
│   │   ├── repository/OrderRepository.java
│   │   ├── service/OrderService.java
│   │   └── controller/OrderController.java
│   ├── src/main/resources/
│   │   ├── application.properties          # Default / dev config
│   │   ├── application-staging.properties  # Staging overrides
│   │   └── application-prod.properties     # Production overrides
│   ├── src/test/java/com/example/orders/
│   │   ├── service/OrderServiceTest.java
│   │   └── controller/OrderControllerTest.java
│   ├── src/test/resources/
│   │   └── application-test.properties
│   ├── pom.xml
│   └── Dockerfile
│
├── k8s/                                    # Kubernetes manifests
│   ├── order-service-deployment.yaml
│   ├── order-service-service.yaml
│   ├── order-db-deployment.yaml
│   ├── order-db-service.yaml
│   └── openshift/
│       ├── setup.sh                        # Deploy app to OpenShift
│       ├── teardown.sh                     # Remove app from OpenShift
│       ├── jenkins-setup.sh                # Deploy Jenkins + create pipeline job
│       ├── jenkins-teardown.sh             # Remove Jenkins
│       ├── argocd-setup.sh                 # Install ArgoCD + create Application CR
│       ├── argocd-teardown.sh              # Remove ArgoCD
│       ├── argocd-application.yaml         # ArgoCD Application CR
│       ├── bob-cli-setup.sh                # Deploy Bob CLI pod
│       ├── bob-cli-teardown.sh             # Remove Bob CLI
│       └── jenkins-agent/
│           └── Dockerfile                  # Custom Jenkins agent image
│
├── pipeline/                               # CI/CD pipeline configs
│   ├── pci-checkstyle.xml                  # PCI compliance linting rules
│   └── smoke-test.sh                       # Post-deployment health checks
│
├── Jenkinsfile                             # The 10-step pipeline
├── Makefile                                # All commands as make targets
├── README.md                               # Setup guide
└── DEMO.md                                 # How to run the demo
```

## Spec Files

The implementation is split across these companion spec files. Each contains complete, copy-pasteable file contents:

| Spec File | What It Covers |
|-----------|---------------|
| [APP_SPEC.md](APP_SPEC.md) | The Spring Boot application: every Java file, pom.xml, Dockerfile, properties files |
| [PIPELINE_SPEC.md](PIPELINE_SPEC.md) | The complete Jenkinsfile, PCI checkstyle rules, smoke test script |
| [INFRA_SPEC.md](INFRA_SPEC.md) | All k8s manifests, setup/teardown scripts, Jenkins agent Dockerfile, ArgoCD setup, Makefile |
| [DEMO_SPEC.md](DEMO_SPEC.md) | Demo branches, what to break in each, README.md, DEMO.md, step-by-step lab guide |

---

## Implementation Phases (with checkpoints)

Each phase ends with a verification step. **Do not proceed to the next phase until the checkpoint passes.** If something fails, fix it before moving on.

### Phase 1: Create the Application (local, no cluster needed)

**What to build:**
- All files in `order-service/` from APP_SPEC.md
- The `pom.xml`, all Java source files, all properties files, Dockerfile

**Checkpoint — verify locally:**
```bash
cd order-service

# 1. Project compiles
mvn compile -q
# Expected: BUILD SUCCESS

# 2. Tests pass
mvn test
# Expected: Tests run: 9, Failures: 0, Errors: 0

# 3. Standard lint passes
mvn checkstyle:check -q
# Expected: BUILD SUCCESS (no violations)

# 4. Application starts (will fail to connect to DB, but should start the Spring context)
mvn spring-boot:run &
sleep 10
curl http://localhost:8080/api/orders/health
# Expected: {"status":"UP","service":"order-service"}
# Kill the process after testing: kill %1
```

If all 4 pass, the application code is correct. Move to Phase 2.

---

### Phase 2: Create Pipeline and Config Files (local, no cluster needed)

**What to build:**
- `Jenkinsfile` from PIPELINE_SPEC.md
- `pipeline/pci-checkstyle.xml` from PIPELINE_SPEC.md
- `pipeline/smoke-test.sh` from PIPELINE_SPEC.md

**Checkpoint — verify locally:**
```bash
# 1. PCI checkstyle runs (should pass on clean code)
cd order-service
mvn checkstyle:check -Dcheckstyle.config.location=../pipeline/pci-checkstyle.xml
# Expected: BUILD SUCCESS

# 2. Smoke test script is syntactically valid
bash -n pipeline/smoke-test.sh
# Expected: no output (no syntax errors)

# 3. Jenkinsfile exists and has all 10 stages
grep -c "stage(" Jenkinsfile
# Expected: 10 or more (checkout, analysis, lint, pci, test, security, dcr, approval, deploy, smoke, update)
```

If all pass, pipeline configs are correct. Move to Phase 3.

---

### Phase 3: Create K8s Manifests (local, no cluster needed)

**What to build:**
- All files in `k8s/` from INFRA_SPEC.md (manifests only, not scripts yet)
  - `order-db-deployment.yaml`
  - `order-db-service.yaml`
  - `order-service-deployment.yaml`
  - `order-service-service.yaml`

**Checkpoint — verify locally:**
```bash
# 1. YAML is valid
python3 -c "import yaml; yaml.safe_load(open('k8s/order-db-deployment.yaml'))"
python3 -c "import yaml; yaml.safe_load(open('k8s/order-service-deployment.yaml'))"
# Expected: no errors

# 2. Manifests reference correct images/ports
grep "containerPort: 5432" k8s/order-db-deployment.yaml
grep "containerPort: 8080" k8s/order-service-deployment.yaml
grep "IMAGE_PLACEHOLDER" k8s/order-service-deployment.yaml
# Expected: all three found
```

---

### Phase 4: Create Infrastructure Scripts and Makefile (local, no cluster needed)

**What to build:**
- All scripts in `k8s/openshift/` from INFRA_SPEC.md
- Jenkins agent Dockerfile from INFRA_SPEC.md
- `Makefile` from INFRA_SPEC.md

**Checkpoint — verify locally:**
```bash
# 1. All scripts are syntactically valid
bash -n k8s/openshift/setup.sh
bash -n k8s/openshift/teardown.sh
bash -n k8s/openshift/jenkins-agent-build.sh
bash -n k8s/openshift/argocd-setup.sh
bash -n k8s/openshift/argocd-teardown.sh
# Expected: no output for each (no syntax errors)

# 2. Makefile targets exist
make help
# Expected: list of targets including setup, teardown, oc-deploy, oc-deploy-jenkins, etc.

# 3. Jenkins agent Dockerfile is valid
head -1 k8s/openshift/jenkins-agent/Dockerfile
# Expected: FROM jenkins/inbound-agent:latest-jdk17
```

---

### Phase 5: Deploy Application to OpenShift (cluster required from here)

**Prerequisites:** `oc login` completed, project created (`oc new-project sre-deploy-lab`)

**What to run:**
```bash
make oc-deploy
```

**Checkpoint — verify on cluster:**
```bash
# 1. Pods are running
oc get pods
# Expected: order-db (Running), order-service (Running)

# 2. Service is accessible
oc get route order-service -o jsonpath='{.spec.host}'
# Use the URL:

# 3. Health check works
curl http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders/health
# Expected: {"status":"UP","service":"order-service"}

# 4. API works (create an order)
curl -X POST http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerName":"test","product":"widget","amount":9.99,"status":"PENDING"}'
# Expected: JSON response with id, customerName, product, etc.

# 5. Database is connected (list orders returns the one we just created)
curl http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders
# Expected: array with at least one order
```

If all 5 pass, the application is running correctly on the cluster. Move to Phase 6.

---

### Phase 6: Deploy Bob CLI

**What to run:**
```bash
make oc-deploy-bob
```

**Checkpoint — verify on cluster:**
```bash
# 1. Bob CLI pod is running
oc get pods -l component=bob-cli
# Expected: bob-cli pod in Running state

# 2. Bob can respond to prompts
make oc-bob PROMPT="Say hello in one sentence"
# Expected: Bob responds with a greeting

# 3. Bob can analyze the application (properties file use case)
make oc-bob PROMPT="Analyze the order-service application in this repo. What configuration properties does it need? What would the application.properties look like for a production environment with an external PostgreSQL database at db-prod.internal:5432?"
# Expected: Bob generates a production properties file with correct DB URL, connection pool settings, etc.
```

If all pass, Bob is working. Move to Phase 7.

---

### Phase 7: Deploy Jenkins

**What to run:**
```bash
make oc-deploy-jenkins
```

**Checkpoint — verify on cluster:**
```bash
# 1. Jenkins pod is running
oc get pods | grep jenkins
# Expected: jenkins pod in Running state

# 2. Jenkins UI is accessible
JENKINS_URL=$(oc get route jenkins -o jsonpath='{.spec.host}')
echo "Open in browser: https://$JENKINS_URL"
# Expected: Jenkins login page appears

# 3. Pipeline job exists
curl -sk "https://$JENKINS_URL/job/sre-pipeline/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['displayName'])"
# Expected: "sre-pipeline"

# 4. Trigger a build and verify it starts
# In Jenkins UI: click sre-pipeline → Build with Parameters → set BRANCH to main → Build
# Expected: Build starts, may fail at checkout if demo branches don't exist yet — that's OK
```

---

### Phase 8: Create Demo Branches and Test Pipeline

**What to do:** Follow DEMO_SPEC.md to create the demo branches.

```bash
# Create happy-path branch
git checkout main && git pull
git checkout -b lab/happy-path
# Make the changes described in DEMO_SPEC.md
git commit -am "chore: improve logging comments for audit compliance"
git push origin lab/happy-path
```

**Checkpoint — run the happy path:**
1. In Jenkins UI: Build with Parameters → BRANCH = `lab/happy-path` → Build
2. Watch the build progress

**Verify each stage passes:**
- [ ] Checkout: succeeds
- [ ] Bob PR Analysis: Bob's analysis appears in console
- [ ] Lint: PASS
- [ ] PCI Compliance: PASS
- [ ] Test: 9 tests pass
- [ ] Security Scan: LOW risk
- [ ] Create Change Request: Bob generates a DCR in console output
- [ ] Management Approval: Pipeline pauses, click Approve
- [ ] Deploy: Rollout completes
- [ ] Smoke Tests: All checks pass
- [ ] Update Change Control: Bob writes status update

If all stages pass, the core demo works. Create the remaining demo branches (test-failure, security-vuln).

---

### Phase 9: Deploy ArgoCD (optional, enhances the demo)

**What to run:**
```bash
make oc-deploy-argocd
```

**Checkpoint — verify on cluster:**
```bash
# 1. ArgoCD is running
oc get pods -n openshift-gitops | grep gitops-server
# Expected: openshift-gitops-server pod in Running state

# 2. ArgoCD UI is accessible
ARGOCD_URL=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
echo "Open in browser: https://$ARGOCD_URL"
# Expected: ArgoCD login page

# 3. Get admin password
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Expected: prints the admin password

# 4. Application CR exists
oc get application order-service -n openshift-gitops
# Expected: shows the application with sync status
```

---

### Phase 10: Bob Properties File Generation (demo capability)

This is a standalone demo capability — Bob helps generate correct configuration for any environment.

**How to demonstrate:**

```bash
# Ask Bob to generate a production properties file
make oc-bob PROMPT="I'm deploying order-service to a production environment. The database is at db-prod.uk-cluster.internal:5432, database name 'orders_prod', credentials in a Kubernetes secret called 'order-db-prod-credentials'.

Analyze the application code and generate:
1. application-prod.properties with production-appropriate settings (connection pooling, timeouts, logging levels, actuator security)
2. The kubectl/oc command to create the ConfigMap from this properties file
3. The environment variables or volume mount needed in the deployment YAML

Explain each setting and why it matters for production."
```

**What Bob produces:** A complete production properties file with explanations like:
```properties
# Database — use external managed PostgreSQL, not the in-cluster pod
spring.datasource.url=jdbc:postgresql://db-prod.uk-cluster.internal:5432/orders_prod
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

# Connection pool — size for production traffic
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000

# JPA — never auto-modify the schema in production
spring.jpa.hibernate.ddl-auto=validate

# Logging — structured JSON for log aggregation, no DEBUG in prod
logging.level.root=WARN
logging.level.com.example.orders=INFO
logging.pattern.console=%d{ISO8601} %-5level [%thread] %logger{36} - %msg%n

# Actuator — restrict endpoints in production
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=never
```

**Why this matters for the demo:** The SRE team said they want Bob to help set up properties files. This shows Bob:
- Understands the application code (knows what properties are used)
- Generates environment-appropriate settings (not just copying dev config)
- Explains WHY each setting is different in production
- Produces the Kubernetes commands to apply the config

**Additional properties use cases to demonstrate:**

```bash
# Bob validates a properties file
make oc-bob PROMPT="Here is our current production properties file for order-service:
[paste file]
Review it for:
1. Security issues (hardcoded credentials, exposed endpoints)
2. Performance issues (pool sizes, timeouts)
3. PCI compliance (logging levels, sensitive data exposure)
4. Missing properties that the application code requires"

# Bob generates ConfigMaps for multiple environments
make oc-bob PROMPT="We need to deploy order-service to three environments:
- dev (in-cluster PostgreSQL at order-db:5432)
- staging (RDS at staging-db.us-east-1.rds.amazonaws.com:5432)
- prod-uk (managed PostgreSQL at db-prod.uk-cluster.internal:5432)
Generate the application.properties for each environment and the oc commands to create ConfigMaps."
```

---

## Key Design Decisions

- **One service, one database.** The demo is about the deployment flow, not the application. Complexity in the app is a distraction.
- **Java/Spring Boot + PostgreSQL.** Matches the SRE team's stack. Maven for builds, JUnit for tests, Checkstyle for linting.
- **Jenkins for CI only.** Linting, testing, security scanning, Bob analysis, DCR creation, approval gate. No direct deployments from Jenkins.
- **ArgoCD for CD.** GitOps-based deployment. Jenkins updates the manifest, ArgoCD syncs the cluster.
- **Bob CLI on a separate pod.** Same pattern as the existing project — `oc exec` into the bob-cli pod to run prompts.
- **No frontend.** The demo runs in Jenkins UI. No React app to maintain. Pipeline output is visible in Jenkins console.
- **PCI compliance checks.** Custom Checkstyle rules that check for hardcoded credentials, System.out usage, and other PCI-relevant patterns.
- **JIRA integration is optional.** The Jenkinsfile logs DCR content to console. If JIRA MCP is configured, Bob can create real tickets. The demo works either way.
- **Multiple Spring profiles for environment config.** The app has `application.properties` (dev default), `application-staging.properties`, and `application-prod.properties`. Bob can generate additional profiles for new environments on the fly.

## What This Does NOT Include

- No React frontend (Jenkins UI is sufficient)
- No chaos engineering
- No AI operations monitoring
- No multiple languages (Java only)
- No multiple databases (PostgreSQL only)
- No DR repo sync (mention conceptually)
- No F5/HAProxy (use OpenShift routes)
- No ISPAN validation environment (skip)
- No deployment window enforcement (mention conceptually)

## Prerequisites

Same as the existing project:
- OpenShift cluster (TechZone reservation)
- `oc` CLI installed
- `podman` installed (for building images)
- GitHub repo with the code (for Jenkins to clone)
- Bob API key (for Bob CLI)
- GitHub PAT (for Jenkins to clone and comment on PRs)
