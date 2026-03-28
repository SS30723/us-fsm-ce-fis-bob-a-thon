# Rollback Safety

- Always have a rollback plan before recommending deployment
- For the order-service: rollback means redeploying the previous image tag via `oc rollout undo deployment/order-service`
- After rollback, verify the service is healthy with smoke tests before closing the incident
- If smoke tests fail post-deployment, recommend rollback unless the issue is clearly unrelated to the change
