# SRE Deploy Demo

Hands-on lab for integrating Bob AI into a regulated CI/CD pipeline. You'll deploy a Spring Boot app to OpenShift, set up Jenkins, and progressively add Bob to diagnose failures and generate deployment change requests.

## What You'll Build

A production deployment pipeline where Bob:
- Analyzes PRs before checks run
- Diagnoses PCI compliance and test failures
- Generates formal Deployment Change Requests (DCRs)
- Updates change control tickets with deployment results

## Prerequisites

- OpenShift cluster (TechZone)
- `oc` CLI (`brew install openshift-cli`)
- `podman` (`brew install podman`)
- GitHub repo with this code
- Bob API key
- GitHub PAT with `repo` scope

## Quick Start

```bash
# Login and create project
oc login --username=<user> --password=<pass> --server=<api-url>
oc new-project sre-deploy-lab

# Deploy everything
make setup

# Get Jenkins URL
oc get route jenkins -o jsonpath='{.spec.host}'
```

Then follow the labs in `labs/`.

## Labs

| Lab | Time | What You Do |
|-----|------|-------------|
| [Lab 1: Setup](labs/LAB1_SETUP.md) | 30 min | Deploy app, Bob CLI, and Jenkins |
| [Lab 2: Bob Integration](labs/LAB2_BOB_PIPELINE.md) | 45 min | Add Bob to pipeline stages |

## Common Commands

```bash
make help                 # Show all targets
make setup                # Deploy app + Jenkins + Bob
make teardown             # Remove everything
make oc-redeploy          # Rebuild and redeploy app
make oc-bob PROMPT="..."  # Ask Bob a question
make test                 # Run tests locally
make pci-check            # Run PCI compliance check
```

## Project Structure

```
├── order-service/        # Spring Boot CRUD API
├── k8s/                  # Kubernetes manifests + setup scripts
├── pipeline/             # PCI checkstyle rules + smoke tests
├── labs/                 # Lab guides
├── Jenkinsfile           # Complete pipeline (reference)
└── Makefile              # All commands
```

## Demo Scenarios

The complete Jenkinsfile includes three demo branches:
- `lab/happy-path` — Clean deployment, all checks pass
- `lab/test-failure` — Unit tests fail, Bob diagnoses root cause
- `lab/security-vuln` — PCI violations + CVEs, Bob explains compliance impact

See `DEMO.md` for presenter notes.