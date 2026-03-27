# SRE Deploy Lab

A hands-on lab for learning how to integrate Bob AI into a regulated CI/CD pipeline. Participants start with a working Jenkins pipeline and progressively add Bob at key integration points — failure diagnosis, risk assessment, and change management.

**What you'll learn:**
1. How to deploy Bob CLI alongside your pipeline on OpenShift
2. How to call Bob from any Jenkins pipeline stage
3. How to use Bob to diagnose PCI compliance and test failures
4. How to have Bob generate formal Deployment Change Requests (DCRs)

## Labs

| Lab | Time | What you do |
|-----|------|-------------|
| [Lab 1: Setup](labs/LAB1_SETUP.md) | ~30 min | Deploy the app, Bob CLI, and Jenkins to the cluster |
| [Lab 2: Integrating Bob](labs/LAB2_BOB_PIPELINE.md) | ~45 min | Add Bob to the pipeline: failure diagnosis, DCR generation |

## Prerequisites

- OpenShift cluster (TechZone reservation)
- `oc` CLI installed (`brew install openshift-cli`)
- `podman` installed (`brew install podman`)
- GitHub repo with this code
- Bob API key
- GitHub PAT with `repo` scope

## Quick Start

```bash
# 1. Login to OpenShift
oc login --username=<user> --password=<pass> --server=<api-url>

# 2. Create project
oc new-project sre-deploy-demo

# 3. Deploy everything
make setup

# 4. Open Jenkins UI (URL printed by setup)
```

Then follow [Lab 1](labs/LAB1_SETUP.md) for the full guided walkthrough.

## Make Targets

```bash
make help                 # Show all targets
make setup                # Deploy app + Jenkins + Bob
make teardown             # Remove everything
make test                 # Run tests locally
make pci-check            # Run PCI compliance check locally
make oc-redeploy          # Rebuild and redeploy the app
make oc-bob PROMPT="..."  # Ask Bob a question on the cluster
```

## Project Structure

```
├── order-service/        # Spring Boot CRUD API (the application)
├── k8s/                  # Kubernetes manifests + OpenShift setup scripts
├── pipeline/             # PCI checkstyle rules + smoke test script
├── labs/                 # Lab guides and starter files
│   ├── LAB1_SETUP.md     # Environment setup lab
│   ├── LAB2_BOB_PIPELINE.md  # Bob integration lab
│   └── Jenkinsfile.starter   # Baseline pipeline (no Bob)
├── Jenkinsfile           # The complete pipeline (with Bob) — reference implementation
├── Makefile              # All commands
└── DEMO.md               # Presenter talking points
```
