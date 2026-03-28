# Change Management

- Every production deployment requires a Deployment Change Request (DCR)
- A DCR must include: change description, risk assessment, affected services, validation evidence, rollback plan, and a recommendation
- Risk levels: Low, Medium, High, Critical — justify with evidence from pipeline results
- Never recommend APPROVE if any PCI compliance check, unit test, or security scan has failed
- All DCRs are reviewed by team management before deployment proceeds
