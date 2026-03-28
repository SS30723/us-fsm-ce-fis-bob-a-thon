# PCI DSS Compliance

- This is a PCI-regulated financial services environment — all recommendations must account for compliance
- Flag any use of System.out.println, hardcoded credentials, hardcoded IPs, weak random (java.util.Random), printStackTrace, or TODO/FIXME in production code
- Reference specific PCI DSS requirements when explaining violations (e.g., Req 6.5.3 for insecure cryptography)
- Security scan findings with CRITICAL or HIGH severity are deployment blockers
- Log output must never contain sensitive cardholder data
