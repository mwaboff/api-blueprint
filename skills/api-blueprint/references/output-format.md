# Generated Documentation Output Format

Standard format specification for generated controller reference files. This format is optimized for AI agent consumption — prioritizing completeness, parsability, and structured data over human readability aesthetics.

## Controller Reference File

Each controller produces one reference file named `{controller-kebab-name}-api.md`.

### Structure

Every controller reference file follows this exact structure:

```
# {Controller Display Name} API

Base path: `{base-path}`
Authentication: {default auth for all endpoints}

## Endpoints

### {HTTP_METHOD} {full-path}
... (repeated for each endpoint)

## Models

### {ClassName}
... (repeated for each DTO/entity used by this controller)

### {EnumName}
... (repeated for each enum used by this controller)
```

### Endpoint Section Format

Each endpoint section contains exactly these subsections. Omit a subsection only if it has no content (e.g., omit "Path Parameters" if there are none).

```
### {HTTP_METHOD} {full-path}

{One-line description from Javadoc or inferred from method name}

**Authentication:** {Public | Authenticated | Role: ADMIN+}
**Status:** {primary success status code}

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | Resource identifier |

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| expand | string[] | No | — | Expandable fields: owner, items |
| page | integer | No | 0 | Page number (zero-indexed) |

#### Request Body: `CreateUserRequest`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | string | Yes | Valid email, max 255 | User email address |
| username | string | Yes | 3-50 chars | Display name |
| role | Role | No | Default: USER | User role |

```json
{
  "email": "player1@example.com",
  "username": "player1",
  "role": "USER"
}
```

#### Response: `UserResponse` — 200

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | integer | No | Auto-generated identifier |
| email | string | No | User email address |
| username | string | No | Display name |
| role | string | No | One of: USER, MODERATOR, ADMIN, OWNER |
| createdAt | string | No | ISO 8601 datetime |

```json
{
  "id": 42,
  "email": "player1@example.com",
  "username": "player1",
  "role": "USER",
  "createdAt": "2026-03-13T10:30:00"
}
```

#### Error Responses

| Status | Condition | Example Body |
|--------|-----------|--------------|
| 400 | Validation failure | `{"message": "Validation failed", "errors": ["email: must be valid"]}` |
| 401 | Not authenticated | `{"message": "Unauthorized"}` |
| 403 | Insufficient role | `{"message": "Access denied"}` |
| 404 | Resource not found | `{"message": "User not found"}` |
| 409 | Duplicate resource | `{"message": "Email already exists"}` |
```

### Sections to Omit

- Omit **Path Parameters** if the endpoint has none
- Omit **Query Parameters** if the endpoint has none
- Omit **Request Body** for GET/DELETE endpoints without a body
- Omit **Error Responses** only if zero error cases were found in tests AND no obvious error conditions exist (rare)

### Model Section Format

After all endpoints, include a Models section documenting every DTO, entity, and enum used by this controller's endpoints.

```
## Models

### CreateUserRequest

Request body for creating a new user.

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | string | Yes | Valid email, max 255 chars | User email address |
| username | string | Yes | 3-50 chars, alphanumeric | Display name |
| password | string | Yes | Min 8 chars, upper+lower+digit+special | Account password |

### UserResponse

Response body for user data.

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | integer | No | Auto-generated unique identifier |
| email | string | No | User email address |
| username | string | No | Display name |
| role | Role | No | User's permission role |
| createdAt | string | No | ISO 8601 creation timestamp |
| lastModifiedAt | string | No | ISO 8601 last update timestamp |

### Role (enum)

User permission roles, ordered from least to most privileged.

| Value | Description |
|-------|-------------|
| USER | Standard user, default role |
| MODERATOR | Can bypass ownership checks |
| ADMIN | Full administrative access |
| OWNER | System owner, highest privilege |
```

## Example Value Guidelines

### Priority Order

Select example values in this priority order:

1. **Values from integration tests** — most realistic, validated by the test suite
2. **First value from enums** — for enum-typed fields
3. **Context-appropriate generated values** — realistic for the field's domain meaning

### Requirements for Generated Values

- NEVER use generic placeholders like `"string"`, `"example"`, `"test"`, or `"foo"`
- Use values that make sense for the field name: `"Aria Stormwind"` for a character name, `"player1@example.com"` for an email, `5` for a level
- For arrays, include 2-3 items showing variety in values
- For optional fields in request examples, include the field with a value to show its format
- For nullable fields in response examples, show a non-null value

### Nested Object Expansion

ALWAYS expand nested objects inline. Never use `{...}`, `"..."`, or type references in example JSON:

```json
{
  "id": 1,
  "owner": {
    "id": 42,
    "username": "player1",
    "email": "player1@example.com"
  },
  "items": [
    {
      "id": 101,
      "name": "Longsword",
      "type": "WEAPON",
      "damage": {
        "dice": "2d6",
        "modifier": 3,
        "type": "PHYSICAL"
      }
    }
  ]
}
```

### Expanded vs Unexpanded Responses

If the API supports `?expand=` parameters, show two example responses:

1. **Default response** (without expansion) — expanded fields are `null` or omitted
2. **Expanded response** (with `?expand=field1,field2`) — expanded fields are populated

## Shared Models Reference

The `shared-models.md` file consolidates models used across multiple controllers:

- All enums (always shared, since multiple controllers may reference them)
- DTOs that appear in more than one controller's endpoints
- Base/abstract types and their concrete subtypes
- Embeddable types (e.g., `DamageRoll`)
- Common response wrappers (e.g., `PageResponse<T>`)

Models used by only one controller should appear in that controller's reference file AND in `shared-models.md` for cross-cutting discoverability.

## Quick Start Reference

The `quick-start.md` file documents cross-cutting concerns that apply to all endpoints:

### Required Sections

1. **Authentication Flow**
   - How to register/login
   - Token format and delivery mechanism (cookie, header, bearer token)
   - How to include auth in requests (example curl with auth)
   - Token expiration and refresh
   - Logout flow

2. **Common Request Headers**
   - Content-Type requirements
   - Authentication header/cookie format
   - Any custom headers

3. **Error Response Format**
   - Standard error body structure with field descriptions
   - Common error status codes and their meanings
   - Validation error format (how field-level errors are returned)

4. **Pagination** (if applicable)
   - Query parameter names and defaults
   - Response wrapper format
   - Example paginated request and response

5. **Response Expansion** (if applicable)
   - How the `?expand=` parameter works
   - Which endpoints support it
   - Example expanded vs unexpanded response

6. **Soft Deletion** (if applicable)
   - How deletion works (soft vs hard)
   - How deleted resources appear (or don't) in list endpoints
   - Whether restore is possible

7. **Content Visibility Model** (if applicable)
   - Official/public/custom content patterns
   - Who can create/modify what

## OpenAPI 3.1 Specification

Generate a valid OpenAPI 3.1 YAML file (`openapi.yaml`) containing:

```yaml
openapi: "3.1.0"
info:
  title: "{API Display Name}"
  version: "{project version or 1.0.0}"
  description: "Auto-generated by API Blueprint"
servers:
  - url: "{base URL}"
paths:
  # All endpoints with:
  # - operationId (from method name)
  # - summary (one-line description)
  # - parameters (path, query, header)
  # - requestBody with $ref to schema
  # - responses with $ref to schema
  # - security requirements
components:
  schemas:
    # All DTOs, entities, enums
    # With full field descriptions, constraints, examples
  securitySchemes:
    # Auth mechanism (bearer, cookie, etc.)
```

The OpenAPI spec must be valid — parseable by standard OpenAPI tools and validators. Use `$ref` for all schema references to keep the file DRY.

## Curl Example Format

For each endpoint, the generated documentation includes a curl example after the response section:

```
#### Example

```bash
# Create a new user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -b "jwt=eyJhbGci..." \
  -d '{
    "email": "player1@example.com",
    "username": "player1",
    "password": "SecurePass1!"
  }'
```
```

Include the authentication mechanism (cookie, header) in the curl example. Use realistic values matching the request body example.
