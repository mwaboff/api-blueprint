# Java/Spring Boot Extraction Checklist

Procedural checklist for extracting API structure from a Java/Spring Boot codebase. This focuses on **what to search for, in what order, and what non-obvious things to verify** — not on explaining Java or Spring concepts.

## Step 1: Find All Controllers

```
Grep pattern: @(RestController|Controller)\b
File glob: **/*.java
Exclude: test files, @ControllerAdvice classes
```

For each controller, extract the base path from `@RequestMapping` at class level. If absent, base path is empty.

## Step 2: Extract Endpoints Per Controller

For each public method with an HTTP mapping annotation, extract:
- HTTP method and sub-path → combine with class base path for full path
- All parameters: `@PathVariable`, `@RequestParam`, `@RequestBody`, `@RequestHeader`
- Return type — unwrap from `ResponseEntity<T>`, handle `List<T>`, `Void`, generic wrappers
- If return type is `ResponseEntity<?>` or raw `ResponseEntity`, check the method body for what gets passed to `.ok()`, `.created()`, etc.

**Non-obvious**: `@RequestParam` defaults to `required=true` unless `defaultValue` is set (which implicitly makes it optional).

## Step 3: Determine Auth Requirements (Three Sources)

Check in this order of specificity — most specific wins:

1. **Method-level**: `@PreAuthorize`, `@Secured`, `@RolesAllowed` on the endpoint method
2. **Class-level**: Same annotations on the controller class
3. **SecurityConfig**: URL pattern matching rules (`.requestMatchers(...).hasAnyRole(...)`, `.permitAll()`, `.authenticated()`)

**Non-obvious**: `SecurityConfig` is the only source for truly public endpoints — if the URL matches `.permitAll()` but has no annotation, it's still public. Check the security configuration class for the definitive URL-to-auth mapping.

## Step 4: Trace DTOs Recursively

Starting from each controller's request/response types, trace the full type graph:

1. Find the class file: `Glob **/{ClassName}.java`
2. Extract all fields with types and constraint annotations
3. For each non-primitive field type → recurse (find and read that class)
4. Track visited classes to prevent infinite loops on circular references
5. Stop at: primitives, String, standard date/time types, collections of primitives

**Checklist per field:**
- [ ] `@JsonProperty("name")` — use this as the JSON field name, not the Java field name
- [ ] `@JsonIgnore` — skip entirely
- [ ] `@JsonIgnoreProperties` at class level — skip listed fields
- [ ] `@Builder.Default` — extract the default value
- [ ] `@NotNull` / `@NotBlank` / `@NotEmpty` — field is required
- [ ] `@Size(min, max)` — length constraints
- [ ] `@Min` / `@Max` / `@Positive` — value constraints
- [ ] `@Pattern(regexp)` — regex constraint
- [ ] Record classes — all components are fields, all required

**Type mapping to JSON** (for consistent output):

| Java Type | JSON Type | Format Note |
|-----------|-----------|-------------|
| `BigDecimal` | `string` | Prefer string for precision |
| `LocalDate` | `string` | `YYYY-MM-DD` |
| `LocalDateTime` | `string` | `YYYY-MM-DDTHH:mm:ss` |
| `Instant` | `string` | ISO 8601 with timezone |
| `UUID` | `string` | UUID format |
| `Enum` | `string` | List ALL values |

Standard primitives/wrappers map obviously; include the table above only for types where the JSON representation is non-obvious.

## Step 5: Extract Every Enum Value Completely

For each enum referenced by any DTO:
1. Read the enum class
2. List **every** constant — never omit values
3. If the enum has constructor parameters (like `description`), include them

**Why this matters**: A missing enum value means a client AI generates types that reject valid API responses at compile time or runtime. This is the single most common source of client bugs from incomplete API docs.

## Step 6: Parse Migrations for Constraints

**Flyway location**: `src/main/resources/db/migration/V*__*.sql`
**Liquibase location**: `src/main/resources/db/changelog/`

Search migrations for each entity's table name. Extract constraints that supplement code annotations:

| SQL Constraint | What It Adds |
|---------------|-------------|
| `VARCHAR(N)` | Max length (may differ from `@Size`) |
| `NOT NULL` | Required (may differ from DTO annotations) |
| `UNIQUE` | Uniqueness — often missing from DTO annotations |
| `DEFAULT 'value'` | Default value — often missing from code |
| `CHECK (expr)` | Validation rule — often missing from code |
| `BIGSERIAL` | Auto-generated — omit from create request docs |

**Critical: Process migrations in version order.** Later migrations (`ALTER TABLE`) may drop constraints that earlier ones added. The final state is what matters.

### Constraint Merging Rules

When code annotations and migrations both constrain a field:
- Take the **stricter** constraint (e.g., `@Size(max=100)` with `VARCHAR(255)` → document max=100)
- If they diverge: API constraint (`@NotNull`) takes precedence for client docs, since the client hits the API, not the database
- If a migration relaxes a constraint the code still enforces, note this — the API is stricter than the database

## Step 7: Harvest Test Data

### Where to Search

```
Glob: **/*{ControllerName}*Test*.java
Glob: **/*{ServiceName}*Test*.java
```

### What to Extract (Priority Order)

1. **JSON string literals in integration tests** — exact wire format, highest value
   - Search for: `.content(` and multi-line string blocks in MockMvc calls
2. **Builder pattern values** — `.name("Aria Stormwind").level(5).build()`
3. **Response assertions** — `jsonPath("$.field").value(X)` reveals response shape
4. **Error test cases** — tests expecting 400/401/403/404 reveal error response format
5. **Auth setup** — how tests create valid tokens reveals the auth mechanism (cookies vs headers)

**Non-obvious**: Integration test JSON literals are the single best source of example data because they represent exactly what the API accepts/returns over the wire. Prefer these over builder patterns.

## Step 8: Detect Cross-Cutting Patterns

### Response Expansion (`?expand=`)
If any endpoint has an `expand` parameter:
1. Find the corresponding **service class** (not the controller)
2. Read `toResponse()` or `parseExpand()` for conditional field inclusion
3. List all valid expand values and what each adds to the response

**Non-obvious**: Expand values are not in the controller — they're buried in the service's response builder logic.

### Soft Deletion
Search for `deletedAt` field on entities, `findAllActive()` on repositories. If present:
- GET endpoints return only active records by default
- DELETE likely performs soft deletion
- Document this behavior per-endpoint

### Content Visibility
Search for `isOfficial` / `isPublic` / `originalItem` patterns. If present, document:
- Who can create/modify official content
- Visibility rules for public vs private content