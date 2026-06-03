# Security Test Results

This document records the results of the automated security and cryptography tests executed against the Adopti infrastructure.

## Test Suite Overview
The test suite (`run_crypto_tests.sh`) validates two primary Non-Functional Requirements (NFRs) outlined in the project guidelines:
1. **SSL para servidor seguro:** Ensuring TLS termination and strict mTLS validation on the internal API Gateway.
2. **Soportar ataques de Denegación de Servicio (DDoS):** Ensuring NGINX `limit_req` zones correctly identify and throttle excessive concurrent requests with `429 Too Many Requests`.

## Execution Results
**Date of execution:** June 2, 2026

```text
==============================================
    Adopti Security & Crypto Test Suite       
==============================================

=== Running SSL / mTLS Security Tests ===

[Test 1] Checking HTTP to HTTPS redirect...
✅ PASS: Port 80 successfully redirects to 443 (HTTP 301).
[Test 2] Checking Gateway mTLS enforcement (missing client cert)...
✅ PASS: Gateway rejects connection without client cert.
[Test 3] Checking Gateway mTLS enforcement (valid client cert)...
✅ PASS: Gateway accepts connection with valid client cert.

=== Running Rate Limiting Security Tests ===

[Test 1] Checking Gateway zone (api_general) on /api/pets/stats...
   Successful requests (200): 22
   Rate-limited requests (429): 3
✅ PASS: DDoS protection active on Gateway endpoints.
[Test 2] Checking Reverse Proxy zone (auth_limit) on /api/session...
   Non-rate-limited requests: 11
   Rate-limited requests (429): 9
✅ PASS: DDoS protection active on Frontend API endpoints.

==============================================
    Security Test Suite Execution Complete    
==============================================
```

## Conclusion
All security configurations are properly enforced. The system actively redirects to secure connections, denies untrusted internal connections (missing mTLS), and successfully mitigates brute-force/DDoS attempts on both public and internal-facing routing zones.
