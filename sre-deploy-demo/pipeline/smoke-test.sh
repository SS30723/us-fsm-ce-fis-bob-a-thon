#!/bin/bash
# Smoke tests for post-deployment verification
# Runs from inside the cluster (Jenkins agent pod)
# Exit code 0 = all healthy, 1 = failures detected

set -uo pipefail

NAMESPACE=$(oc project -q 2>/dev/null || echo "sre-deploy-demo")
FAILURES=0
TOTAL=0

check_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    TOTAL=$((TOTAL + 1))

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$status" = "$expected_status" ]; then
        echo "  ✓ ${name}: HTTP ${status}"
    else
        echo "  ✗ ${name}: HTTP ${status} (expected ${expected_status})"
        FAILURES=$((FAILURES + 1))
    fi
}

check_endpoint_body() {
    local name="$1"
    local url="$2"
    local expected_string="$3"
    TOTAL=$((TOTAL + 1))

    local body
    body=$(curl -s --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo "UNREACHABLE")

    if echo "$body" | grep -q "$expected_string"; then
        echo "  ✓ ${name}: contains '${expected_string}'"
    else
        echo "  ✗ ${name}: expected '${expected_string}' not found in response"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "═══════════════════════════════════════"
echo "  Post-Deployment Smoke Tests"
echo "  Namespace: ${NAMESPACE}"
echo "  Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "═══════════════════════════════════════"
echo ""

echo "Service Health:"
check_endpoint "order-service /health" "http://order-service:8080/api/orders/health"
check_endpoint_body "order-service health body" "http://order-service:8080/api/orders/health" "UP"

echo ""
echo "Actuator Probes:"
check_endpoint "order-service liveness" "http://order-service:8080/actuator/health/liveness"
check_endpoint "order-service readiness" "http://order-service:8080/actuator/health/readiness"

echo ""
echo "API Functional Tests:"
check_endpoint "GET /api/orders" "http://order-service:8080/api/orders"

# Create a test order and verify
echo ""
echo "Write Test:"
TOTAL=$((TOTAL + 1))
CREATE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"customerName":"smoke-test","product":"test-product","amount":1.00,"status":"PENDING"}' \
    --connect-timeout 5 --max-time 10 \
    "http://order-service:8080/api/orders" 2>/dev/null || echo "FAIL")

if echo "$CREATE_RESPONSE" | grep -q "smoke-test"; then
    echo "  ✓ POST /api/orders: created order successfully"

    # Clean up — extract id and delete
    ORDER_ID=$(echo "$CREATE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")
    if [ -n "$ORDER_ID" ]; then
        curl -s -X DELETE "http://order-service:8080/api/orders/${ORDER_ID}" --connect-timeout 5 > /dev/null 2>&1
    fi
else
    echo "  ✗ POST /api/orders: failed to create order"
    FAILURES=$((FAILURES + 1))
fi

echo ""
echo "Database Connectivity:"
check_endpoint "order-service actuator health" "http://order-service:8080/actuator/health"
# The actuator health endpoint includes db status when datasource is configured

echo ""
echo "═══════════════════════════════════════"
if [ "$FAILURES" -eq 0 ]; then
    echo "  RESULT: ALL ${TOTAL} CHECKS PASSED"
else
    echo "  RESULT: ${FAILURES}/${TOTAL} CHECKS FAILED"
fi
echo "═══════════════════════════════════════"

exit $FAILURES
