---
description: Generate AI-optimized API docs from this backend codebase
argument-hint: "[output-dir]"
---

Generate an API Blueprint for this backend codebase using the api-blueprint skill.

Output directory: ${1:-infer from project name}

## Workflow

1. **Detect the framework** by running: !`bash ${CLAUDE_PLUGIN_ROOT}/skills/api-blueprint/scripts/detect-framework.sh .`
2. **Confirm with the user**: the detected framework, output directory (default: `.{project-name}-api-blueprint` derived from the working directory name, e.g., `.core-api-blueprint`), an API display name, and a base URL
3. **Discover all controllers** and present the manifest table for user confirmation
4. **Analyze each controller** — use the controller-analyzer agent for each controller in parallel when possible
5. **Generate documentation** for each controller following the output format in the api-blueprint skill's references
6. **Assemble the final skill** with SKILL.md, per-controller references, shared models, quick-start guide, and OpenAPI spec
7. **Validate** that all generated files exist and endpoint counts match the manifest
8. **Report** a summary and installation instructions

Load the api-blueprint skill for detailed instructions on each phase, output format, and the generated skill template.
