---
name: API Blueprint
description: This skill should be used when the user asks to "generate API documentation", "create an API blueprint", "map the backend API", "generate API skill for clients", "create API docs for AI agents", "document the backend for frontend", "analyze backend endpoints", "generate client API skill", or wants to produce AI-optimized API documentation from a backend codebase that client-side AI agents can use to understand and interact with every endpoint.
version: 0.1.0
---

# API Blueprint

Generate a complete, AI-optimized API skill from a backend codebase. The output is a portable skill that any AI coding agent can install to immediately understand how to interact with every endpoint — no re-analysis of the backend required.

## Overview

API Blueprint analyzes a backend application's controllers, models, DTOs, enums, database migrations, and tests to produce:

1. **Per-controller reference files** with complete endpoint docs, all field types/constraints, every enum value, and realistic example requests/responses harvested from tests
2. **A shared models reference** consolidating all DTOs, entities, and enums
3. **An OpenAPI 3.1 specification** for tool compatibility
4. **A SKILL.md index** using progressive disclosure so client AI agents load only the sections they need

## Workflow

### Phase 1: Detect & Configure

1. Execute the framework detection script: `bash ${CLAUDE_PLUGIN_ROOT}/skills/api-blueprint/scripts/detect-framework.sh .`
2. If the result has `"confidence": "low"` or `"framework": "unknown"`, ask the user to confirm the framework
3. Infer the **project name** from the working directory name (e.g., `/home/user/projects/core` → `core`, `/home/user/my-service` → `my-service`). Kebab-case it for use in naming.
4. Ask the user:
   - **Output directory** — where to write the generated skill (default: `.{project-name}-api-blueprint/`, e.g., `.core-api-blueprint/`)
   - **API display name** — for the generated skill's metadata (default: title-cased project name, e.g., `Core`)
   - **Base URL** — for example requests (default: `http://localhost:8080`)

### Phase 2: Discover

Load the framework-specific extraction checklist:
- Java/Spring Boot → Read `references/java-spring-patterns.md`
- Other frameworks → Not yet supported; ask whether to proceed with best-effort analysis

Scan the codebase to build a **controller manifest** — a table of:
- Controller file path and class name
- Base route path
- Estimated endpoint count
- Corresponding test file paths

Present the manifest for user confirmation before deep analysis.

### Phase 3: Analyze (Parallel)

Use the controller-analyzer agent for each controller discovered in Phase 2. Spawn all agents in parallel with `run_in_background: true`, passing each one:
- The controller file path
- Its test file paths
- The framework name
- The base URL

If the Agent tool or controller-analyzer agent is unavailable (non-Claude-Code environments), process controllers sequentially using available file-reading and search tools. The extraction steps are the same — only parallelism changes.

For each controller, the analysis extracts:

| Category | What to Extract |
|----------|----------------|
| **Endpoints** | HTTP method, full path, path variables, query params, request body type, response type, status codes, auth requirements |
| **DTOs/Models** | Every field: name, JSON type, nullability, validation constraints, defaults, nested types |
| **Enums** | Every value with description — never omit values |
| **Migrations** | Column types, NOT NULL, UNIQUE, CHECK, foreign keys, defaults |
| **Test Data** | Realistic field values from test fixtures, builders, integration test request/response bodies |

Merge constraints from code annotations and database migrations — the stricter constraint wins.

### Phase 4: Generate Documentation

For each controller, produce a reference markdown file following `references/output-format.md`.

Generate additionally:
- `shared-models.md` — all DTOs, entities, enums used across multiple controllers
- `quick-start.md` — authentication flow, common headers, error format, pagination, expansion patterns
- `openapi.yaml` — valid OpenAPI 3.1 specification covering all endpoints and schemas

### Phase 5: Assemble the Skill

Using `references/generated-skill-template.md`, assemble the output directory:

```
{output-dir}/
├── SKILL.md                        # Lightweight index with progressive disclosure
├── openapi.yaml                    # OpenAPI 3.1 specification
└── references/
    ├── quick-start.md              # Authentication, common patterns, error format
    ├── {controller-name}-api.md    # Per-controller endpoint documentation
    └── shared-models.md            # All DTOs, entities, enums
```

The generated SKILL.md must stay under 3000 words regardless of API size. All request/response details, model tables, and examples belong in the reference files only.

### Phase 6: Validate & Report

- Verify every file referenced in the generated SKILL.md exists
- Confirm total endpoint count matches the discovery manifest
- Print a summary: controllers, endpoints, models, enums documented
- Provide installation instructions for the generated skill

## Additional Resources

### Reference Files

- **`references/java-spring-patterns.md`** — Extraction checklist for Java/Spring Boot: search patterns, constraint merging rules, test data harvesting locations, and non-obvious gotchas
- **`references/output-format.md`** — Format specification for generated controller documentation files, optimized for AI agent consumption
- **`references/generated-skill-template.md`** — Template and assembly instructions for the generated skill's SKILL.md, including progressive disclosure rules and trigger phrase generation

### Scripts

- **`scripts/detect-framework.sh`** — Detects backend framework from project indicator files. Returns JSON with language, framework, build tool, confidence, and whether full support is available.
