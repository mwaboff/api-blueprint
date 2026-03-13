# API Blueprint

A Claude Code plugin that generates AI-optimized API documentation from any backend codebase. The output is a portable skill that any AI coding agent can install on a client project to immediately understand how to interact with every endpoint — no re-analysis of the backend required.

## Why

Every time an AI agent working on a frontend or client app needs to call your backend, it has to re-read controllers, trace DTOs, find valid enum values, and figure out auth. API Blueprint does this once and produces a structured skill that any AI tool can consume instantly.

Run it after every PR to keep your API docs current and machine-readable.

## Supported Frameworks

| Language | Framework | Support |
|----------|-----------|---------|
| Java | Spring Boot | Full |
| Python | FastAPI, Django, Flask | Detection only (best-effort analysis) |
| Node.js | Express, NestJS, Fastify | Detection only (best-effort analysis) |
| Go | Gin, Chi, Gorilla Mux | Detection only (best-effort analysis) |
| Rust | Actix-web, Axum, Rocket | Detection only (best-effort analysis) |
| Ruby | Rails, Sinatra | Detection only (best-effort analysis) |
| C# | ASP.NET | Detection only (best-effort analysis) |

Full support includes framework-specific extraction patterns for controllers, DTOs, migrations, and tests. Best-effort analysis uses the AI's general knowledge of the framework.

## Installation

### Option 1: Install from local directory

```bash
claude plugin install /path/to/api-blueprint
```

### Option 2: Use without installing

```bash
claude --plugin-dir /path/to/api-blueprint
```

## Usage

### Interactive

Start Claude Code with the plugin loaded, then either use the slash command or ask naturally:

```bash
# Slash command
/api-blueprint

# Natural language (skill auto-triggers)
> Generate an API blueprint for this codebase
```

The plugin will:
1. Detect your backend framework
2. Ask you to confirm the framework, output directory, API name, and base URL
3. Discover all controllers and show you the manifest
4. Analyze each controller in parallel (extracting endpoints, DTOs, enums, migrations, test data)
5. Generate the documentation skill
6. Validate and report a summary

### Non-interactive (CI/CD)

```bash
# Generate with defaults
claude -p "/api-blueprint" --plugin-dir /path/to/api-blueprint

# Specify output directory
claude -p "/api-blueprint ./docs/api-skill" --plugin-dir /path/to/api-blueprint
```

## Output

API Blueprint generates a complete skill directory:

```
.api-blueprint/
├── SKILL.md                        # Lightweight endpoint index
├── openapi.yaml                    # OpenAPI 3.1 specification
└── references/
    ├── quick-start.md              # Auth flow, headers, error format
    ├── users-api.md                # Per-controller endpoint docs
    ├── character-sheets-api.md     # Per-controller endpoint docs
    ├── ...                         # One file per controller
    └── shared-models.md            # All DTOs, entities, enums
```

Each controller reference file includes:
- Every endpoint with method, path, parameters, and auth requirements
- Complete request/response examples with realistic data from your tests
- All field types, constraints, and validation rules
- Every enum value (never omitted — missing values break client code)
- Curl examples with your auth mechanism
- Error response documentation

## Installing the Generated Skill on a Client Project

Copy the generated directory into the client project where your AI tool discovers context:

| AI Tool | Where to Place |
|---------|---------------|
| Claude Code | `.claude/skills/` or reference via a plugin |
| Windsurf / Cursor | Project root or docs directory |
| Other tools | Wherever the tool reads context/documentation |

The AI agent will automatically load only the specific controller docs it needs for the current task (progressive disclosure).

## How It Works

API Blueprint uses progressive disclosure at every level:

**During generation:** The plugin loads a lean skill with the workflow, then loads framework-specific extraction patterns only when needed. Each controller is analyzed by a dedicated sub-agent running in parallel.

**In the generated output:** The SKILL.md is a lightweight index (under 3000 words regardless of API size). Detailed endpoint docs, models, and examples live in separate reference files loaded on demand. An AI agent building a login form only loads `quick-start.md` and `auth-api.md`, not your entire API.

## Development

### Plugin Structure

```
api-blueprint/
├── .claude-plugin/
│   ├── plugin.json                          # Plugin manifest
│   └── marketplace.json                     # Marketplace metadata
├── commands/
│   └── api-blueprint.md                     # /api-blueprint slash command
├── agents/
│   └── controller-analyzer.md               # Per-controller analysis agent
└── skills/
    └── api-blueprint/
        ├── SKILL.md                         # Core workflow
        ├── references/
        │   ├── java-spring-patterns.md      # Spring Boot extraction checklist
        │   ├── output-format.md             # Generated doc format spec
        │   └── generated-skill-template.md  # Template for output skill
        └── scripts/
            └── detect-framework.sh          # Framework detection
```

### Adding Support for a New Framework

1. Create `references/{framework}-patterns.md` following the same structure as `java-spring-patterns.md`
2. Update `scripts/detect-framework.sh` to set `supported=true` for the new framework
3. Add a framework branch in the SKILL.md Phase 2 section
4. Update this README's supported frameworks table