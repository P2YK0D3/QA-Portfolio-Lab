# Defect Report: `BUG_SOFT_001_idempotency`

**Title**: Race Condition in Payment Capture Service Allows Duplicate Charges Under Identical `Idempotency-Key`  
**Defect ID**: `BUG_SOFT_001`  
**Classification**: Software QA / Backend API / Financial Integrity  
**Severity**: S1 - Blocker (Direct Financial Loss / Compliance Breach)  
**Priority**: P1 - Immediate (Hotfix Required)  
**Reported By**: Senior QA Systems Engineer  
**Date Reported**: 2026-11-10  
**Target Release**: Hotfix v1.4.3  

---

## 1. Environment Details
- **Environment**: Staging Cluster (`k8s-useast1-stg`)
- **API Service**: `checkout-orchestrator-svc:v1.4.2`
- **Database**: PostgreSQL 15.4 (RDS Multi-AZ)
- **Cache / Distributed Lock**: Redis Cluster v7.2 (`aws-elasticache`)
- **Payment Provider**: Stripe Mock & Live Sandbox API (`2024-04-10`)
- **Client**: Thunder Client / Python Concurrency Harness (`asyncio` + `aiohttp`)

---

## 2. Summary
When two or more identical payment capture requests bearing the exact same `Idempotency-Key` HTTP header are dispatched concurrently within a ~35ms window, both requests bypass the duplicate check filter. Consequently, two distinct payment transactions are authorized and settled at the payment gateway, and duplicate orders are generated in the database for a single customer purchase.

---

## 3. Preconditions
1. Test account `qa_user_391@lab.local` has a valid active session.
2. Active cart populated with `SKU-WIDGET-01` ($89.00 USD).
3. Client generates a valid UUID v4: `Idempotency-Key: b7f154cd-9f76-43b9-a54e-d6e2417769cf`.

---

## 4. Steps to Reproduce
1. Prepare a script to fire two concurrent HTTP `POST` requests to:  
   `POST https://staging-api.ecommerce.lab/v1/checkout/orders/capture`
2. Include identical headers on both threads:
   ```http
   Authorization: Bearer <VALID_JWT_TOKEN>
   Content-Type: application/json
   Idempotency-Key: b7f154cd-9f76-43b9-a54e-d6e2417769cf
   ```
3. Request Body:
   ```json
   {
     "cart_id": "cart_992147",
     "payment_method_id": "pm_card_visa",
     "expected_amount": 89.00,
     "currency": "USD"
   }
   ```
4. Fire Thread 1 and Thread 2 simultaneously with delta $\Delta t < 40\text{ ms}$.
5. Observe HTTP responses, Redis key state, database `orders` table, and payment gateway portal.

---

## 5. Expected Result
- **Thread 1**: Processes payment, registers order `ORD-10023`, returns HTTP `201 Created` with payload.
- **Thread 2**: 
  - If processed while Thread 1 is in-flight: returns HTTP `409 Conflict` (Code: `TRANSACTION_IN_PROGRESS`).
  - If processed after Thread 1 finishes: returns cached HTTP `200 OK` / `201 Created` with identical body as Thread 1.
- **Result**: Exactly **one** charge of $89.00 executed.

---

## 6. Actual Result
- **Both Thread 1 and Thread 2** return HTTP `201 Created`.
- **Database**: Two separate records inserted into `orders` table:
  - `ORD-10023` (Transaction ID: `ch_3OqL21...01`)
  - `ORD-10024` (Transaction ID: `ch_3OqL22...02`)
- **Stripe Dashboard**: Customer credit card charged **twice** ($89.00 x 2 = $178.00).

---

## 7. Diagnostic Logs & Telemetry

### Redis Cluster Monitor Log
```text
[11:04:12.102] "GET" "idempotency:b7f154cd-9f76-43b9-a54e-d6e2417769cf" -> (nil) [Thread-1]
[11:04:12.118] "GET" "idempotency:b7f154cd-9f76-43b9-a54e-d6e2417769cf" -> (nil) [Thread-2]
[11:04:12.380] "SET" "idempotency:b7f154cd-9f76-43b9-a54e-d6e2417769cf" "{\"order_id\":\"ORD-10023\"}" EX 86400 [Thread-1]
[11:04:12.395] "SET" "idempotency:b7f154cd-9f76-43b9-a54e-d6e2417769cf" "{\"order_id\":\"ORD-10024\"}" EX 86400 [Thread-2]
```

### Root Cause Analysis (RCA)
A classic **Time-of-Check to Time-of-Use (TOCTOU)** vulnerability exists in `CheckoutService.ts`.  
The application performs an initial `redis.get(key)` check. If `nil`, it proceeds to authorize payment at the external gateway, and only commits the idempotency key upon receiving the successful gateway callback. Because the payment authorization takes ~250ms, a concurrent request easily passes the non-blocking `GET` check.

Furthermore, the `orders` table lacks a database-level unique constraint on `idempotency_key`.

---

## 8. Proposed Remediation

### Immediate Fix (Atomic Mutex Lock)
Use an atomic `SET key value NX PX <milliseconds>` distributed lock pattern or Redlock before initiating third-party API calls:
```typescript
// Acquire atomic lock before external gateway interaction
const acquired = await redis.set(
  `lock:idempotency:${key}`,
  workerId,
  'PX', 15000, // 15s lock TTL
  'NX'
);

if (!acquired) {
  return res.status(409).json({
    code: "CONCURRENT_REQUEST",
    message: "A payment request with this idempotency key is currently processing."
  });
}
```

### Database Hardening
Add a unique index to enforce persistence guarantees:
```sql
ALTER TABLE orders ADD CONSTRAINT uq_orders_idempotency_key UNIQUE (idempotency_key);
```

---

## 9. QA Verification Plan (Regression)
- [ ] Run automated load test: 50 concurrent requests with identical `Idempotency-Key` to verify only 1 charge passes.
- [ ] Verify HTTP 409 returned for concurrent attempts during lock acquisition window.
- [ ] Verify cached response returned for requests arriving after lock release and settlement.
