---
name: frd
description: "Generate a Functional Requirements Document (FRD) for a technical feature or system component. Use when planning backend work, API design, internal systems, or infrastructure changes. Triggers on: create an frd, write frd for."
---

# FRD Generator

Create detailed Functional Requirements Documents that are clear, actionable, and suitable for implementation by AI agents.

---

## The Job

1. Receive a feature or component description from the user
2. Ask any and all clarifying questions with the AskUserQuestion tool
3. Generate a structured FRD based on answers
4. Save to `tasks/frd-[feature-name].md`

**Important:** Do NOT start implementing. Just create the FRD.

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Actors:** Who or what interacts with this system? (services, API clients, internal components, operators)
- **Core Functionality:** What must the system do?
- **Scope/Boundaries:** What should it NOT do?
- **Constraints:** Performance requirements, compatibility needs, operational concerns?
- **Success Criteria:** How do we know it's done?

Use the AskUserQuestion tool to work through these questions.

---

## Step 2: FRD Structure

Generate the FRD with these sections:

### 1. Overview
Brief description of the component/feature and the problem it solves. Include context on where this fits in the broader system.

### 2. Goals
Bullet list of objectives. Each must be specific, measurable, achievable, and relevant.

### 3. Actors
List all entities that interact with this system:
- **Internal services** (e.g., "Ingestion service calls this API to...")
- **API clients** (e.g., "External clients authenticate via...")
- **Operators** (e.g., "On-call engineers need to...")
- **Scheduled jobs** (e.g., "Nightly cleanup process...")

### 4. Functional Requirements

Group related requirements under logical headings. Each requirement needs:
- **ID:** Unique identifier (FR-001, FR-002, etc.)
- **Title:** Short descriptive name
- **Description:** What the system must do, written as "The system will..."
- **Acceptance Criteria:** Verifiable checklist of what "done" means

Each requirement should be small enough to implement and test in one focused session.

**Format:**
```markdown
#### FR-001: [Title]
**Description:** The system will [specific behavior].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Unit/integration tests pass
- [ ] New behaviors have new tests or test cases
- [ ] Typecheck, staticcheck, lint, other such checks pass
```

**Important:** Acceptance criteria must be verifiable, not vague. "Works correctly" is bad. "Returns 404 with error code `RESOURCE_NOT_FOUND` when ID does not exist" is good.

### 5. Non-Functional Requirements
Numbered list of performance, reliability, and operational requirements:
- **NFR-001:** "The API will respond within 100ms at p99 under normal load"
- **NFR-002:** "The system will handle 1000 requests/second"
- **NFR-003:** "Failed jobs will be retryable without side effects"

### 6. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope.

### 7. API Contracts (If Applicable)
Define interfaces this system exposes or consumes:
- Endpoint signatures
- Request/response schemas
- Error codes and conditions
- Authentication requirements

### 8. Data Model (If Applicable)
- New tables, columns, or schema changes
- Data types and constraints
- Migration considerations

### 9. Technical Considerations
- Known constraints or dependencies
- Integration points with existing systems
- Failure modes and error handling approach

### 10. Open Questions
Remaining questions or areas needing clarification.

---

## Writing for Implementation

The FRD reader may be a junior developer or AI agent. Therefore:

- Be explicit and unambiguous
- Use precise technical language but explain domain-specific terms
- Provide enough detail to understand purpose and expected behavior
- Number all requirements for easy reference
- Where helpful, include concrete examples of inputs, outputs, and error conditions
- Specify exact error codes, status codes, and message formats

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `frd-[feature-name].md` (kebab-case)

---

## Example FRD

````markdown
# FRD: Rate Limiting Service

## Overview

Implement a rate limiting service to protect backend APIs from abuse and ensure fair resource allocation across tenants. The service will intercept requests, track usage against configurable limits, and reject requests that exceed thresholds.

## Goals

- Enforce per-tenant request rate limits across all API endpoints
- Provide configurable limits by tenant tier (free, pro, enterprise)
- Return clear error responses when limits are exceeded
- Expose metrics for monitoring and alerting
- Operate with minimal latency overhead (<5ms p99)

## Actors

- **API Gateway:** Calls rate limiter on every inbound request to check/decrement quota
- **Admin Service:** Updates tenant tier configuration and custom limits
- **Monitoring System:** Scrapes Prometheus metrics endpoint
- **Operators:** Query rate limit state for debugging customer issues

## Functional Requirements

### Request Validation

#### FR-001: Check rate limit
**Description:** The system will check whether a request is within the tenant's rate limit and return an allow/deny decision.

**Acceptance Criteria:**
- [ ] Accepts tenant ID and endpoint identifier
- [ ] Returns `ALLOWED` if under limit, `DENIED` if over
- [ ] Response includes remaining quota and reset timestamp
- [ ] Latency < 5ms at p99
- [ ] Unit tests cover allow, deny, and edge cases
- [ ] Typecheck passes

#### FR-002: Atomic decrement
**Description:** The system will atomically decrement the quota counter when a request is allowed.

**Acceptance Criteria:**
- [ ] Counter decrement is atomic (no race conditions under concurrent load)
- [ ] Counter cannot go negative
- [ ] Integration test demonstrates correctness under 100 concurrent requests
- [ ] Typecheck passes

#### FR-003: Rate limit exceeded response
**Description:** The system will return a structured error when rate limit is exceeded.

**Acceptance Criteria:**
- [ ] Returns HTTP 429 status code
- [ ] Response body includes: `error_code: "RATE_LIMIT_EXCEEDED"`, `retry_after_seconds`, `limit`, `reset_at`
- [ ] `Retry-After` header set correctly
- [ ] Unit test validates response schema
- [ ] Typecheck passes

### Configuration

#### FR-004: Tenant limit configuration
**Description:** The system will support configurable rate limits per tenant tier.

**Acceptance Criteria:**
- [ ] Default limits defined per tier: free (100/min), pro (1000/min), enterprise (10000/min)
- [ ] Custom per-tenant overrides supported
- [ ] Configuration changes take effect within 60 seconds without restart
- [ ] Unit tests cover default and override scenarios
- [ ] Typecheck passes

#### FR-005: Per-endpoint limits
**Description:** The system will support different rate limits for different API endpoints.

**Acceptance Criteria:**
- [ ] Limits configurable per endpoint pattern (e.g., `/api/v1/write` vs `/api/v1/query`)
- [ ] Falls back to tenant default if no endpoint-specific limit defined
- [ ] Unit tests cover endpoint-specific and fallback cases
- [ ] Typecheck passes

### Observability

#### FR-006: Prometheus metrics
**Description:** The system will expose metrics for monitoring rate limit behavior.

**Acceptance Criteria:**
- [ ] `ratelimit_requests_total` counter with labels: tenant_id, endpoint, decision (allowed/denied)
- [ ] `ratelimit_check_latency_seconds` histogram
- [ ] `ratelimit_current_usage` gauge per tenant
- [ ] Metrics endpoint accessible at `/metrics`
- [ ] Integration test verifies metrics are emitted
- [ ] Typecheck passes

## Non-Functional Requirements

- **NFR-001:** Rate limit check latency will be < 5ms at p99 under 10,000 req/s load
- **NFR-002:** Service will remain available if Redis is temporarily unreachable (fail-open with logging)
- **NFR-003:** Service will horizontally scale to handle 100,000 req/s
- **NFR-004:** State will survive service restarts (persisted in Redis)

## Non-Goals

- No user-facing dashboard for viewing rate limit status (future work)
- No automatic tier upgrades based on usage patterns
- No rate limiting by IP address (tenant ID only)
- No request queuing or backpressure (reject immediately when over limit)

## API Contracts

### Check Rate Limit

```
POST /v1/check
Content-Type: application/json

Request:
{
  "tenant_id": "tenant_abc123",
  "endpoint": "/api/v1/write"
}

Response (allowed):
HTTP 200
{
  "decision": "ALLOWED",
  "remaining": 847,
  "limit": 1000,
  "reset_at": "2024-01-15T10:05:00Z"
}

Response (denied):
HTTP 200
{
  "decision": "DENIED",
  "remaining": 0,
  "limit": 1000,
  "reset_at": "2024-01-15T10:05:00Z",
  "retry_after_seconds": 45
}
```

### Error Codes

| Code | Condition |
|------|-----------|
| `RATE_LIMIT_EXCEEDED` | Tenant has exceeded their quota |
| `INVALID_TENANT` | Tenant ID not found |
| `INTERNAL_ERROR` | Service failure (fail-open, request allowed) |

## Data Model

### Redis Keys

- `ratelimit:{tenant_id}:{endpoint}:count` — Current window request count (integer)
- `ratelimit:{tenant_id}:{endpoint}:window_start` — Window start timestamp

### Configuration Store

```sql
CREATE TABLE rate_limit_config (
  tenant_id VARCHAR(255) PRIMARY KEY,
  tier VARCHAR(50) NOT NULL DEFAULT 'free',
  custom_limit_per_min INTEGER NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## Technical Considerations

- Use Redis for counter storage (atomic INCR, TTL for window expiration)
- Sliding window algorithm preferred over fixed window to prevent burst at window boundaries
- Circuit breaker pattern for Redis connection failures
- Configuration cached locally with 60-second refresh interval

## Security Considerations

- Rate limiter endpoint is internal-only (not exposed to public internet)
- Tenant ID must be validated against known tenants
- No PII stored in rate limit state

## Success Metrics

- p99 latency < 5ms under normal load
- Zero false denials (requests rejected when tenant is under limit)
- Alert fires within 1 minute when tenant approaches 90% of limit
- Operators can identify rate-limited tenants within 2 minutes using Grafana dashboard

## Open Questions

- Should we support burst allowance (e.g., allow 10% over limit temporarily)?
- What is the desired behavior during Redis failover? (Currently: fail-open)
- Do we need an admin API to manually reset a tenant's counter?
````

---

## Checklist

Before saving the FRD:

- [ ] Asked clarifying questions with the AskUserQuestion tool
- [ ] Incorporated user's answers
- [ ] Functional requirements are small and specific
- [ ] All requirements are numbered and unambiguous
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] Non-goals section defines clear boundaries
- [ ] API contracts include error conditions
- [ ] Saved to `tasks/frd-[feature-name].md`